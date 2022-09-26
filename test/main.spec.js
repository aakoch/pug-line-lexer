import assert from "assert"
import util from "util"
import _ from "lodash"
import debugFunc from 'debug'
const debug = debugFunc('line-lexer:test')
import dyp from 'dyp'
import Parser from '../build/main.js'
// import { AttrResolver } from '@foo-dog/attrs'
const parser = Parser.parser

const TEXT_TAGS_ALLOW_SUB_TAGS = true

// let tagAlreadyFound = false
// var lparenOpen = false
  
  // tagAlreadyFound = false
  // lparenOpen = false
  
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

    // tagAlreadyFound = false
    // lparenOpen = false
    var actual = parser.parse(input)
    debug(input + ' ==> ', util.inspect(actual))
    
    let compareFunc
    if (strict)
      compareFunc = assert.deepEqual
    else 
      compareFunc = dyp

    compareFunc.call({}, actual, expected)
  }

test('<UNBUF_CODE_BLOCK>list = ["uno", "dos", "tres",', {
  type: 'unbuf_code',
  val: 'list = ["uno", "dos", "tres",',
  state: 'UNBUF_CODE_BLOCK'
})

test('li #{n}', {
  name: 'li',
  type: 'tag',
  val: 'n'
})

// filters-empty.pug:
test(':cdata', {filter: 'cdata', state: 'TEXT_START'})

test(`:custom(opt='val' num=2)`, {
  attrs: [
    {
      name: 'opt',
      val: "'val'"
    },
    {
      name: 'num',
      val: '2'
    }
  ],
  filter: 'custom',
  state: 'TEXT_START'
})

test(':cdata inside', {
  filter: 'cdata',
  type: 'text',
  val: 'inside',
  state: 'TEXT_START'
})
test(':markdown', {filter: 'markdown', state: 'TEXT_START'})
test('+centered#First Hello World', {
  id: 'First',
  name: 'centered',
  type: 'mixin_call',
  val: 'Hello World'
  // type: 'mixin_call',
  // name: 'article',
  // attrs: [ { name: "'Foo'" } ],
  // val: ": p I'm article foo"
})
test(`+article('Foo'): p I'm article foo`, {
  children: [
    {
      name: 'p',
      type: 'tag',
      val: "I'm article foo"
    }
  ],
  name: 'article',
  params: "'Foo'",
  // attrs: [ { name: "'Foo'" } ],
  type: 'mixin_call',
  state: 'NESTED'
})

test(`+comment('This',`, {
  name: 'comment',
  // attrs_start: [ { name: "'This'" } ],
  // state: 'MULTI_LINE_ATTRS',
  params: "'This',",
  state: 'MIXIN_PARAMS_CONT',
  type: 'mixin_call'
})

test(`+comment('This', (('is regular, javascript')))`, {
  name: 'comment',
  // attrs: [
  //   { name: "'This'" },
  //   { name: "(('is" },
  //   { name: 'regular' },
  //   { name: "javascript'))" }
  // ],
  params: "'This', (('is regular, javascript'))",
  type: 'mixin_call'
})

test(`<MULTI_LINE_ATTRS>(('is regular, javascript')))`, {
  type: 'attrs_end',
  val: [
    { name: "(('is" },
    { name: 'regular' },
    { name: "javascript'))" }
  ],
  state: 'MULTI_LINE_ATTRS_END'
})

// TODO: `val` and `state` are incorrect for MIXIN_PARAMS_CONT. Separate out rules `<MULTI_LINE_ATTRS,MIXIN_PARAMS_CONT>','?(.*)')'` and `<MULTI_LINE_ATTRS,MIXIN_PARAMS_CONT>.+`
test(`<MIXIN_PARAMS_CONT>(('is regular, javascript')))`, {
  type: 'attrs_end',
  val: [
    { name: "(('is" },
    { name: 'regular' },
    { name: "javascript'))" }
  ],
  state: 'MULTI_LINE_ATTRS_END'
})

test(`+article('Something').aClassname`, {
  name: 'article',
  type: 'mixin_call',
  params: "'Something'",
  attrs: [ { name: 'class', val: '"aClassname"' } ]

})

test(`<MIXIN_CALL>+centered('Section 1')#Second`, {
  name: 'centered',
  id: 'Second',
  // attrs: [ { name: "'Section" }, { name: "1'" } ],
  params: "'Section 1'",
  type: 'mixin_call'
})

test(':markdown-it', {filter: 'markdown-it', state: 'TEXT_START'})

// tags.self-closing.pug
//   #{
//   'foo'
//   }/
// test('#{', {})

// non-HTML tags not yet supported
// xml.pug
// test(`category(term='some term')/`, {})

test('li #{key}: #{val}', { type: 'tag', name: 'li', val: '#{key}: #{val}' })

