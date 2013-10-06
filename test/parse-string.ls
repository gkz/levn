parse-string = require '../lib/parse-string'
{deep-equal, strict-equal: equal, throws} = require 'assert'
{parse-type} = require 'type-check'

q = (input, type, expected, options) ->
  result = parse-string (parse-type type), input, options
  switch typeof! expected
  | 'Array', 'Object' => deep-equal result, expected
  | otherwise         => equal result, expected

suite 'parse-string' ->
  test '"string"' ->
    q '"string"', 'String', '"string"'
    q '"string"', '*', '"string"'
    q "'string'", 'String', "'string'"
    q "'string'", '*', "'string'"
    q '"string with spaces and: {[(})]"', 'String', '"string with spaces and: {[(})]"'
    q 'string with spaces and: {[(})]', 'String', 'string with spaces and: {[(})]'
    throws (-> q 'string with spaces and: {[(})]', '*'), /Unable to parse/
    throws (-> q 'string with spaces and: {[(})]', 'String', , {+explicit}), /Unable to parse/

  test '#date#' ->
    q '#2011-11-11#', 'Date', '#2011-11-11#'
    q '#2011-11-11#', '*', '#2011-11-11#'
    q '#[] () :: { }#', 'Date', '#[] () :: { }#'
    q '#[] () :: { }#', '*', '#[] () :: { }#'

  test '/regexp/flags' ->
    q '/regexp/ig', 'RegExp', '/regexp/ig'
    q '/regexp/ig', '*', '/regexp/ig'
    q '/[ ] {:}/ig', 'RegExp', '/[ ] {:}/ig'
    q '/[ ] {:}/ig', '*', '/[ ] {:}/ig'

  test '[array]' ->
    q '[1,2,3]', 'Array', ['1','2','3']
    q '[1,2,3]', '[Number]', ['1','2','3']
    q '[1,2,3]', '*', ['1','2','3']
    q '[one two , three four]', '[String]', ['one two','three four']

    q '[1,2,3,]', '*', ['1','2','3']
    q '[1, 2, 3, ]', '*', ['1','2','3']


    q '[]', 'Array', []
    q '[]', '[Number]', []
    q '[]', '*', []

    q '1,2,3', '[Number]', ['1','2','3']
    q '1,2,3', 'Array', ['1','2','3']
    throws (-> q '1,2,3', '*'), /Unable to parse/

    q '1, 2, 3', '[Number]', ['1','2','3']
    q '1, 2, 3', 'Array', ['1','2','3']

    q '', '[Number]', []
    q '', 'Array', []

    q '[1,2],[3,4]', 'Array', [['1','2'],['3','4']]
    q '[1,2],[3,4]', '[[Number]]', [['1','2'],['3','4']]

  test '(tuple)' ->
    q '(1,2)', '(Number, Number)', ['1', '2']
    q '(1,2)', '*', ['1', '2']

    q '(1, 2)', '(Number, Number)', ['1', '2']
    q '(1, 2)', '*', ['1', '2']

    q '(one two , 2)', '(String, Number)', ['one two', '2']

    q '1,2', '(Number, Number)', ['1', '2']
    q '1, 2', '(Number, Number)', ['1', '2']

    throws (-> q '1,2', '*'), /Unable to parse/
    throws (-> q '1,2', '*'), /Unable to parse/

    q '(1,2),(3,4)', '((Number,Number),(Number,Number))', [['1','2'],['3','4']]

  test '{object}' ->
    q '{x: 2, y: 3}', 'Object', {x: '2', y: '3'}
    q '{x: 2, y: 3}', '{...}', {x: '2', y: '3'}
    q '{x: 2, y: 3}', 'RegExp{...}', {x: '2', y: '3'}
    q '{x: 2, y: 3}', '{x: Number, y: Number}', {x: '2', y: '3'}
    q '{x: 2, y: 3}', '*', {x: '2', y: '3'}

    q '', 'Object', {}
    q '', '{...}', {}
    q '', '{x: Number, y: Number}', {}

    throws (-> q '{x}', '*'), /Expected ':', but got '}' instead/

    q 'x: 2, y: 3', 'Object', {x: '2', y: '3'}
    q 'x: 2, y: 3', '{x: Number, y: Number}', {x: '2', y: '3'}

    throws (-> q 'x: 2, y: 3', '*'), /Unable to parse/

  test 'etc' ->
    q 'hi', '*', 'hi'
    q 'this is a string', '*', 'this is a string'
    q '&$-1234asdfasw#!.+=%', '*', '&$-1234asdfasw#!.+=%'

  test 'explicit' ->
    throws (-> q '1,2,3', '*', , {+explicit}), /Unable to parse/
    throws (-> q '1,2,3', 'Array', , {+explicit}), /Unable to parse/

  test 'nothing' ->
    throws (-> q '', '*'), /Error parsing ''/
