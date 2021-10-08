/* simple parser */

/* lexical grammar */
%lex

word         [a-zA-Z]+\b
number       [0-9]+
space			[\t \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]
comment \/\/
other        [^a-zA-Z0-9 \n\\]+ 

%s ATTRS
%x TEXT_START
%%

<INITIAL>{comment}$ %{
  this.pushState('TEXT_START')
  this.unput(' ')
  return 'COMMENT'
%}
<INITIAL>{comment} %{
  this.pushState('TEXT_START')
  return 'COMMENT'
%}
<INITIAL>\/\/\s*(?<!$) %{
  this.pushState('TEXT_START')
  return 'COMMENT'
%}
<INITIAL>'<'[A-Z_]+'>'  %{
  this.pushState(yytext.substring(1, yytext.length - 1));
%}
<INITIAL>^"doctype html" return 'DOCTYPE';
<INITIAL>(mixin|include|block)        %{
  this.pushState('ATTRS')
  return 'DIRECTIVE';
%}

<INITIAL>{word}       return 'TAG_NAME';
<INITIAL>{number}     return 'NUMBER';
<INITIAL>'('             %{
  this.pushState('ATTRS')
  return 'LPAREN'
%}
<INITIAL>')'             return 'RPAREN';
'| '              %{
  this.pushState('ATTRS')
  return 'TEXT_START'
%}
'.'   return 'DOT'
<INITIAL>{other}      return 'OTHER';
{space}      return 'SPACE';
<INITIAL><<EOF>>      return 'ENDOFFILE';
<INITIAL>\n           return 'NEWLINE'; // ignore newlines
<ATTRS>[^)\n]+          %{
  this.popState()
  return 'THEREST'
%}
<TEXT_START>[^\n\r]+  %{
  this.popState()
  return 'TEXT'
%}

/lex

%ebnf

%% 


/* language grammar */

start
  : ENDOFFILE
  | DOCTYPE ENDOFFILE
  {
    $$ = { type: 'doctype', val: 'html' }
  }
  | TAG_NAME ENDOFFILE
  {
    $$ = { type: 'tag', name: $TAG_NAME }
  }
  | TAG_NAME LPAREN THEREST RPAREN ENDOFFILE
  {
    $$ = { type: 'tag', name: $TAG_NAME, attrs: $THEREST }
  }
  | DIRECTIVE SPACE THEREST ENDOFFILE
  {
    $$ = { type: 'directive', name: $DIRECTIVE, params: $THEREST }
  }
  | TEXT_START THEREST ENDOFFILE
  {
    $$ = { type: 'text', text: $THEREST }
  }
  | TAG_NAME DOT SPACE* ENDOFFILE
  {
    $$ = { type: 'tag', name: $TAG_NAME, state: 'TEXT_START' }
  }
  | TAG_NAME SPACE* TAG_NAME ENDOFFILE
  {
    $$ = { type: 'tag', name: $TAG_NAME1, therest: $TAG_NAME2 }
  }
  | TEXT ENDOFFILE
  {
    $$ = { type: 'text', text: $TEXT, state: 'TEXT_START' }
  }
  | DOT TAG_NAME ENDOFFILE
  {
    $$ = { type: 'classname', name: $TAG_NAME }
  }
  | COMMENT TEXT* ENDOFFILE
  {
    $$ = { type: 'comment',  state: 'TEXT_START' }
  }
  ;

%% 

// feature of the GH fork: specify your own main.
//
// compile with
// 
//      jison -o test.js --main path/to/simple.jison
//
// then run
//
//      node ./test.js
//
// to see the output.

var assert = require("assert");

parser.main = function () {

  function test(input, expected) {
    console.log(`\nTesting '${input}'...`)
    var actual = parser.parse(input)
    console.log(input + ' ==> ', JSON.stringify(actual))
    assert.deepEqual(actual, expected)
  }

  test('html', { type: 'tag', name: 'html' })


test("doctype html", { type: 'doctype', val: 'html' })
test("html(lang='en-US')", {"type":"tag","name":"html","attrs":"lang='en-US'"})

test("include something", { type: 'directive', name: 'include', params: 'something' })
test("block here", { type: 'directive', name: 'block', params: 'here' })
test("head", { type: 'tag', name: 'head' })
test("meta(charset='UTF-8')", {"type":"tag","name":"meta","attrs":"charset='UTF-8'"})
test("meta(name='viewport' content='width=device-width')", { type: 'tag', name: 'meta', attrs: "name='viewport' content='width=device-width'"})
test("title", {"type":"tag","name":"title"})
test("| White-space and character 160 | Adam Koch ", {"type":"text","text":"White-space and character 160 | Adam Koch "})
test("script(async src=\"https://www.googletagmanager.com/gtag/js?id=UA-452464-5\")", {"type":"tag","name":"script","attrs":"async src=\"https://www.googletagmanager.com/gtag/js?id=UA-452464-5\""})
test("script.  ", {"type":"tag","name":"script","state":"TEXT_START"})
test("<TEXT_START>window.dataLayer = window.dataLayer || [];   ", { type: 'text', text: 'window.dataLayer = window.dataLayer || [];   ', state: 'TEXT_START' })
test("<TEXT_START>gtag('config', 'UA-452464-5');", {"type":"text","text":"gtag('config', 'UA-452464-5');", state: 'TEXT_START'})
test("", "")
test("script test", {"type":"tag","name":"script","therest":"test"})
test("tag", { type: 'tag', name: 'tag' })
test(".classname", { type: 'classname', name: 'classname' })

// test("// some text", { type: 'comment', text: ' some text', state: 'TEXT_START' })
// test("// ", { type: 'comment', text: ' ', state: 'TEXT_START' })
// test("//", { type: 'comment', text: ' ', state: 'TEXT_START' })

test("// some text", { type: 'comment', state: 'TEXT_START' })
test("// ", { type: 'comment', state: 'TEXT_START' })
test("//", { type: 'comment', state: 'TEXT_START' })


};