test('#[strong foo]', { type: 'tag', name: 'strong', val: 'foo' } )
test('#[q(lang="es") ¡Hola Mundo!]', { type: 'tag', name: 'q', val: '¡Hola Mundo!', attrs: [{name: 'lang', val: '"es"'}] } )

// Filters
test('include:markdown-it article.md', { type: 'include', val: 'article.md', filter: 'markdown-it', state: 'TEXT_START' })
// test(':cdata', { type: 'filter', val: 'cdata' })

// TODO: I'm not sure what the expected behavior of this is. Need to look at Pug code.
test(`+baz()= '123'`,{
  type: 'mixin_call',
  name: 'baz',
  // state: 'MIXIN_CALL',
  // params: '',
  assignment: true,
  val: "'123'"
} )

test('block append head', { type: 'block', val: 'append head' })

test("<INTERPOLATION>'foo'", { type: 'text', val: 'foo' } )

try {
  test('a.3foo', { name: 'a', type: 'tag', attrs: [ { name: 'class', val: '"3foo"' } ] }, null, { allowDigitToStartClassName: false })
//   fail('Should not allow for a class name to start with a digit')
} catch (e) {
  if (e.message != 'Classnames starting with a digit are not allowed. Set allowDigitToStartClassName to true to allow.') {
    throw e;
  }
}

test('prepend head', { type: 'prepend', val: 'head' })

test('script(type="application/ld+json").', {
  name: 'script',
  type: 'tag',
  attrs: [ { name: 'type', val: '"application/ld+json"' } ],
  state: 'TEXT_START'
})

test('a.3foo', { name: 'a', type: 'tag', attrs: [ { name: 'class', val: '"3foo"' } ] }, null, { allowDigitToStartClassName: true })

test('<!--build:js /js/app.min.js?v=#{version}-->', {
  type: 'html_comment',
  children: [
    { type: 'text', val: 'build:js /js/app.min.js?v=' },
    { type: 'interpolation', val: 'version' }
  ]
})
test(`<li>foo</li>`, { type: 'text', val: '<li>foo</li>' })
test(`<ul>`, { type: 'text', val: '<ul>' })
test(`</ul>`, { type: 'text', val: '</ul>' })

test(`p.bar&attributes(attributes) One`, {
  name: 'p',
  type: 'tag',
  attrs: [ { name: 'class', val: '"bar"' }, { val: 'attributes' } ],
  val: 'One'
})

test(`p.baz.quux&attributes(attributes) Two`, {
  name: 'p',
  type: 'tag',
  attrs: [ { name: 'class', val: '"baz"' }, { name: 'class', val: '"quux"' }, { val: 'attributes' } ],
  val: 'Two'
})
test(`p&attributes(attributes) Three`, {
  name: 'p',
  type: 'tag',
  attrs: [ { val: 'attributes' } ],
  val: 'Three'
})
// TODO
test(`p.bar&attributes(attributes)(class="baz") Four`, {
  name: 'p',
  type: 'tag',
  attrs: [ { name: 'class', val: '"bar"' }, { val: 'attributes' }, { name: 'class', val: '"baz"' } ],
  val: 'Four'
})

// The next bunch tests "- Attributes"
// Tests include: mixin.merge.pug
test(`+foo.hello`, { type: 'mixin_call', name: 'foo', 
  attrs: [ { name: 'class', val: '"hello"' }]
  //, state: 'MIXIN_CALL' 
})
test(`+foo#world`, { type: 'mixin_call', name: 'foo', id: 'world'
  // , state: 'MIXIN_CALL' 
})
test(`+foo.hello#world`, { type: 'mixin_call', name: 'foo', id: 'world', attrs: [ { name: 'class', val: '"hello"' }]
  //, state: 'MIXIN_CALL'
})

test(`+foo(class="hello")`, {
  type: 'mixin_call',
  name: 'foo',
  // state: 'MIXIN_CALL',
  params: 'class="hello"'
  // attrs: [ { name: 'class', val: '"hello"' } ]

})
test(`+foo.hello(class="world")`, {
  type: 'mixin_call',
  name: 'foo',
  // state: 'MIXIN_CALL',
  params: 'class="world"',
  attrs: [
    { name: 'class', val: '"hello"' },
    // { name: 'class', val: '"world"' }
  ]
})
test(`+foo&attributes({class: "hello"})`, { type: 'mixin_call', name: 'foo', attrs: [ { name: 'class', val: '"hello"' } ],
  // state: 'MIXIN_CALL' 
})

test("a.rho(href='#', class='rho--modifier')", {
  name: 'a',
  type: 'tag',
  attrs: [
    { name: 'class', val: '"rho"' },
    { name: 'href', val: "'#'" },
    { name: 'class', val: "'rho--modifier'" }
  ]
})
test(`div(id=id)&attributes({foo: 'bar', fred: 'bart'})`, {
  name: 'div',
  type: 'tag',
  attrs: [
    { name: 'id', val: 'id' },
    { name: 'foo', val: '"bar"' },
    { name: 'fred', val: '"bart"' }
  ]
})

