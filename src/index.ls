parse-string = require './parse-string'
cast = require './cast'
{parse-type} = require 'type-check'

VERSION = '0.3.0'

parsed-type-parse = (parsed-type, string, options = {}) ->
  options.explicit ?= false
  options.custom-types ?= {}
  cast (parse-string parsed-type, string, options), parsed-type, options

parse = (type, string, options) ->
  parsed-type-parse (parse-type type), string, options

module.exports = {VERSION, parse, parsed-type-parse}
