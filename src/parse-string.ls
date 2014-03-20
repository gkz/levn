{reject} = require 'prelude-ls'

function consume-op tokens, op
  if tokens.0 is op
    tokens.shift!
  else
    throw new Error "Expected '#op', but got '#{tokens.0}' instead in #{ JSON.stringify tokens }."

function maybe-consume-op tokens, op
  tokens.shift! if tokens.0 is op

function consume-list tokens, [open, close], has-delimiters
  consume-op tokens, open if has-delimiters
  result = []
  while tokens.length and tokens.0 isnt close
    result.push consume-element tokens
    maybe-consume-op tokens, ','
  consume-op tokens, close if has-delimiters
  result

function consume-array tokens, has-delimiters
  consume-list tokens, <[ [ ] ]>, has-delimiters

function consume-tuple tokens, has-delimiters
  consume-list tokens, <[ ( ) ]>, has-delimiters

function consume-fields tokens, has-delimiters
  consume-op tokens, '{' if has-delimiters
  result = {}
  while tokens.length and (not has-delimiters or tokens.0 isnt '}')
    key = tokens.shift!
    consume-op tokens, ':'
    result[key] = consume-element tokens
    maybe-consume-op tokens, ','
  consume-op tokens, '}' if has-delimiters
  result

function consume-element tokens
  switch tokens.0
  | '[' => consume-array tokens, true
  | '(' => consume-tuple tokens, true
  | '{' => consume-fields tokens, true
  |  _  => tokens.shift!

function consume-top-level tokens, types, options
  {type, structure} = types.0
  orig-tokens = tokens.concat!
  if not options.explicit and types.length is 1 and ((not type and structure) or type in <[ Array Object ]>)
    result = if structure is 'array' or type is 'Array'
      consume-array tokens, tokens.0 is '['
    else if structure is 'tuple'
      consume-tuple tokens, tokens.0 is '('
    else # structure is fields or type is 'Object'
      consume-fields tokens, tokens.0 is '{'

    final-result = if tokens.length
      consume-element if structure is 'array' or type is 'Array'
        orig-tokens
          ..unshift '['
          ..push ']'
      else # tuple
        orig-tokens
          ..unshift '('
          ..push ')'
    else
      result
  else
    final-result = consume-element tokens
  if tokens.length and orig-tokens.length
    throw new Error "Unable to parse #{ JSON.stringify orig-tokens } of type #{ JSON.stringify types}."
  else
    final-result

special = /\[\]\(\)}{:,/.source
token-regex = //
    ("(?:\\"|[^"])*")          # "string"
  | ('(?:\\'|[^'])*')          # 'string'
  | (/(?:\\/|[^/])*/[a-zA-Z]*) # /reg-exp/flags
  | (#.*#)                     # # date #
  | ([#special])               # special
  | ([^\s#special](?:\s*[^\s#special]+)*) # everything else
  | \s*
//

module.exports = (types, string, options = {}) ->
  if not options.explicit and types.length is 1 and types.0.type is 'String'
    return "'#{ string.replace /\\'/ "\\\\'" }'"
  tokens = reject (-> not it or /^\s+$/.test it), string.split token-regex
  node = consume-top-level tokens, types, options
  throw new Error "Error parsing '#string'." unless node
  node
