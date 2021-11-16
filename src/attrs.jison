/* Pug attributes */

/* lexical grammar */
%lex

// ID          [A-Z-]+"?"?
// NUM         ([1-9][0-9]+|[0-9])
space  [ \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]
// quote  ['"]


%x AFTER_NAME
%x AFTER_EQ

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
<INITIAL>\s*[^=]+
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
<AFTER_EQ>[^,]+
%{
  this.popState()
                                          return 'VAL'
%}
<AFTER_EQ>[^ ,]+
%{
  this.popState()
                                          return 'VAL'
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
  | attr
  {
    $$ = [$attr]
  }
  ;

attr
  : NAME EQ VAL
  {
    debug('attr: NAME EQ VAL: NAME=', $NAME, ', VAL=', $VAL)
    $$ = { name: $NAME.trim(), val: $VAL }
  } 
  | SPREAD
  {
    $$ = { name: $SPREAD, val: $SPREAD }
  }
  ;

%% 
__module_imports__

const TEXT_TAGS_ALLOW_SUB_TAGS = true

const debug = debugFunc('pug-line-lexer:attrs')

let tagAlreadyFound = false
let obj, name, value
var lparenOpen = false
const keysToMergeText = ['therest']
const quoteStack = []
const parens = []

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

test(`class=['foo', 'bar', 'baz']`, [{ name: 'class', val: "['foo', 'bar', 'baz']" }])

// commenting this all out for now while I test pug-attr {
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
test(`href  =  '/user/' + id, class  =  'button'`, [ {
    name: 'href',
    val: "'/user/' + id"
  },  {
    name: 'class',
    val: "'button'"
  }])
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
test(`key='answer' value=answer()`, [ {
    name: 'href',
    val: "'/user/' + id"
  },  {
    name: 'class',
    val: "'button'"
  }])
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

// test(`id=id)&attributes({foo: 'bar'}`)
// - var bar = null
// test(`foo=null bar=bar)&attributes({baz: 'baz'})

test(`...object`, [{name: '...object', val: '...object'}])
test(`...object after="after"`, [{name: '...object', val: '...object'}, {name: 'after', val: '"after"'}])
test(`before="before" ...object`, [{name: 'before', val: '"before"'}, {name: '...object', val: '...object'}])
test(`before="before" ...object after="after"`, [{name: 'before', val: '"before"'}, {name: '...object', val: '...object'}, {name: 'after', val: '"after"'}])

};