test(`a(class=['foo', 'bar', 'baz'])`, {
  name: 'a',
  type: 'tag',
  attrs: [ { name: 'class', val: "['foo', 'bar', 'baz']" } ]
})

// TODO: revisit
test(`a.foo(class='bar').baz`, {
  name: 'a',
  type: 'tag',
  attrs: [
    { name: 'class', val: '"foo"' },
    { name: 'class', val: "'bar'" },
    { name: 'class', val: '"baz"' }
  ]
})
// How is that ^ different than this?: a(href='/save').button save

test(`a.foo-bar_baz`, {
  name: 'a',
  type: 'tag',
  attrs: [ { name: 'class', val: '"foo-bar_baz"' } ]
})

test(`a(class={foo: true, bar: false, baz: true})`, {
  attrs: [
    {
      name: 'class',
      val: '{foo: true, bar: false, baz: true}'
    }
  ],
  name: 'a',
  type: 'tag'
})

test('span(v-for="item in items" :key="item.id" :value="item.name")', {
  name: 'span',
  type: 'tag',
  attrs: [
    { name: 'v-for', val: '"item in items"' },
    { name: ':key', val: '"item.id"' },
    { name: ':value', val: '"item.name"' }
  ]
})

test('p <strong>strongly worded phrase</strong> that cannot be <em>ignored</em>', {
  name: 'p',
  type: 'tag',
  val: '<strong>strongly worded phrase</strong> that cannot be <em>ignored</em>'
})


// Not sure about this...
test('span &boxv;', { type: 'tag', name: 'span', val: '&boxv;'})
//  {
//   name: 'span',
//   type: 'tag',
//   children: [ { type: 'text', val: '&boxv;' } ]
// })

test('span.hljs-section )', {
  name: 'span',
  type: 'tag',
  attrs: [ { name: 'class', val: '"hljs-section"' } ],
  val: ')'
})
test("#{'foo'}(bar='baz') /", {
  attrs: [
    {
      name: 'bar',
      val: "'baz'"
    }
  ],
  name: "'foo'",
  type: 'escaped_text',
  val: '/'
})
test("!{'foo'}(bar='baz') /", {
  attrs: [
    {
      name: 'bar',
      val: "'baz'"
    }
  ],
  name: "'foo'",
  type: 'unescaped_text',
  val: '/'
})

test('li= item', {
  assignment: true,
  val: 'item',
  name: 'li',
  type: 'tag'
})
// test('<MULTI_LINE_ATTRS_END>)', {
//   state: 'MULTI_LINE_ATTRS_END'
// })
// test('a(:link="goHere" value="static" :my-value="dynamic" @click="onClick()" :another="more") Click Me!', {})

test('span.font-monospace .htmlnanorc', {
  attrs: [
    {
      name: 'class',
      val: '"font-monospace"'
    }
  ],
  name: 'span',
  type: 'tag',
  val: '.htmlnanorc'
})

test('.container.post#post-20210905', {
  type: 'tag',
  attrs: [
    { name: 'class', val: '"container"' },
    { name: 'class', val: '"post"' }
  ],
  id: 'post-20210905'
})

test('} else {', {
  type: 'block_end',
  val: 'else {'
})

test("+project('Moddable Two (2) Case', 'Needing Documentation ', ['print'])", 
    { 
      type: 'mixin_call', 
      name: 'project', 
      params: "'Moddable Two (2) Case', 'Needing Documentation ', ['print']"

      // attrs: [
      //   { name: "'Moddable" },
      //   { name: 'Two' },
      //   { name: '(2)' },
      //   { name: "Case'" },
      //   { name: "'Needing" },
      //   { name: 'Documentation' },
      //   { name: "'" },
      //   { name: "['print']" }
      // ]

      // state: 'MIXIN_CALL'
  })

test('p: a(href="https://www.thingiverse.com/thing:4578862") Thingiverse', {
  name: 'p',
  type: 'tag',
  state: 'NESTED',
  children: [ { name: 'a', type: 'tag', attrs: [{
          name: 'href',
          val: '"https://www.thingiverse.com/thing:4578862"'
        }], val: 'Thingiverse' } ]
})

test('.project(class= (tags || []).map((tag) => tag.replaceAll(" ", "_")).join(" "))', {
  type: 'tag',
  attrs: [
    { name: 'class', val: '"project"' },
    {
      name: 'class',
      val: '(tags || []).map((tag) => tag.replaceAll(" ", "_")).join(" ")'
    }
  ]
})

test('.status-wrapper Status:', {
  type: 'tag',
  attrs: [ { name: 'class', val: '"status-wrapper"' } ],
  val: 'Status:'
})

