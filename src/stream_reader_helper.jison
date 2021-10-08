/* simple parser */

/* lexical grammar */
%lex

word         [a-zA-Z]+\b
classname         \.[a-zA-Z0-9-]+\b
id                #[a-zA-Z0-9-]+\b
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


(a|abbr|acronym|address|applet|area|article|aside|audio|b|base|basefont|bdi|bdo|bgsound|big|blink|blockquote|body|br|button|canvas|caption|center|cite|code|col|colgroup|content|data|datalist|dd|del|details|dfn|dialog|dir|div|dl|dt|em|embed|fieldset|figcaption|figure|font|footer|form|frame|frameset|h1|h2|h3|h4|h5|h6|head|header|hgroup|hr|html|i|iframe|image|img|input|ins|kbd|keygen|label|legend|li|link|main|map|mark|marquee|math|menu|menuitem|meta|meter|nav|nobr|noembed|noframes|noscript|object|ol|optgroup|option|output|p|param|picture|plaintext|portal|pre|progress|q|rb|rp|rt|rtc|ruby|s|samp|section|select|shadow|slot|small|source|spacer|span|strike|strong|style|sub|summary|sup|svg|table|tbody|td|template|textarea|tfoot|th|thead|time|title|tr|track|tt|u|ul|var|video|wbr|xmp)\b      %{
  return 'TAG_NAME'
%}
(script|style)\b      %{
  return 'TEXT_TAG_NAME'
%}
<INITIAL>{id}       %{
  return 'ID';
%}
<INITIAL>{classname}       %{
  return 'CLASSNAME';
%}
<INITIAL>{number}     return 'NUMBER';
<INITIAL>'('             %{
  this.pushState('ATTRS')
  return 'LPAREN'
%}
<INITIAL>')'             return 'RPAREN';
'| '              %{
  this.pushState('TEXT_START')
  return 'PIPE'
%}
'.'   return 'DOT'
<INITIAL>{other}      %{
  return 'OTHER';
%}
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
^{word}$      return 'WORD';
.+     return 'THEREST';

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
  | WORD ENDOFFILE
  {
    $$ = { type: 'unknown', name: $WORD }
  }
  | TAG_NAME LPAREN THEREST RPAREN ENDOFFILE
  {
    $$ = { type: 'tag', name: $TAG_NAME, attrs: $THEREST }
  }
  | TEXT_TAG_NAME SPACE WORD* ENDOFFILE
  {
    $$ = { type: 'tag', name: $TEXT_TAG_NAME, state: 'TEXT_START', therest: $3.join('') }
  }
  | TEXT_TAG_NAME DOT? SPACE+ THEREST* ENDOFFILE
  {
    $$ = { type: 'tag', name: $TEXT_TAG_NAME, state: 'TEXT_START' }
  }
  | TEXT_TAG_NAME DOT? LPAREN THEREST RPAREN ENDOFFILE
  {
    $$ = { type: 'tag', name: $TEXT_TAG_NAME, attrs: $THEREST, state: 'TEXT_START' }
  }
  | TAG_NAME LPAREN THEREST RPAREN DOT ENDOFFILE
  {
    $$ = { type: 'tag', name: $TAG_NAME, attrs: $THEREST, state: 'TEXT_START' }
  }
  | TAG_NAME LPAREN THEREST RPAREN SPACE THEREST ENDOFFILE
  {
    $$ = { type: 'tag', name: $TAG_NAME, attrs: $THEREST1, therest: $6 }
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
  | TAG_NAME CLASSNAME+ ENDOFFILE
  {
    $$ = { type: 'tag', name: $TAG_NAME, classes: $2.map(classname => classname.substring(1)) }
  }
  | TAG_NAME CLASSNAME+ SPACE+ THEREST ENDOFFILE
  {
    $$ = { type: 'tag', name: $TAG_NAME, classes: $2.map(classname => classname.substring(1)), therest: $4 }
  }
  | TAG_NAME SPACE* TAG_NAME ENDOFFILE
  {
    $$ = { type: 'tag', name: $TAG_NAME1, therest: $TAG_NAME2 }
  }
  | TEXT ENDOFFILE
  {
    $$ = { type: 'text', text: $TEXT, state: 'TEXT_START' }
  }
  | CLASSNAME ENDOFFILE
  {
    $$ = { type: 'tag', classes: [$CLASSNAME.substring(1)] }
  }
  | COMMENT TEXT* ENDOFFILE
  {
    $$ = { type: 'comment',  state: 'TEXT_START' }
  }
  | PIPE TEXT ENDOFFILE
  {
    $$ = { type: 'text', text: $TEXT }
  }
  | ID CLASSNAME* ENDOFFILE
  {
    $$ = { type: 'tag', id: $ID.substring(1), classes: $2.map(classname => classname.substring(1)) }
  }
  | TAG_NAME ID LPAREN THEREST RPAREN ENDOFFILE
  {
    $$ = { type: 'tag', name: $TAG_NAME, id: $ID.substring(1), attrs: $THEREST }
  }
  | TAG_NAME ID ENDOFFILE
  {
    $$ = { type: 'tag', name: $TAG_NAME, id: $ID.substring(1) }
  }
  | TAG_NAME ID SPACE THEREST ENDOFFILE
  {
    $$ = { type: 'tag', name: $TAG_NAME, id: $ID.substring(1), therest: $THEREST }
  }
  | TAG_NAME ID CLASSNAME* ENDOFFILE
  {
    $$ = { type: 'tag', name: $TAG_NAME, id: $ID.substring(1), classes: $3.map(classname => classname.substring(1)) }
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


const tagLines = fs.readFileSync('/Users/aakoch/projects/new-foo/workspaces/parser-generation/all_tags.txt', 'utf-8').split('\n')
const tags = tagLines.join('|')
console.log(tags)

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
test("script(async src=\"https://www.googletagmanager.com/gtag/js?id=UA-452464-5\")", {"type":"tag","name":"script","attrs":"async src=\"https://www.googletagmanager.com/gtag/js?id=UA-452464-5\"", state: 'TEXT_START'})
test("script.  ", {"type":"tag","name":"script","state":"TEXT_START"})
test("<TEXT_START>window.dataLayer = window.dataLayer || [];   ", { type: 'text', text: 'window.dataLayer = window.dataLayer || [];   ', state: 'TEXT_START' })
test("<TEXT_START>gtag('config', 'UA-452464-5');", {"type":"text","text":"gtag('config', 'UA-452464-5');", state: 'TEXT_START'})
test("", "")
test("script test", {"type":"tag","name":"script","state":"TEXT_START","therest":"test"})
test("tag", { type: 'unknown', name: 'tag' })
test(".classname", { type: 'tag', classes: ['classname'] })

// test("// some text", { type: 'comment', text: ' some text', state: 'TEXT_START' })
// test("// ", { type: 'comment', text: ' ', state: 'TEXT_START' })
// test("//", { type: 'comment', text: ' ', state: 'TEXT_START' })

test("// some text", { type: 'comment', state: 'TEXT_START' })
test("// ", { type: 'comment', state: 'TEXT_START' })
test("//", { type: 'comment', state: 'TEXT_START' })
test('style(id=\'wp-block-library-inline-css\' type=\'text/css\').', {"type":"tag","name":"style","attrs":"id='wp-block-library-inline-css' type='text/css'","state":"TEXT_START"})
test('| #start-resizable-editor-section{figcaption{color:hsla(0,0%,100%,.65)}', {"type":"text","text":"#start-resizable-editor-section{figcaption{color:hsla(0,0%,100%,.65)}"})
test('body.post-template-default.single.single-post.postid-1620.single-format-standard.wp-embed-responsive.single-author.singular.two-column.right-sidebar', {"type":"tag","name":"body","classes":["post-template-default","single","single-post","postid-1620","single-format-standard","wp-embed-responsive","single-author","singular","two-column","right-sidebar"]})
test('#page.hfeed', {"type":"tag","id":"page","classes":["hfeed"]})
test('header#branding(role=\'banner\')', {"type":"tag","name":"header","id":"branding","attrs":"role='banner'"})
test('h1#site-title', {type: 'tag', name: 'h1', id: 'site-title'})
test('a(href=\'https://www.adamkoch.com/\' rel=\'home\') Adam Koch', {type: 'tag', name: 'a', attrs: 'href=\'https://www.adamkoch.com/\' rel=\'home\'', therest: 'Adam Koch'})
test('h2#site-description Software Developer and Clean Code Advocate', {type: 'tag', name: 'h2', id: 'site-description', therest: 'Software Developer and Clean Code Advocate' })
test('h3.assistive-text Main menu', {type: 'tag', name: 'h3', classes: ['assistive-text'], therest: 'Main menu' })
test('ul#menu-header.menu', {type: 'tag', name: 'ul', id: 'menu-header', classes: ['menu']})
};
