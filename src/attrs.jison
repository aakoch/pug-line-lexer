/* Pug attributes */

/* lexical grammar */
%lex

// ID          [A-Z-]+"?"?
// NUM         ([1-9][0-9]+|[0-9])
space  [ \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]
// quote  ['"]


%x AFTER_NAME
%x AFTER_EQ
%x VARS

%%

<INITIAL>','\s*
%{
                                          return 'COMMA'
%}
<INITIAL>'...'\w+
%{
  debug('spread')
                                          return 'SPREAD'
%}
// SPACE before NAME for list delimiting
<INITIAL>{space}
%{
                                          return 'SPACE'
%}
<INITIAL>\s*[^= ,]+
%{
  this.pushState('AFTER_NAME')
                                          return 'NAME'
%}
<AFTER_NAME>\s*'='\s*
%{
  this.popState()
  this.pushState('AFTER_EQ')
                                          return 'EQ'
%}
<AFTER_EQ>'['[^\]]+']'
%{
  this.popState()
                                          return 'VAL'
%}
<AFTER_EQ>'{'[^\}]+'}'
%{
  this.popState()
                                          return 'VAL'
%}
<AFTER_EQ>'"'[^"]+'"'
%{
  this.popState()
                                          return 'VAL'
%}

// content='I came across a problem in Internet Explorer (it wasn\'t a problem with Firefox) when I...'
<AFTER_EQ>"'"([^']|\\\')+"'"\s*$
%{
  this.popState()
  this.pushState('VARS')
                                          return 'VAR'
%}

// Added for this test case: `content='width=device-width'`
<AFTER_EQ>"'"([^']|\\\')+"'"
%{
  this.popState()
  this.pushState('VARS')
                                          return 'VAR'
%}
<AFTER_EQ>\w+'()'
%{
  this.popState()
                                          return 'VAL'
%}

// match '=' but not '=>' is handled by '='(?!'>')
<AFTER_EQ>[^=]+'='(?!'>')
%{
  debug("<AFTER_EQ>[^=]+'='")

  debug('1 yytext=', yytext)
  const lastSepIndex = findLastSeparatorIndex(yytext)
  debug('lastSepIndex=', lastSepIndex)
  debug('yytext.length=', yytext.length)
  const nextToken = yytext.substring(lastSepIndex)
  debug('nextToken=', nextToken)
  this.unput(nextToken)
  yytext = yytext.substring(0, lastSepIndex)
  yytext = yytext.removeFromEnd(' ')
  yytext = yytext.removeFromEnd(',')
  debug('2 yytext=' + yytext)
  
  // debug('this.matches=', this.matches)

  // if (yytext.includes('=')) {
  //   debug('"=" was found')
  //   // oh, great
  //   // TODO:
  // }
  // else {
  //   debug('"=" NOT found')
  // }
    this.popState()
    this.popState()
                                          return 'VAL'
%}
<VARS>\s*'+'\s*\w+
%{
                                          return ['VAR', 'PLUS']
%}
<VARS>','\s*
%{
  this.popState()
                                          return 'COMMA'
%}
<VARS>{space}
%{
  this.popState()
                                          return 'SPACE'
%}
// class= (tags || []).map((tag) => tag.replaceAll(" ", "_")).join(" ")
<AFTER_EQ>.+
%{
  // id=id
  this.popState()
                                          return 'VAL'
%}
// <AFTER_EQ>[^,]+
// %{
//   this.popState()
//                                           return 'VAL'
// %}
// <AFTER_EQ>[^ ,]+
// %{
//   this.popState()
//                                           return 'VAL'
// %}

// for "foo, bar, baz"
<AFTER_NAME>','{space}*
%{
  debug("<AFTER_NAME>','")
  this.popState()
                                            return 'COMMA'
%}
// for "foo, bar, baz"
<AFTER_NAME>{space}
%{
  debug("<AFTER_NAME>{space}")
  this.popState()
                                            return 'SPACE'
%}

/lex

%ebnf
%options token-stack 

%% 

start
  : EOF
  | attrs EOF
  ;

attrs
  : attrs (SPACE|COMMA) attr
  {
    $attrs.push($attr)
    $$ = $attrs
  }
  | attrs (SPACE|COMMA)
  {
    $$ = $attrs
  }
  | attr
  {
    $$ = [$attr]
  }
  ;

attr
  : NAME EQ val
  {
    debug('attr: NAME EQ val: NAME=', $NAME, ', val=', $val)
    $$ = { name: $NAME.trim(), val: $val }
  } 
  | SPREAD
  {
    $$ = { name: $SPREAD, val: $SPREAD }
  }
  // for "foo, bar, baz"
  | NAME
  {
    debug('attr: NAME: $NAME=', $NAME)
    // $$ = $1.map( function(id2) {
    //   return { name: id2 }
    // })
    $$ = { name: $NAME }
  } 
  ;

val
  : VAL
  | VAR
  | val PLUS VAR
  {
    $$ = $val + $VAR
  }
  ;

%% 
__module_imports__

const TEXT_TAGS_ALLOW_SUB_TAGS = true

const debug = debugFunc('line-lexer:attrs')

let tagAlreadyFound = false
let obj, name, value
var lparenOpen = false
const keysToMergeText = ['therest']
const quoteStack = []
const parens = []

function findLastSeparatorIndex(str) {
  let index = str.length - 2
  let letterFoundIndex = -1
  while(letterFoundIndex == -1 && index > -1) {
    const c = str.charAt(index)
    if (/\w/.test(c)) {
      letterFoundIndex = index
    }
    index--
  }
  const substr = str.substring(0, letterFoundIndex)
  return Math.max(substr.lastIndexOf(' '), substr.lastIndexOf(','))
}

function parseNumber(str) {
  try {
    if (str.includes('.')) {
      return parseFloat(str)
    }
    else {
      return parseInt(str)
    }
  } catch (e) {
    console.error('Unparseable string "' + str + '"')
    return NaN
  }
}

parser.main = function () {
  
  tagAlreadyFound = false
  lparenOpen = false



  function test(input, expected, strict = true ) {
    tagAlreadyFound = false
    lparenOpen = false
    debug(`\nTesting '${input}'...`)
    var actual = parser.parse(input)
    debug(input + ' ==> ', util.inspect(actual))
    
    let compareFunc
    if (strict)
      compareFunc = assert.deepEqual
    else 
      compareFunc = dyp

    compareFunc.call({}, actual, expected)
  }

test('abc,', [{name: 'abc'}])
test('foo, bar, baz', [{name: 'foo'}, {name: 'bar'}, {name: 'baz'}])
test("value='foo' selected", [{name: 'value', val: "'foo'"}, {name: 'selected'}])
test("selected value='bar'", [ { name: 'selected' }, { name: 'value', val: "'bar'" } ])

test("name='viewport' content='width=device-width'", [{name: 'name', val: "'viewport'"}, {name: 'content', val: "'width=device-width'"}])
test("content='I came across a problem in Internet Explorer (it wasn\\'t a problem with Firefox) when I...'", [{ name: 'content', val: "'I came across a problem in Internet Explorer (it wasn\\'t a problem with Firefox) when I...'" }])
test("property='og:description' content='I came across a problem in Internet Explorer (it wasn\\'t a problem with Firefox) when I...'", [{ name: 'property', val: "'og:description'" }, { name: 'content', val: "'I came across a problem in Internet Explorer (it wasn\\'t a problem with Firefox) when I...'" }])
test(`foo=null bar=bar`, [{ name: 'foo', val: 'null' }, { name: 'bar', val: 'bar' }])
test(`data-epoc=new Date(0)`, [{ name: 'data-epoc', val: 'new Date(0)' }])
test(`class= (tags || []).map((tag) => tag.replaceAll(" ", "_")).join(" ")`, [{ name: 'class', val: '(tags || []).map((tag) => tag.replaceAll(" ", "_")).join(" ")'}])
test('id=id', [{ name: 'id', val: 'id'}])

test(`class=['foo', 'bar', 'baz']`, [{ name: 'class', val: "['foo', 'bar', 'baz']" }])

// commenting this all out for now while I test attr {
test(`class='bar'`, [{ name: 'class', val: "'bar'" }])
// test(`class={foo: true, bar: false, baz: true}`, [{ name: 'class', val: "[ 'foo', 'baz' ]" }])
// test(`v-for="item in items" :name="item.id" :value="item.name"`, [{
//   name: "v-for",
//   val: "item in items"
// }, {
//   name: ":name",
//   val: "item.id"
// }, {
//   name: ":value",
//   val: "item.name"
// }])

// test(`class= (tags || []).map((tag) => tag.replaceAll(" ", "_")).join(" ")`, [{
//   assignment: true,
//   val: `(tags || []).map((tag) => tag.replaceAll(" ", "_")).join(" ")`,
//   name: 'class'
// }])

// // url is a variable in a mixin
// test(`href=url`, [
//     { name: 'href', assignment: true, val: 'url' }
//   ])

// }

test(`data-escaped={message: "Let's rock!"}`, [{ name: 'data-escaped', val: '{message: "Let\'s rock!"}' }])
test(`data-items=[1,2,3]`, [{ name: 'data-items', val: '[1,2,3]' }])
test(`href  =  '/user/' + id, class  =  'button'`, [{name: 'href', val: "'/user/' + id"}, {name: 'class', val: "'button'"}])

// I'm not supporting this right now
// test(`href='/user/' + id, class='button'`, [{
//   name: 'href',
//   assignment: true,
//   val: '"/user/" + id'
// },
// {name: 'class', val: 'button'}])

// test(`class = ['class1', 'class2']`, [{ name: 'class', val: 'class1 class2'}])

test(`href='/user/' + id, class='button'`, [
  {
    name: 'href',
    val: "'/user/' + id"
  },
  {
    name: 'class',
    val: "'button'"
  }
])
test(`key='answer', value=answer()`, [
  {
    name: 'key',
    val: "'answer'"
  },
  {
    name: 'value',
    val: 'answer()'
  }
])
test(`class = ['class1', 'class2']`, [
  {
    name: 'class',
    val: "['class1', 'class2']"
  }
])
test(`href='/user/' + id class='button'`, [ {
    name: 'href',
    val: "'/user/' + id"
  },  {
    name: 'class',
    val: "'button'"
  }])
test(`href  =  '/user/' + id class  =  'button'`, [ {
    name: 'href',
    val: "'/user/' + id"
  },  {
    name: 'class',
    val: "'button'"
  }])
test(`key='answer' value=answer()`, [
  {
    name: 'key',
    val: "'answer'"
  },
  {
    name: 'value',
    val: 'answer()'
  }
])
test(`class = ['class1', 'class2']`, [
  {
    name: 'class',
    val: "['class1', 'class2']"
  }
])
test(`class = ['class1', 'class2']`, [
  {
    name: 'class',
    val: "['class1', 'class2']"
  }
])

// test(`id=id)&attributes({foo: 'bar'}`, {})
// - var bar = null
// test(`foo=null bar=bar)&attributes({baz: 'baz'}`. [])

test(`...object`, [{name: '...object', val: '...object'}])
test(`...object after="after"`, [{name: '...object', val: '...object'}, {name: 'after', val: '"after"'}])
test(`before="before" ...object`, [{name: 'before', val: '"before"'}, {name: '...object', val: '...object'}])
test(`before="before" ...object after="after"`, [{name: 'before', val: '"before"'}, {name: '...object', val: '...object'}, {name: 'after', val: '"after"'}])

};