test('+sensitive ', {
  name: 'sensitive',
  type: 'mixin_call',
  // state: 'MIXIN_CALL'
})

test('a(href=url)= url', {
  assignment: true,
  val: 'url',
  attrs: [
    { name: 'href', val: 'url' }
  ],
  name: 'a',
  type: 'tag'
})

// I'm not supporting this right now
// test('a(href=\'/user/\' + id, class=\'button\')', {
//   attrs: [
//     "href='/user/' + id, class='button'"
//   ],
//   name: 'a',
//   type: 'tag'
// })


// I'm not supporting this right now
// test('a(href=\'/user/\' + id, class=\'button\')', {
//   attrs: [
//     "href='/user/' + id, class='button'"
//   ],
//   name: 'a',
//   type: 'tag'
// })
// test('a(href  =  \'/user/\' + id, class  =  \'button\')', {
//   attrs: [
//     "href  =  '/user/' + id, class  =  'button'"
//   ],
//   name: 'a',
//   type: 'tag'
// })

test('a(class = [\'class1\', \'class2\'])',  {
  name: 'a',
  type: 'tag',
  attrs: [ { name: 'class', val: "['class1', 'class2']" } ]
})
test('a.tag-class(class = [\'class1\', \'class2\'])', {
  name: 'a',
  type: 'tag',
  attrs: [
    { name: 'class', val: '"tag-class"' },
    { name: 'class', val: "['class1', 'class2']" }
  ]
})
test('a(href=\'/user/\' + id class=\'button\')',  {
  name: 'a',
  type: 'tag',
  attrs: [
    { name: 'href', val: "'/user/' + id" },
    { name: 'class', val: "'button'" }
  ]
})
test('a(href  =  \'/user/\' + id class  =  \'button\')', {
  name: 'a',
  type: 'tag',
  attrs: [
    { name: 'href', val: "'/user/' + id" },
    { name: 'class', val: "'button'" }
  ]
})
test('meta(key=\'answer\' value=answer())', {
  name: 'meta',
  type: 'tag',
  attrs: [
    { name: 'key', val: "'answer'" },
    { name: 'value', val: 'answer()' }
  ]
})

test(`div(id=id)&attributes({foo: 'bar'})`, {
  name: 'div',
  type: 'tag',
  attrs: [ { name: 'id', val: 'id' }, { name: 'foo', val: '"bar"' } ]
})
test(`div(foo=null bar=bar)&attributes({baz: 'baz'})`, {
  name: 'div',
  type: 'tag',
  attrs: [
    { name: 'foo', val: 'null' },
    { name: 'bar', val: 'bar' },
    { name: 'baz', val: '"baz"' }
  ]
})

test('foo(abc', {type: 'tag', name: 'foo', attrs_start: [ { name: 'abc' }], state: 'MULTI_LINE_ATTRS'})
test('foo(abc,', {type: 'tag', name: 'foo', attrs_start: [ { name: 'abc' }], state: 'MULTI_LINE_ATTRS'})
test('<MULTI_LINE_ATTRS>,def)', { type: 'attrs_end', val: [ { name: 'def' } ], state: 'MULTI_LINE_ATTRS_END' })
test('<MULTI_LINE_ATTRS>def)', { type: 'attrs_end', val: [ { name: 'def' } ], state: 'MULTI_LINE_ATTRS_END' })

test('span(', {type: 'tag', name: 'span', state: 'MULTI_LINE_ATTRS'})
test('<MULTI_LINE_ATTRS>v-for="item in items"', {
  type: 'attrs_cont',
  val: [ { name: 'v-for', val: '"item in items"' } ],
  state: 'MULTI_LINE_ATTRS'
})
test('<MULTI_LINE_ATTRS>:key="item.id"', {
  type: 'attrs_cont',
  val: [ { name: ':key', val: '"item.id"' } ],
  state: 'MULTI_LINE_ATTRS'
})
test('<MULTI_LINE_ATTRS>:value="item.name"', {
  type: 'attrs_cont',
  val: [ { name: ':value', val: '"item.name"' } ],
  state: 'MULTI_LINE_ATTRS'
})
test('<MULTI_LINE_ATTRS>)', { type: 'attrs_end', val: '', state: 'MULTI_LINE_ATTRS_END'})
test('a(:link="goHere" value="static" :my-value="dynamic" @click="onClick()" :another="more") Click Me!', {
  name: 'a',
  type: 'tag',
  attrs: [
    { name: ':link', val: '"goHere"' },
    { name: 'value', val: '"static"' },
    { name: ':my-value', val: '"dynamic"' },
    { name: '@click', val: '"onClick()"' },
    { name: ':another', val: '"more"' }
  ],
  val: 'Click Me!'
})

