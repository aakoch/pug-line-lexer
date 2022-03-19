import assert from "assert"
import util from "util"
import _ from "lodash"
import debugFunc from 'debug'
const debug = debugFunc('line-lexer:test')
import dyp from 'dyp'
import Parser from '../build/main.js'
import { AttrResolver } from '@foo-dog/attrs'
const parser = Parser.parser

const TEXT_TAGS_ALLOW_SUB_TAGS = true

let tagAlreadyFound = false
var lparenOpen = false
  
  tagAlreadyFound = false
  lparenOpen = false
  
  function test(input, expected, strict = true, options) {
    
    if (_.isEmpty(options)) {
      debug(`\nTesting '${input}'...`)
    }
    else {
      debug(`\nTesting '${input}' with ${JSON.stringify(options)}...`)
      // debug('parser.options before=', parser.options)
      parser.options = options
      parser.options.allowDigitToStartClassName = true
      // debug('parser.options after=', parser.options)
    }

    tagAlreadyFound = false
    lparenOpen = false
    var actual = parser.parse(input)
    debug(input + ' ==> ', util.inspect(actual))
    
    let compareFunc
    if (strict)
      compareFunc = assert.deepEqual
    else 
      compareFunc = dyp

    compareFunc.call({}, actual, expected)
  }


test('<UNBUF_CODE_BLOCK>var i', {
  type: 'unbuf_code',
  val: 'var i',
  state: 'UNBUF_CODE_BLOCK'
})

test('code(class="language-scss").', {
  name: 'code',
  type: 'tag',
  attrs: [ { name: 'class', val: '"language-scss"' } ],
  state: 'TEXT_START'
})  

test('- function answer() { return 42; }', {
  state: 'UNBUF_CODE_FOLLOWER',
  type: 'unbuf_code',
  val: 'function answer() { return 42; }'
})

test('-var ajax = true', {type: 'unbuf_code', val: 'var ajax = true', state: 'UNBUF_CODE_FOLLOWER'})
test('-if( ajax )', {type: 'unbuf_code', val: 'if( ajax )', state: 'UNBUF_CODE_FOLLOWER'})
test('-', { type: 'unbuf_code_block', state: 'UNBUF_CODE_BLOCK_START' })
test('- ', { type: 'unbuf_code_block', state: 'UNBUF_CODE_BLOCK_START' })

test(`<UNBUF_CODE_BLOCK>var list = ["Uno", "Dos", "Tres", "Cuatro", "Cinco", "Seis"]`, { type: 'unbuf_code', val: 'var list = ["Uno", "Dos", "Tres", "Cuatro", "Cinco", "Seis"]', state: 'UNBUF_CODE_BLOCK' })


test('- var title = \'Fade Out On MouseOver Demo\'', { type: 'unbuf_code', val: 'var title = \'Fade Out On MouseOver Demo\'', state: 'UNBUF_CODE_FOLLOWER' })

test('pre: code(class="language-scss").', {
  name: 'pre',
  type: 'tag',
  state: 'NESTED',
  children: [
    { name: 'code', type: 'tag', attrs: [
        {
          name: 'class',
          val: '"language-scss"'
        }], state: 'TEXT_START' }
  ]
})

// test(' -', {
//   state: 'UNBUF_CODE_START',
//   type: 'code',
//   val: ''
// })

// if we get the state UNBUF_CODE followed by something other than '-', we should parse it as if the state wasn't there 
test('<UNBUF_CODE_FOLLOWER>var i', { name: 'var', type: 'tag', val: 'i' })

test('pre: code.', {
  children: [
    {
      name: 'code',
      state: 'TEXT_START',
      type: 'tag'
    }
  ],
  name: 'pre',
  state: 'NESTED',
  type: 'tag'
})

test("- var attrs = {foo: 'bar', bar: '<baz>'}",  {
  type: 'unbuf_code',
  state: 'UNBUF_CODE_FOLLOWER',
  val: "var attrs = {foo: 'bar', bar: '<baz>'}"
})