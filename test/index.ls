levn = require '..'
{strict-equal: equal} = require 'assert'

suite 'index' ->
  test 'version' ->
    equal levn.VERSION, (require '../package.json').version