test('foo(data-user=user)', {
  name: 'foo',
  type: 'tag',
  attrs: [ { name: 'data-user', val: 'user' } ]
})
test('foo(data-items=[1,2,3])', {
  name: 'foo',
  type: 'tag',
  attrs: [ { name: 'data-items', val: '[1,2,3]' } ]
})
test('foo(data-username=\'tobi\')', {
  attrs: [ { name: 'data-username', val: "'tobi'" } ],
  name: 'foo',
  type: 'tag'
})
test('foo(data-escaped={message: "Let\'s rock!"})', {
  attrs: [
    { name: 'data-escaped', val: '{message: "Let\'s rock!"}' }
  ],
  name: 'foo',
  type: 'tag'
})
test('foo(data-ampersand={message: "a quote: &quot; this & that"})', {
  attrs: [
    { name: 'data-ampersand', val: '{message: "a quote: &quot; this & that"}' }
  ],
  name: 'foo',
  type: 'tag'
})
test('foo(data-epoc=new Date(0))', {
  attrs: [
    { name: 'data-epoc', val: 'new Date(0)' }
  ],
  name: 'foo',
  type: 'tag'
})

test('html', { type: 'tag', name: 'html' })
test('html ', { type: 'tag', name: 'html' }, false)

// test("doctype html", { type: 'doctype', val: 'html' })
test('doctype html', { type: 'doctype', val: 'html' })

test("html(lang='en-US')", {"type":"tag","name":"html","attrs":[{name:"lang", val: "'en-US'"}]})

// test("include something", { type: 'include_directive', params: 'something' })
test('include something', { type: 'include', val: 'something' })

// test("block here", { type: 'directive', name: 'block', params: 'here' })
test("block here", { type: 'block', val: 'here' })

test("head", { type: 'tag', name: 'head' })
test("meta(charset='UTF-8')", {"type":"tag","name":"meta","attrs":[{name:"charset", val:"'UTF-8'"}]})
test("meta(name='viewport' content='width=device-width')", { type: 'tag', name: 'meta', attrs: [{name: 'name', val: "'viewport'"}, {name: 'content', val: "'width=device-width'"}]})
test("title", {"type":"tag","name":"title"})
test("| White-space and character 160 | Adam Koch ", {"type":"text","val":"White-space and character 160 | Adam Koch "})
if (!TEXT_TAGS_ALLOW_SUB_TAGS)
  test("script(async src=\"https://www.googletagmanager.com/gtag/js?id=UA-452464-5\")", {"type":"tag","name":"script","attrs":["async src=\"https://www.googletagmanager.com/gtag/js?id=UA-452464-5\""], state: 'TEXT_START'})
test("script.  ", {"type":"tag","name":"script","state":"TEXT_START"})
test("<TEXT>window.dataLayer = window.dataLayer || [];   ", { type: 'text', val: 'window.dataLayer = window.dataLayer || [];   ' })
test("<TEXT>gtag('config', 'UA-452464-5');", {"type":"text","val":"gtag('config', 'UA-452464-5');"})
test("", "")
if (!TEXT_TAGS_ALLOW_SUB_TAGS)
  test("script test", {"type":"tag","name":"script","state":"TEXT_START","val":"test"})
test(".classname", { type: 'tag', attrs: [ { name: 'class', val: '"classname"' } ] })

test("//- some text", { type: 'comment', state: 'TEXT_START', val: ' some text' })
test("// some text", { type: 'html_comment', state: 'TEXT_START', val: ' some text' })

test("//- ", { type: 'comment', state: 'TEXT_START', val: ' ' })
test("// ", { type: 'html_comment', val: ' ', state: 'TEXT_START' })

test("//", { type: 'html_comment', state: 'TEXT_START' })


