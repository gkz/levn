{parsed-type-check} = require 'type-check'

types =
  '*': (value, options) ->
    switch typeof! value
    | 'Array'   => type-cast value, {type: 'Array'}, options
    | 'Object'  => type-cast value, {type: 'Object'}, options
    | otherwise => type: 'Just', value: types-cast value, [
      * type: 'Undefined'
      * type: 'Null'
      * type: 'NaN'
      * type: 'Boolean'
      * type: 'Number'
      * type: 'Date'
      * type: 'RegExp'
      * type: 'Array'
      * type: 'Object'
      * type: 'String'
    ], options <<< {+explicit}
  Undefined: -> if it is 'undefined' or it is void then {type: 'Just', value: void} else {type: 'Nothing'}
  Null: -> if it is 'null' then {type: 'Just', value: null} else {type: 'Nothing'}
  NaN: -> if it is 'NaN' then {type: 'Just', value: NaN} else {type: 'Nothing'}
  Boolean: ->
    if it is 'true'
      type: 'Just', value: true
    else if it is 'false'
      type: 'Just', value: false
    else
      type: 'Nothing'
  Number: -> type: 'Just', value: +it
  Int: -> type: 'Just', value: parse-int it
  Float: -> type: 'Just', value: parse-float it
  Date: (value, options) ->
    if /^\#(.*)\#$/.exec value
      type: 'Just', value: new Date (+that.1 or that.1)
    else if options.explicit
      type: 'Nothing'
    else
      type: 'Just', value: new Date (+value or value)
  RegExp: (value, options) ->
    if /^\/(.*)\/([gimy]*)$/.exec value
      type: 'Just', value: new RegExp that.1, that.2
    else if options.explicit
      type: 'Nothing'
    else
      type: 'Just', value: new RegExp value
  Array: (value, options) -> cast-array value, {of: [{type: '*'}]}, options
  Object: (value, options) -> cast-fields value, {of: {}}, options
  String: ->
    return type: 'Nothing' unless typeof! it is 'String'
    if it.match /^'(.*)'$/
      type: 'Just', value: that.1
    else if it.match /^"(.*)"$/
      type: 'Just', value: that.1
    else
      type: 'Just', value: it

function cast-array node, type, options
  return {type: 'Nothing'} unless typeof! node is 'Array'
  type-of = type.of
  type: 'Just', value: [types-cast element, type-of, options for element in node]

function cast-tuple node, type, options
  return {type: 'Nothing'} unless typeof! node is 'Array'
  result = []
  for types, i in type.of
    cast = types-cast node[i], types, options
    result.push cast if typeof! cast isnt 'Undefined'
  type: 'Just', value: result

function cast-fields node, type, options
  return {type: 'Nothing'} unless typeof! node is 'Object'
  type-of = type.of
  type: 'Just', value: {[key, types-cast value, (type-of[key] or [{type: '*'}]), options] for key, value of node}

function type-cast node, type-obj, options
  {type, structure} = type-obj
  if type
    cast-func = options.custom-types[type]?.cast or types[type]
    throw new Error "Type not defined: #type." unless cast-func
    cast-func node, options, types-cast
  else
    switch structure
    | 'array'  => cast-array node, type-obj, options
    | 'tuple'  => cast-tuple node, type-obj, options
    | 'fields' => cast-fields node, type-obj, options

function types-cast node, types, options
  for type in types
    {type: value-type, value} = type-cast node, type, options
    continue if value-type is 'Nothing'
    return value if parsed-type-check [type], value, {custom-types: options.custom-types}
  throw new Error "Value #{ JSON.stringify node} does not type check against #{ JSON.stringify types }."

module.exports = types-cast
