levn = require '..'
{deep-equal: deep-equal, strict-equal: equal, throws} = require 'assert'
{is-it-NaN} = require 'prelude-ls'

q = (type, input, expected, options) ->
  result = levn.parse type, input, options
  equal (typeof! result), (typeof! expected)
  if is-it-NaN expected
    is-it-NaN result
  else
    switch typeof! expected
    | 'Array' 'Object' => deep-equal result, expected
    | 'Date'           => equal result.get-time!, expected.get-time!
    | 'RegExp'         => equal result.to-string!, expected.to-string!
    | otherwise        => equal result, expected

suite 'cast' ->
  test 'Undefined' ->
    q 'Undefined', 'undefined', void
    throws (-> q 'Undefined', 'null'), /Value "null" does not type check against/

  test 'Null' ->
    q 'Null', 'null', null
    throws (-> q 'Null', 'undefined'), /Value "undefined" does not type check against/

  test 'NaN' ->
    q 'NaN', 'NaN', NaN
    throws (-> q 'NaN', '1'), /Value "1" does not type check against/

  test 'Boolean' ->
    q 'Boolean', 'true', true
    q 'Boolean', 'false', false
    throws (-> q 'Boolean', '0'), /Value "0" does not type check against/

  test 'Number' ->
    q 'Number', '2', 2
    q 'Number', '-2', -2
    q 'Number', '2.1', 2.1
    q 'Number', '-2.1', -2.1
    throws (-> q 'Number', 'NaN'), /Value "NaN" does not type check against/

  test 'Int' ->
    q 'Int', '2', 2
    q 'Int', '-2', -2
    q 'Int', '2.1', 2
    q 'Int', '-2.1', -2
    throws (-> q 'Int', 'NaN'), /Value "NaN" does not type check against/

  test 'Float' ->
    q 'Float', '2', 2
    q 'Float', '-2', -2
    q 'Float', '2.1', 2.1
    q 'Float', '-2.1', -2.1
    throws (-> q 'Float', 'NaN'), /Value "NaN" does not type check against/

  test 'Date' ->
    q 'Date', '2011-11-11', new Date '2011-11-11'
    q 'Date', '#2011-11-11#', new Date '2011-11-11'
    q 'Date', '1320969600000', new Date '2011-11-11'
    q 'Date', '#1320969600000#', new Date '2011-11-11'
    throws (-> q 'Date', '#2011-13#'), /Value "#2011-13#" does not type check against/

  test 'RegExp' ->
    q 'RegExp', 'hi', /hi/
    q 'RegExp', '/hi/', /hi/
    q 'RegExp', '/h\\/i/', /h\/i/
    q 'RegExp', '/hi/ig', /hi/ig
    q 'RegExp', '/^(hi)|[a-zA-Z]*:there$/g', /^(hi)|[a-zA-Z]*:there$/g

  test 'Array' ->
    q 'Array', '[1,2,3]', [1,2,3]
    q 'Array', '1,2,3', [1,2,3]
    q 'Array', '[]', []

  test 'Object' ->
    q 'Object', '{x: 2, y: hello}', {x: 2, y: 'hello'}
    q 'Object', 'x: 2, y: hello', {x: 2, y: 'hello'}
    q 'Object', '{}', {}

  test 'String' ->
    q 'String', '2', '2'
    q 'String', 'one two three', 'one two three'
    q 'String', 'blah "hi \\" there:"', 'blah "hi \\" there:"'
    q 'String', "blah 'hi \\' there:'", "blah 'hi \\' there:'"
    q 'String', '[2]', '[2]'
    q 'String', '{2: [], ()}', '{2: [], ()}'

  test 'String using quotes' ->
    q 'String', "'one[two]three'", '\'one[two]three\''
    q 'String', '"before"after"', '"before"after"'
    q 'String', '"hi"', '"hi"'
    q 'String', '"h\n\ni"', '"h\n\ni"'

  test 'multiple' ->
    q 'Number | String', '2', 2
    q 'Number | String', 'str', 'str'

  suite 'array' ->
    test 'regular' ->
      q '[Number]', '[1, 2, 3]', [1 2 3]

    test 'children' ->
      q '[String]', '[1, hi, 3]', ['1' 'hi' '3']

    test 'no delimiters' ->
      q '[Number]', '1, 2, 3', [1 2 3]

    test 'trailing comma' ->
      q '[Number]', '[1, 2, 3,]', [1 2 3]

    test 'empty' ->
      q '[Number]', '[]', []

    test 'nested' ->
      q '[[Number]]', '[[1, 2],[3,4],[5,6]]', [[1 2] [3 4] [5 6]]
      q '[[Number]]', '[1,2],[3,4],[5,6]', [[1 2] [3 4] [5 6]]

    test 'nope' ->
      throws (-> q '[Number]', '[hi, there]'), /Value "hi" does not type check against/

  suite 'tuple' ->
    test 'simple' ->
      q '(Number, String)' '(2, hi)', [2, 'hi']
      q '(Number, Boolean)' '(2, false)', [2, false]
      q '(Number, Null)' '(2, null)', [2, null]

    test 'no delimiters' ->
      q '(Number, String)' '2, hi', [2 'hi']

    test 'trailing comma' ->
      q '(Number, String)' '(2, hi,)', [2, 'hi']

    test 'nested' ->
      q '((Boolean, String), Number)' '(true, hi), 2', [[true, 'hi'], 2]

    test 'attempt to cast non-array' ->
      q '(Number, String) | Number' '(2, hi)', [2, 'hi']
      q '(Number, String) | Number' '2', 2

    test 'maybe' ->
      q '(Number, Maybe String)' '(2)', [2]
      q '(Number, Maybe String)' '2', [2]

      q '(Number, Maybe String)' '(2, undefined)', [2]
      q '(Number, Maybe String)' '2,undefined', [2]

    test 'nope' ->
      throws (-> q '(Number, String)' '(hi, 2)'), /Value "hi" does not type check against/
      throws (-> q '(Number, String)' '(2)'), /does not type check/
      throws (-> q '(Number, Number)' '(1,2,3)'), /does not type check/

  suite 'fields' ->
    test 'basic' ->
      q '{x: Number}', '{x: 2}', {x: 2}

    test 'no delimiters' ->
      q '{x: Number}', 'x: 2', {x: 2}

    test 'trailing comma' ->
      q '{x: Number}', '{x: 2,}', {x: 2}

    test 'multiple keys' ->
      q '{x: Number, y: String}', '{x: 2, y: yo}', {x: 2, y: 'yo'}

    test 'nested' ->
      q '{obj: {z: String}, x: {y: Boolean}}', 'obj: {z: hi}, x: {y: true}', {obj: {z:'hi'},x:{+y}}

    test 'etc' ->
      q '{x: Number, ...}', '{x: 2, y: hi}', {x: 2, y: 'hi'}

    test 'maybe' ->
      q '{x: Number, y: Maybe String}', '{x: 2}', {x: 2}

    test 'with type' ->
      q 'RegExp{source: String}', '/[a-z]/g', /[a-z]/g

    test 'nope' ->
      throws (-> q '{x: Number}', '{x: hi}'), /Value "hi" does not type check against/
      throws (-> q '{x: Number}', '{x: 2, y: hi}'), /does not type check/
      throws (-> q '{x: Number, y: String}', '{x: 2}'), /does not type check/

  suite 'wildcard' ->
    test 'undefined' ->
      q '*', 'undefined', void

    test 'null' ->
      q '*', 'null', null

    test 'null' ->
      q '*', 'NaN', NaN

    test 'bool' ->
      q '*', 'true', true
      q '*', 'false', false

    test 'number' ->
      q '*', '0', 0
      q '*', '1', 1
      q '*', '-1', -1
      q '*', '1.1', 1.1
      q '*', '-1.1', -1.1

    test 'string' ->
      q '*', 'hi', 'hi'
      q '*', '2011-11-11', '2011-11-11'

    test 'quoted string' ->
      q '*', '"hello there"', 'hello there'
      q '*', '"undefined"', 'undefined'
      q '*', '"void"', 'void'
      q '*', '"true"', 'true'
      q '*', '"false"', 'false'
      q '*', '"2"', '2'

    test 'date' ->
      q '*', '#2011-11-11#', new Date '2011-11-11'
      q '*', '#1320969600000#', new Date '2011-11-11'

    test 'regex' ->
      q '*', '/hi/', /hi/
      q '*', '/hi/ig', /hi/ig
      q '*', '/^(hi) |[a-zA-Z]*:there$/g', /^(hi) |[a-zA-Z]*:there$/g

    test 'array' ->
      q '*', '[1,2,3]', [1,2,3]
      q '*', '[]', []

    test 'tuple' ->
      q '*', '(1,2)', [1,2]

    test 'object' ->
      q '*', '{x: 2, y: hello}', {x: 2, y: 'hello'}
      q '*', '{}', {}
      throws (-> q '*', 'x: 2, y: hello'), /Unable to parse/

  suite 'nested mixed' ->
    test 'array of tuples' ->
      q '[(Number, String)]', '[(1, hi),(3,"hello there"),(5,yo)]',
          [[1 'hi'], [3 'hello there'] [5 'yo']]

    test 'array of objects' ->
      q '[{x: Number}]', '[{x: 2}, {x: 3}]', [{x: 2}, {x: 3}]

    test 'wildcard' ->
      q '*', '[hi,(null,[42]),{k: true}]', ['hi', [null, [42]], {k: true}]

  suite 'options' ->
    test 'explicit' ->
      q 'Date | String', '2011-11-11', (new Date '2011-11-11'), {-explicit}
      q 'Date | String', '2011-11-11', '2011-11-11', {+explicit}

      q 'RegExp', 're', /re/, {-explicit}
      throws (-> q 'RegExp', 're', null, {+explicit}), /Value "re" does not type check/

    test 'custom-types' ->
      !function Person name, age
        @name = name
        @age = age
      options =
        custom-types:
          Even:
            type-of: 'Number'
            validate: -> it % 2 is 0
            cast: -> {type: 'Just', value: parse-int it}
          Person:
            type-of: 'Object'
            validate: (instanceof Person)
            cast: (value, options, types-cast) ->
              return {type: 'Nothing'} unless typeof! value is 'Object'
              name = types-cast value.name, [type: 'String'], options
              age = types-cast value.age, [type: 'Number'], options
              {type: 'Just', value: new Person name, age}
      q 'Even', '2', 2, options
      throws (-> q 'Even', '3', null, options), /Value "3" does not type check/

      q 'Person', '{name: Arnold, age: 25}', (new Person 'Arnold', 25), options

      throws (-> q 'FAKE', '3', , options), /Type not defined: FAKE/
      throws (-> q 'FAKE', '3'), /Type not defined: FAKE/