test('a.url.fn.n(href=\'https://wordpress.adamkoch.com/author/admin/\' title=\'View all posts by Adam\' rel=\'author\') Adam',  {
  name: 'a',
  type: 'tag',
  attrs: [
    { name: 'class', val: '"url"' },
    { name: 'class', val: '"fn"' },
    { name: 'class', val: '"n"' },
    {
      name: 'href',
      val: "'https://wordpress.adamkoch.com/author/admin/'"
    },
    { name: 'title', val: "'View all posts by Adam'" },
    { name: 'rel', val: "'author'" }
  ],
  val: 'Adam'
})
test('style(id=\'wp-block-library-inline-css\' type=\'text/css\').', {
  name: 'style',
  type: 'tag',
  attrs: [
    { name: 'id', val: "'wp-block-library-inline-css'" },
    { name: 'type', val: "'text/css'" }
  ],
  state: 'TEXT_START'
})
test('| #start-resizable-editor-section{figcaption{color:hsla(0,0%,100%,.65)}', {"type":"text","val":"#start-resizable-editor-section{figcaption{color:hsla(0,0%,100%,.65)}"})
test('body.post-template-default.single.single-post.postid-1620.single-format-standard.wp-embed-responsive.single-author.singular.two-column.right-sidebar', {
  name: 'body',
  type: 'tag',
  attrs: [
    { name: 'class', val: '"post-template-default"' },
    { name: 'class', val: '"single"' },
    { name: 'class', val: '"single-post"' },
    { name: 'class', val: '"postid-1620"' },
    { name: 'class', val: '"single-format-standard"' },
    { name: 'class', val: '"wp-embed-responsive"' },
    { name: 'class', val: '"single-author"' },
    { name: 'class', val: '"singular"' },
    { name: 'class', val: '"two-column"' },
    { name: 'class', val: '"right-sidebar"' }
  ]
})
test('#page.hfeed', { type: 'tag', id: 'page', attrs: [ { name: 'class', val: '"hfeed"' } ] })
test('header#branding(role=\'banner\')', {
  name: 'header',
  type: 'tag',
  id: 'branding',
  attrs: [ { name: 'role', val: "'banner'" } ]
})
test('h1#site-title', {type: 'tag', name: 'h1', id: 'site-title'})
test('a(href=\'https://www.adamkoch.com/\' rel=\'home\') Adam Koch', {
  name: 'a',
  type: 'tag',
  attrs: [
    { name: 'href', val: "'https://www.adamkoch.com/'" },
    { name: 'rel', val: "'home'" }
  ],
  val: 'Adam Koch'
})
test('h2#site-description Software Developer and Clean Code Advocate', {type: 'tag', name: 'h2', id: 'site-description', val: 'Software Developer and Clean Code Advocate' })
test('h3.assistive-text Main menu', {
  name: 'h3',
  type: 'tag',
  attrs: [ { name: 'class', val: '"assistive-text"' } ],
  val: 'Main menu'
})
test('ul#menu-header.menu', {
  name: 'ul',
  type: 'tag',
  id: 'menu-header',
  attrs: [ { name: 'class', val: '"menu"' } ]
})
test('a(href=\'https://wordpress.adamkoch.com/posts/\') Posts', {
  name: 'a',
  type: 'tag',
  attrs: [ { name: 'href', val: "'https://wordpress.adamkoch.com/posts/'" } ],
  val: 'Posts'
})
test('span.sep  by', {
  name: 'span',
  type: 'tag',
  attrs: [ { name: 'class', val: '"sep"' } ],
  val: ' by'
})
test('style.', {"type":"tag","name":"style","state":"TEXT_START"})
test('p I came across a problem in Internet Explorer (it wasn\'t a problem with Firefox) when I was trying to compare two strings. To me, one string looked to have an extra space in the front. No problem, I\'ll just call the', {
  type: 'tag',
  name: 'p',
  val: "I came across a problem in Internet Explorer (it wasn't a problem with Firefox) when I was trying to compare two strings. To me, one string looked to have an extra space in the front. No problem, I'll just call the"
})
test('.sd-content', { type: 'tag', attrs: [ { name: 'class', val: '"sd-content"' } ] })
test('th  Browser', { type: 'tag', name: 'th', val: ' Browser' })
test('.sharedaddy.sd-sharing-enabled', {
  type: 'tag',
  attrs: [
    { name: 'class', val: '"sharedaddy"' },
    { name: 'class', val: '"sd-sharing-enabled"' }
  ]
})
test('time(datetime=\'2009-07-28T01:24:04-06:00\') 2009-07-28 at 1:24 AM', {
  name: 'time',
  type: 'tag',
  attrs: [ { name: 'datetime', val: "'2009-07-28T01:24:04-06:00'" } ],
  val: '2009-07-28 at 1:24 AM'
} )
test('<TEXT>}).join(\' \')', { type: 'text', val: "}).join(' ')" })
test('  ', {})
test('#content(role=\'main\')', {
  type: 'tag',
  id: 'content',
  attrs: [ { name: 'role', val: "'main'" } ]
})

test('mixin sensitive()', { type: 'mixin', val: 'sensitive()' })
test('extends ../templates/blogpost', {
  type: 'extends',
  val: '../templates/blogpost'
})
test('append head', {
  type: 'append',
  val: 'head'
})
test('p Maecenas sed lorem accumsan, luctus eros eu, tempor dolor. Vestibulum lorem est, bibendum vel vulputate eget, vehicula eu elit. Donec interdum cursus felis, vitae posuere libero. Cras et lobortis velit. Pellentesque in imperdiet justo. Suspendisse dolor mi, aliquet at luctus a, suscipit quis lectus. Etiam dapibus venenatis sem, quis aliquam nisl volutpat vel. Aenean scelerisque dapibus sodales. Vestibulum in pretium diam. Quisque et urna orci.', {type: 'tag', name: 'p', val: 'Maecenas sed lorem accumsan, luctus eros eu, tempor dolor. Vestibulum lorem est, bibendum vel vulputate eget, vehicula eu elit. Donec interdum cursus felis, vitae posuere libero. Cras et lobortis velit. Pellentesque in imperdiet justo. Suspendisse dolor mi, aliquet at luctus a, suscipit quis lectus. Etiam dapibus venenatis sem, quis aliquam nisl volutpat vel. Aenean scelerisque dapibus sodales. Vestibulum in pretium diam. Quisque et urna orci.' })

