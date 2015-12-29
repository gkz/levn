name: 'levn'
version: '0.3.0'

author: 'George Zahariev <z@georgezahariev.com>'
description: 'Light ECMAScript (JavaScript) Value Notation - human written, concise, typed, flexible'
homepage: 'https://github.com/gkz/levn'
keywords:
  'levn'
  'light'
  'ecmascript'
  'value'
  'notation'
  'json'
  'typed'
  'human'
  'concise'
  'typed'
  'flexible'
files:
  'lib'
  'README.md'
  'LICENSE'
main: './lib/'

bugs: 'https://github.com/gkz/levn/issues'
license: 'MIT'
engines:
  node: '>= 0.8.0'
repository:
  type: 'git'
  url: 'git://github.com/gkz/levn.git'
scripts:
  test: "make test"

dependencies:
  'prelude-ls': '~1.1.2'
  'type-check': '~0.3.2'

dev-dependencies:
  livescript: '~1.4.0'
  mocha: '~2.3.4'
  istanbul: '~0.4.1'
