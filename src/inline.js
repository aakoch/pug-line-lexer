import assert from "assert"
import util from "util"
import _ from "lodash"
import debugFunc from 'debug'
const debug = debugFunc('line-lexer:inlinejs')

function parseInline(str) {


  const interpRegex = /(?<BEFORE>.*)(?<!\\)#\{(?<INTERP>.+)\}(?<AFTER>.*)/g
  // const matches = str.matchAll(interpRegex)
  const matches = interpRegex.exec(str)
  debug('matches=', matches)
  // debug('matches.groups=', matches.groups)
  // debug('matches.groups.BEFORE=', matches.groups.BEFORE)

  const arr = []
  if (matches != null) {
    if (matches.groups.BEFORE.length) arr.push( { type: 'text', val: matches.groups.BEFORE } )
    if (matches.groups.INTERP.length) arr.push( { type: 'interp', val: matches.groups.INTERP } )
    if (matches.groups.AFTER.length) arr.push( { type: 'text', val: matches.groups.AFTER } )
  }
  else {
    arr.push({type: 'text', val: str})
  }
  
  return arr
}

function main() {
  
  // tagAlreadyFound = false
  // lparenOpen = false

  function test(input, expected, strict = true ) {
    // tagAlreadyFound = false
    // lparenOpen = false
    debug(`\nTesting '${input}'...`)
    var actual = parseInline(input)
    debug(input + ' ==> ', util.inspect(actual, false, 8))
    
    let compareFunc
    if (strict)
      compareFunc = assert.deepEqual
    else 
      compareFunc = dyp

    // fs.writeFileSync('actual.json', JSON.stringify(actual))
    // fs.writeFileSync('expected.json', JSON.stringify(expected))

    compareFunc.call({}, actual, expected)
  }



test('Written with love by #{author}', [
  { type: 'text', val: 'Written with love by ' },
  { type: 'interp', val: 'author' }
])
test('This will be safe: #{theGreat}', [
  { type: 'text', val: 'This will be safe: ' },
  { type: 'interp', val: 'theGreat' }
])
test('No escaping for #{\'}\'}!', [
  { type: 'text', val: 'No escaping for ' },
  { type: 'interp', val: "'}'" },
  { type: 'text', val: '!' }
])
test('Escaping works with \\#{interpolation}', [ { type: 'text', val: 'Escaping works with \\#{interpolation}' }])


test('#[br]', [{ type: 'tag', name: 'br' }])
test('#[strong mighty]', [{ type: 'tag', name: 'strong', val: 'mighty' }])
test('A #[strong strongly worded phrase] that cannot be #[em ignored].', [
  { type: 'text', val: 'A ' },
  { type: 'tag', name: 'strong', val: 'strongly worded phrase' },
  { type: 'text', val: ' that cannot be ' },
  { type: 'tag', name: 'em', val: 'ignored' },
  { type: 'text', val: '.' }
])
test('This is a very long and boring paragraph that spans multiple lines. Suddenly there is a #[strong strongly worded phrase] that cannot be #[em ignored].', [
  {
    type: 'text',
    val: 'This is a very long and boring paragraph that spans multiple lines. Suddenly there is a '
  },
  { type: 'tag', name: 'strong', val: 'strongly worded phrase' },
  { type: 'text', val: ' that cannot be ' },
  { type: 'tag', name: 'em', val: 'ignored' },
  { type: 'text', val: '.' }
])
test('And here\'s an example of an interpolated tag with an attribute: #[q(lang="es") ¡Hola Mundo!]', [
  {
    type: 'text',
    val: "And here's an example of an interpolated tag with an attribute: "
  },
  { type: 'tag', name: 'q', attrs: [ { name: 'lang', val: '"es"' } ] },
  { type: 'text', val: ' ¡Hola Mundo!]' }
])

try {
  test('#[strong a}', {})
  fail('expected exception')
} catch (expected) {}

test('before #[:cdata inside] after', [
  { type: 'text', val: 'before ' },
  { type: 'filter', name: 'cdata', val: 'inside' },
  { type: 'text', val: ' after' }
])
test('bing #[strong foo] bong', [
  { type: 'text', val: 'bing ' },
  { type: 'tag', name: 'strong', val: 'foo' },
  { type: 'text', val: ' bong' }
])

test("bing #[strong foo] #[strong= '[foo]'] bong",  [
  { type: 'text', val: 'bing ' },
  { type: 'tag', name: 'strong', val: 'foo' },
  { type: 'text', val: ' ' },
  { type: 'tag', name: 'strong', assignment: " '[foo]'" },
  { type: 'text', val: ' bong' }
])

// TODO:
// test("bing #[- var foo = 'foo]'] bong", {})

test('\\#[strong escaped]', [ { type: 'text', val: '\\#[strong escaped]' } ])
test('\\#[#[strong escaped]', [
  { type: 'text', val: '\\#[' },
  { type: 'tag', name: 'strong', val: 'escaped' }
])

// TODO:
// test("#[a.rho(href='#', class='rho--modifier') with inline link]", {})
// test("Some text #[a.rho(href='#', class='rho--modifier')]", {})
// test("Some text #[a.rho(href='#', class='rho--modifier') with inline link]", {})
// test("This also works #[+linkit('http://www.bing.com')] so hurrah for Pug", {})

};

main()