test('+project(\'Images\', \'On going\')', 
    { type: 'mixin_call', 
      name: 'project', 
      params: "'Images', 'On going'"
      // attrs: [ { name: "'Images'" }, { name: "'On" }, { name: "going'" } ]

      //, state: 'MIXIN_CALL' 
})
test("+project('Moddable Two (2) Case', 'Needing Documentation ', ['print'])", {
  type: 'mixin_call',
  name: 'project',
  // attrs: [
  //   { name: "'Moddable" },
  //   { name: 'Two' },
  //   { name: '(2)' },
  //   { name: "Case'" },
  //   { name: "'Needing" },
  //   { name: 'Documentation' },
  //   { name: "'" },
  //   { name: "['print']" }
  // ]

  params: "'Moddable Two (2) Case', 'Needing Documentation ', ['print']",
  // state: 'MIXIN_CALL'
})
test('| . The only "gotcha" was I originally had "www.adamkoch.com" as the A record instead of "adamkoch.com". Not a big deal and easy to rectify.', { type: 'text', val: '. The only "gotcha" was I originally had "www.adamkoch.com" as the A record instead of "adamkoch.com". Not a big deal and easy to rectify.' })
test('<TEXT>| #start-resizable-editor-section{display:none}.wp-block-audio figcaption{color:#555;font-size:13px;', {"type":"text","val":"#start-resizable-editor-section{display:none}.wp-block-audio figcaption{color:#555;font-size:13px;" })


test('mixin project(title)', {
  type: 'mixin',
  val: 'project(title)'
})
test('// comment', {
  state: 'TEXT_START',
  type: 'html_comment',
  val: ' comment'
})
test('meta(property=\'og:description\' content=\'I came across a problem in Internet Explorer (it wasn\\\'t a problem with Firefox) when I...\')',  {
  name: 'meta',
  type: 'tag',
  attrs: [
    { name: 'property', val: "'og:description'" },
    {
      name: 'content',
      val: "'I came across a problem in Internet Explorer (it wasn\\'t a problem with Firefox) when I...'"
    }
  ]
})


test("link(rel='alternate' type='application/rss+xml' title='Adam Koch &raquo; White-space and character 160 Comments Feed' href='https://wordpress.adamkoch.com/2009/07/25/white-space-and-character-160/feed/')",  {
  name: 'link',
  type: 'tag',
  attrs: [
    { name: 'rel', val: "'alternate'" },
    { name: 'type', val: "'application/rss+xml'" },
    {
      name: 'title',
      val: "'Adam Koch &raquo; White-space and character 160 Comments Feed'"
    },
    {
      name: 'href',
      val: "'https://wordpress.adamkoch.com/2009/07/25/white-space-and-character-160/feed/'"
    }
  ]
})

test('pre.', {
  name: 'pre',
  state: 'TEXT_START',
  type: 'tag'
})

test('|. The only "gotcha" was I originally had "www.adamkoch.com" as the A record instead of "adamkoch.com". Not a big deal and easy to rectify.', { type: 'text', val: '. The only "gotcha" was I originally had "www.adamkoch.com" as the A record instead of "adamkoch.com". Not a big deal and easy to rectify.' })

test('.rule: p.', {
  type: 'tag',
  attrs: [ { name: 'class', val: '"rule"' } ],
  state: 'NESTED',
  children: [ { name: 'p', type: 'tag', state: 'TEXT_START' } ]
})
test('.rule.unratified: p.',  {
  type: 'tag',
  attrs: [
    { name: 'class', val: '"rule"' },
    { name: 'class', val: '"unratified"' }
  ],
  state: 'NESTED',
  children: [ { name: 'p', type: 'tag', state: 'TEXT_START' } ]
})

test("style(id='wp-block-library-inline-css' type='text/css'). ", {
  name: 'style',
  type: 'tag',
  attrs: [
    { name: 'id', val: "'wp-block-library-inline-css'" },
    { name: 'type', val: "'text/css'" }
  ],
  state: 'TEXT_START'
})

test('|', { type: 'text', val: '' })
test('.', { state: 'TEXT_START' })

try {
  test("tag", { type: 'unknown', name: 'tag' })
throw AssertionError('Expected exception')
} catch (e) {}
// }


test('+code(\'Pretty-print any JSON file\') jq \'.\' package.json',
{
  type: 'mixin_call',
  name: 'code',
  params: "'Pretty-print any JSON file'",
  // attrs: [
  //   { name: "'Pretty-print any JSON file'" }
  // ],

  val: "jq '.' package.json",
  // state: 'MIXIN_CALL'
} )

