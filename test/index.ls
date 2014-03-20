levn = require '..'
{equal} = require 'assert'

suite 'index' ->
  test 'version' ->
    equal levn.VERSION, (require '../package.json').version