test("a(href='/save').button save", {
  name: 'a',
  type: 'tag',
  attrs: [
    { name: 'href', val: "'/save'" },
    { name: 'class', val: '"button"' }
  ],
  val: 'save'
})

test("meta( charset='utf8' )", {
  name: 'meta',
  type: 'tag',
  attrs: [ { name: 'charset', val: "'utf8'" } ]
})

// test("input(pattern='\\\\S+')", {})
test("a(href='/contact') contact", {
  name: 'a',
  type: 'tag',
  attrs: [ { name: 'href', val: "'/contact'" } ],
  val: 'contact'
})
test("a(foo bar baz)", {
  name: 'a',
  type: 'tag',
  attrs: [ { name: 'foo' }, { name: 'bar' }, { name: 'baz' } ]
})
test("a(foo='foo, bar, baz' bar=1)", {
  name: 'a',
  type: 'tag',
  attrs: [
    { name: 'foo', val: "'foo, bar, baz'" },
    { name: 'bar', val: '1' }
  ] 
})
test("a(foo='((foo))' bar= (1) ? 1 : 0 )", {
  name: 'a',
  type: 'tag',
  attrs: [
    { name: 'foo', val: "'((foo))'" },
    { name: 'bar', val: '(1) ? 1 : 0' }
  ]
})
test("select", { name: 'select', type: 'tag' })
test("option(value='foo' selected) Foo",{
  name: 'option',
  type: 'tag',
  attrs: [ { name: 'value', val: "'foo'" }, { name: 'selected' } ],
  val: 'Foo'
})
test("option(selected value='bar') Bar", {
  name: 'option',
  type: 'tag',
  attrs: [ { name: 'selected' }, { name: 'value', val: "'bar'" } ],
  val: 'Bar'
})
test('a(foo="class:")', { name: 'a', type: 'tag', attrs: [ { name: 'foo', val: '"class:"' } ] })
// test("input(pattern='\\S+')", {})
test('foo(terse="true")', {
  name: 'foo',
  type: 'tag',
  attrs: [ { name: 'terse', val: '"true"' } ]
})
test("foo(date=new Date(0))", {
  name: 'foo',
  type: 'tag',
  attrs: [ { name: 'date', val: 'new Date(0)' } ]
})
// test("a(foo='foo' \"bar\"=\"bar\")", {})

try {
  test("a(foo='foo' 'bar'='bar'))", {})
  fail('expected exception')
} catch (expected) {}

test("div&attributes(attrs)", { type: 'tag', name: 'div', attrs: [{val: 'attrs'}] })

test('p A sentence with a #[strong strongly worded phrase] that cannot be #[em ignored].', {
  name: 'p',
  type: 'tag',
  children: [
    { type: 'text', val: 'A sentence with a ' },
    { type: 'tag', name: 'strong', val: 'strongly worded phrase' },
    { type: 'text', val: ' that cannot be ' },
    { type: 'tag', name: 'em', val: 'ignored' },
    { type: 'text', val: '.' }
  ]
})

test(`p Some text #[a.rho(href='#', class='rho--modifier') with inline link]`, {
  name: 'p',
  type: 'tag',
  children: [
    { type: 'text', val: 'Some text ' },
    { name: 'a', type: 'tag', attrs: [
        {
          name: 'class',
          val: '"rho"'
        },
        {
          name: 'href',
          val: "'#'"
        },
        {
          name: 'class',
          val: "'rho--modifier'"
        }
      ], val: 'with inline link' }
  ]
})

test(`p #[a.rho(href='#', class='rho--modifier') with inline link]`, {
  children: [
    {
      attrs: [
        {
          name: 'class',
          val: '"rho"'
        },
        {
          name: 'href',
          val: "'#'"
        },
        {
          name: 'class',
          val: "'rho--modifier'"
        }
      ],
      name: 'a',
      type: 'tag',
      val: 'with inline link'
    }
  ],
  name: 'p',
  type: 'tag'
})

test(`+list()`, {
  type: 'mixin_call',
  // params: '',
  name: 'list',
  // state: 'MIXIN_CALL'
})

test(`+ list()`, {
  type: 'mixin_call',
  // params: '',
  name: 'list',
  // state: 'MIXIN_CALL'
})

test(`<MIXIN_CALL>p some awesome content`, { name: 'p', type: 'tag', val: 'some awesome content' })

test(`<MIXIN_CALL>| Test`, { type: 'text', val: 'Test' })

// TODO: I don't know if this is really expected, but it passes. Temporary fix
test(`+centered(title).highlight&attributes(attributes)`,  {
  type: 'mixin_call',
  name: 'centered',
  params: 'title',
  attrs: [ { name: 'class', val: '"highlight"' }, { val: 'attributes' } ]
})