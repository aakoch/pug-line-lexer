/* simple parser */

/* lexical grammar */
%lex

%options case-insensitive


word         [a-zA-Z0-9]+\b
classname         \.[a-zA-Z0-9-]+\b
id                #[a-zA-Z0-9-]+\b
block                \+[a-zA-Z0-9-]+\b
number       [0-9]+
space			[\t \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]
comment \/\/
code_unbuf     -(?<=\s*\w|\s|)
other        [^a-zA-Z0-9 \n\\-]+ 

%s ATTRS
%x TEXT
%x TEXT_START
%x MIXIN_CALL
%%

<INITIAL>^(?!{other}){space}+$ 	%{
  debug('blank line')
  // return 'ENDOFFILE'
%} /* eat blank lines */

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
<INITIAL>'mixin'\s+{word}        %{
  yytext = yytext.substring(6)
  this.pushState('MIXIN')
  return 'MIXIN_DECL';
%}
<INITIAL>'include'\s+.*        %{
  yytext = yytext.substring(8).trim()
  return 'INCLUDE_DECL';
%}
<INITIAL>'block'\s+.*        %{
  yytext = yytext.substring(6).trim()
  return 'BLOCK_DECL';
%}
<INITIAL>'extends'\s+.*        %{
  yytext = yytext.substring(7).trim()
  return 'EXTENDS_DECL';
%}
<INITIAL>'append'\s+.*        %{
  yytext = yytext.substring(6).trim()
  return 'APPEND_DECL';
%}

<INITIAL>'+'{word}'('       %{
  yytext = yytext.substring(1, yytext.length - 1)
  this.pushState('MIXIN_CALL')
  return 'MIXIN_CALL';
%}


<INITIAL>^(a|abbr|acronym|address|applet|area|article|aside|audio|b|base|basefont|bdi|bdo|bgsound|big|blink|blockquote|body|br|button|canvas|caption|center|cite|code|col|colgroup|content|data|datalist|dd|del|details|dfn|dialog|dir|div|dl|dt|em|embed|fieldset|figcaption|figure|font|footer|form|frame|frameset|h1|h2|h3|h4|h5|h6|head|header|hgroup|hr|html|i|iframe|image|img|input|ins|kbd|keygen|label|legend|li|link|main|map|mark|marquee|math|menu|menuitem|meta|meter|nav|nobr|noembed|noframes|noscript|object|ol|optgroup|option|output|p|param|picture|plaintext|portal|pre|progress|q|rb|rp|rt|rtc|ruby|s|samp|section|select|shadow|slot|small|source|spacer|span|strike|strong|sub|summary|sup|svg|table|tbody|td|template|textarea|tfoot|th|thead|time|title|tr|track|tt|u|ul|var|video|wbr|xmp)\b':'?(?<![.# \(]\))      %{
  debug('tag name='+yytext)
  if (yytext.endsWith(':')) {
    yytext = yytext.substring(0, yytext.length - 1)
    return 'NESTED_TAG'
  }
  else if (tagAlreadyFound) {
  // debug('tag name was ' + (tagAlreadyFound ? '' : 'not ') + 'already found')
    this.unput(yytext)
    this.pushState('TEXT')
    return 'THEREST'
  }
  else {
    tagAlreadyFound = true;
    return 'TAG_NAME'
  }
%}
<INITIAL>(script|style)      %{
  if (tagAlreadyFound) {
  // debug('tag name was ' + (tagAlreadyFound ? '' : 'not ') + 'already found')
    this.unput(yytext)
    this.pushState('TEXT_START')
    return 'THEREST'
  }
  else {
    tagAlreadyFound = true;
    return 'TEXT_TAG_NAME'
  }
  
%}
<INITIAL>{id}       %{
  debug('id='+yytext)
  return 'ID';
%}
<INITIAL>{classname}       %{
  // debug('classname='+yytext)
  return                                'CLASSNAME';
%}

<INITIAL>{code_unbuf}            %{
  this.pushState('TEXT')
  this.unput(' ')
  return 'CODE_UNBUF'
%}

// <INITIAL>{number}     return              'NUMBER';
<INITIAL>'('             %{
  // debug('LPAREN='+yytext)
  this.pushState('ATTRS')
                                    return 'LPAREN'
%}
<INITIAL>')'             return           'RPAREN';
'| '              %{
  debug('PIPE')
  this.pushState('TEXT')
  return                                    'PIPE'
%}
'.'         %{
  debug('DOT - topState=' + this.topState())
  return 'DOT'
%}
{space}      return 'SPACE';
<INITIAL><<EOF>>      return 'ENDOFFILE';
<INITIAL>\n           return 'NEWLINE'; // ignore newlines

// TODO: need to handle ) better
<ATTRS>[^)\n]+          %{
  this.popState()
  return 'THEREST'
%}
<MIXIN_CALL>.*(?=\))          %{
  this.popState()
  return 'THEREST'
%}

<TEXT>[^\n\r]+  %{
  debug('inside <TEXT>[^\n\r]+')
  if (yytext.startsWith('| ')) {
    yytext = yytext.substring(2)
  }
  this.popState()
  return 'TEXT'
%}

<MIXIN>{word} return 'MIXIN_NAME';
<MIXIN>'('             %{
                                    return 'LPAREN'
%}
<MIXIN>')'             return           'RPAREN';
<MIXIN><<EOF>>      return 'ENDOFFILE';


^{word}$      return 'WORD';
.+     return 'THEREST';

<TEXT_START>.+     return ['ENDOFFILE', 'TEXT'];

<INITIAL>{other}      %{
  return 'OTHER';
%}

/lex

%ebnf
%options token-stack 

%% 


/* language grammar */

start
  : ENDOFFILE
  {
    tagAlreadyFound = false
  }
  | element ENDOFFILE
  {
    tagAlreadyFound = false
  }
  ;

element
  : DOCTYPE
  {
    $$ = { type: 'doctype', val: 'html' }
  }
  | WORD
  {
    $$ = { type: 'unknown', name: $WORD }
  }
  | TAG_NAME classname_followers
  {
    // debug('TAG_NAME tag_name_followers')
    $$ = merge({ type: 'tag', name: $TAG_NAME }, $classname_followers)
  }
  | TEXT_TAG_NAME DOT? SPACE* attrs? DOT? (SPACE|THEREST|WORD)*
  {
    $$ = { type: 'tag', name: $TEXT_TAG_NAME, state: 'TEXT_START' }
    if ($4 != undefined && $4.length > 0) {
      $$.attrs = $4
    }
    if ($6 != undefined && $6.length > 0) {
      $$.therest = $6.join('')
    }
  }
  | NESTED_TAG SPACE TAG_NAME classname_followers
  {

    $$ = { 
      type: 'tag', name: $NESTED_TAG, state: 'NESTED',
      children: [ merge({ type: 'tag', name: $TAG_NAME }, $classname_followers) ]
    }

  }
  | MIXIN_DECL attrs
  {
    $$ = { type: 'mixin_declaration', name: $MIXIN_DECL }
    if ($2 != undefined && $2.length > 0) {
      $$ = Object.assign($$, { params: $2 })
    }
  }
  | MIXIN_CALL THEREST RPAREN
  {
    debug('MIXIN_CALL')
    $$ = { type: 'mixin_call', name: $MIXIN_CALL, params: $2 }
  }
  | INCLUDE_DECL 
  {
    $$ = { type: 'include_directive', params: $INCLUDE_DECL }
  }
  | BLOCK_DECL 
  {
    $$ = { type: 'directive', name: 'block', params: $BLOCK_DECL }
  }
  | EXTENDS_DECL 
  {
    $$ = { type: 'extends_declaration', template: $EXTENDS_DECL }
  }
  | APPEND_DECL 
  {
    $$ = { type: 'append_declaration', template: $APPEND_DECL }
  }
// | TEXT_START THEREST
// {
//   $$ = { type: 'text', text: $THEREST }
// }
  | TEXT
  {
    // debug('TEXT')
    $$ = { type: 'text', text: $TEXT }
  }
  | CLASSNAME classname_followers
  {
    debug('CLASSNAME classname_followers', 'CLASSNAME=', $CLASSNAME)

    $$ = merge({ type: 'tag', classes: [$CLASSNAME.substring(1)] }, $classname_followers)
  }
  | COMMENT TEXT*
  {
    // debug('COMMENT TEXT*')
    $$ = { type: 'comment',  state: 'TEXT_START' }
  }
  | PIPE TEXT
  {
    // debug('PIPE TEXT')
    $$ = { type: 'text', text: $TEXT }
  }
  | ID classname_followers
  {
    // debug('ID CLASSNAME*')
    // $$ = { type: 'tag', id: $ID.substring(1), classes: $classname_followers }
    $$ = merge( { type: 'tag', id: $ID.substring(1) }, $classname_followers )
  }
  | CODE_UNBUF SPACE? (THEREST|TEXT)
  {
    debug('CODE_UNBUF (THEREST|TEXT) 3=' + $3)
    $$ = { type: 'js' }
    if ($3) 
      $$ = Object.assign($$, { val: $3.trim() } )
  }
  | THEREST
  {
    // debug('THEREST')
    $$ = { therest: $THEREST.trim() }
  }
  ;

attrs
  : LPAREN (THEREST|TEXT)* RPAREN
  {
    debug('attrs')
    $$ = $2
  }
  | 
  ;

tag_name_followers
  : tag_name_followers tag_name_follower
  | tag_name_follower
  ;

tag_name_follower
  : ID
  {
    $$ = { id: $ID.substring(1) }
  }
  ;


classname_followers
  : classname_followers classname_follower
  {
    debug('classname_followers classname_follower')
    debug('classname_followers=', $classname_followers)
    debug('classname_follower=', $classname_follower)
    $$ = [merge(...$classname_followers, $classname_follower)]
  }
  | classname_follower
  {
    // debug('classname_follower111=', $classname_follower)
    $$ = [ $classname_follower ]
  }
  | attrs
  {
    // debug('attrs')
    $$ = [{ attrs: $attrs }]
  }
  ;

classname_follower
  : 
  {
    $$ = { }
  }
  | SPACE SPACE* 
  {
    if ($2.length > 0) {
      $$ = { therest: $2 }
    }
  }
  | THEREST
  {
    // debug('THEREST')
    $$ = { therest: $THEREST.trim() }
  }
  | WORD
  {
    // debug('WORD')
    $$ = { therest: $WORD }
  }
  | TEXT
  {
    // debug('TEXT')
    $$ = { therest: $TEXT }
  }
  | CLASSNAME
  {
    debug('CLASSNAME=', $CLASSNAME.substring(1))
    $$ = { classes: [$CLASSNAME.substring(1)] }
  }
  | ID
  {
    // debug('ID')
    $$ = { id: $ID.substring(1) }
  }
  | attrs
  {
    // debug('attrs')
    $$ = [{ attrs: $attrs }]
  }
  | DOT SPACE?
  {
    $$ = { state: 'TEXT_START' }
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
var util = require("util");
var _ = require("lodash");
var debugFunc = require('debug')
const debug = debugFunc('stream-reader-helper')

let tagAlreadyFound = false
let obj

const keysToMergeText = ['therest']

function merge(obj, src) {
  debug('merging', obj, src)

  if (Array.isArray(src) && src.length > 0)
    src = src.reduce(merge)

  if (util.isDeepStrictEqual(src, [ { therest: '' } ]))
    return obj

  const ret = _.mergeWith(obj, src, function (objValue, srcValue, key, object, source, stack) {
    debug('inside _mergeWith', key, objValue, srcValue)
    if (objValue == undefined && srcValue == undefined) {
      return {}
    }
    if (objValue == undefined) {
      return srcValue
    }
    if (srcValue == undefined) {
      return objValue
    }
    if (objValue != undefined && srcValue != undefined) {
      if (keysToMergeText.includes(key)) {
        // return objValue.concat(srcValue).join('')
        return objValue + srcValue
      }
      else {
        return objValue.concat(srcValue)
      }
    }
  })
  debug('returning', ret)
  return ret
  // return Object.assign(obj, src);
}

parser.main = function () {
  
  tagAlreadyFound = false
  function test(input, expected) {
    tagAlreadyFound = false
    debug(`\nTesting '${input}'...`)
    var actual = parser.parse(input)
    debug(input + ' ==> ', util.inspect(actual))
    assert.deepEqual(actual, expected)
  }



// const tagLines = fs.readFileSync('/Users/aakoch/projects/new-foo/workspaces/parser-generation/all_tags.txt', 'utf-8').split('\n')
// const tags = tagLines.join('|')
// debug(tags)


test('html', { type: 'tag', name: 'html' })
test("doctype html", { type: 'doctype', val: 'html' })
test("html(lang='en-US')", {"type":"tag","name":"html","attrs":["lang='en-US'"]})

test("include something", { type: 'include_directive', params: 'something' })
test("block here", { type: 'directive', name: 'block', params: 'here' })
test("head", { type: 'tag', name: 'head' })
test("meta(charset='UTF-8')", {"type":"tag","name":"meta","attrs":["charset='UTF-8'"]})
test("meta(name='viewport' content='width=device-width')", { type: 'tag', name: 'meta', attrs: ["name='viewport' content='width=device-width'"]})
test("title", {"type":"tag","name":"title"})
test("| White-space and character 160 | Adam Koch ", {"type":"text","text":"White-space and character 160 | Adam Koch "})
test("script(async src=\"https://www.googletagmanager.com/gtag/js?id=UA-452464-5\")", {"type":"tag","name":"script","attrs":["async src=\"https://www.googletagmanager.com/gtag/js?id=UA-452464-5\""], state: 'TEXT_START'})
test("script.  ", {"type":"tag","name":"script","state":"TEXT_START"})
test("<TEXT>window.dataLayer = window.dataLayer || [];   ", { type: 'text', text: 'window.dataLayer = window.dataLayer || [];   ' })
test("<TEXT>gtag('config', 'UA-452464-5');", {"type":"text","text":"gtag('config', 'UA-452464-5');"})
test("", "")
test("script test", {"type":"tag","name":"script","state":"TEXT_START","therest":"test"})
test("tag", { type: 'unknown', name: 'tag' })
test(".classname", { type: 'tag', classes: ['classname'] })
test("// some text", { type: 'comment', state: 'TEXT_START' })
test("// ", { type: 'comment', state: 'TEXT_START' })
test("//", { type: 'comment', state: 'TEXT_START' })
test('style(id=\'wp-block-library-inline-css\' type=\'text/css\').', {"type":"tag","name":"style","attrs":["id='wp-block-library-inline-css' type='text/css'"],"state":"TEXT_START"})
test('| #start-resizable-editor-section{figcaption{color:hsla(0,0%,100%,.65)}', {"type":"text","text":"#start-resizable-editor-section{figcaption{color:hsla(0,0%,100%,.65)}"})
test('body.post-template-default.single.single-post.postid-1620.single-format-standard.wp-embed-responsive.single-author.singular.two-column.right-sidebar', {"type":"tag","name":"body","classes":["post-template-default","single","single-post","postid-1620","single-format-standard","wp-embed-responsive","single-author","singular","two-column","right-sidebar"]})
test('#page.hfeed', {"type":"tag","id":"page","classes":["hfeed"]})
test('header#branding(role=\'banner\')', {"type":"tag","name":"header","id":"branding","attrs":["role='banner'"]})
test('h1#site-title', {type: 'tag', name: 'h1', id: 'site-title'})
test('a(href=\'https://www.adamkoch.com/\' rel=\'home\') Adam Koch', {type: 'tag', name: 'a', attrs: ['href=\'https://www.adamkoch.com/\' rel=\'home\''], therest: 'Adam Koch'})
test('h2#site-description Software Developer and Clean Code Advocate', {type: 'tag', name: 'h2', id: 'site-description', therest: 'Software Developer and Clean Code Advocate' })
test('h3.assistive-text Main menu', {type: 'tag', name: 'h3', classes: ['assistive-text'], therest: 'Main menu' })
test('ul#menu-header.menu', {type: 'tag', name: 'ul', id: 'menu-header', classes: ['menu']})
test('a(href=\'https://wordpress.adamkoch.com/posts/\') Posts', {type: 'tag', name: 'a', attrs: ['href=\'https://wordpress.adamkoch.com/posts/\''], therest: 'Posts'})
test('span.sep  by', {type:'tag', name: 'span', classes: ['sep'], therest: ' by' })
test('style.', {"type":"tag","name":"style","state":"TEXT_START"})
test('a.url.fn.n(href=\'https://wordpress.adamkoch.com/author/admin/\' title=\'View all posts by Adam\' rel=\'author\') Adam',  {
  type: 'tag',
  name: 'a',
  classes: [ 'url', 'fn', 'n' ],
  therest: 'Adam',
  attrs: ["href='https://wordpress.adamkoch.com/author/admin/' title='View all posts by Adam' rel='author'"]
})
test('p I came across a problem in Internet Explorer (it wasn\'t a problem with Firefox) when I was trying to compare two strings. To me, one string looked to have an extra space in the front. No problem, I\'ll just call the', {
  type: 'tag',
  name: 'p',
  therest: "I came across a problem in Internet Explorer (it wasn't a problem with Firefox) when I was trying to compare two strings. To me, one string looked to have an extra space in the front. No problem, I'll just call the"
})
test('.sd-content', { type: 'tag', classes: [ 'sd-content' ] })
test('th  Browser', { type: 'tag', name: 'th', therest: ' Browser' })
test('.sharedaddy.sd-sharing-enabled', {"type":"tag","classes":['sharedaddy', 'sd-sharing-enabled']})
test('time(datetime=\'2009-07-28T01:24:04-06:00\') 2009-07-28 at 1:24 AM', { type: 'tag', name: 'time', attrs: ['datetime=\'2009-07-28T01:24:04-06:00\''], therest: '2009-07-28 at 1:24 AM'} )
test('- var title = \'Fade Out On MouseOver Demo\'', { type: 'js', val: 'var title = \'Fade Out On MouseOver Demo\'' })
test('<TEXT>}).join(\' \')', { type: 'text', text: "}).join(' ')" })
test('  ', '')
test('#content(role=\'main\')', { type: 'tag', id: 'content', attrs: ['role=\'main\'']})
test('pre: code(class="language-scss").', { type: 'tag', name: 'pre', children: [ { type: 'tag', name: 'code', attrs: ['class="language-scss"'], state: 'TEXT_START'} ], state: 'NESTED'})

test('mixin sensitive()', { type: 'mixin_declaration', name: 'sensitive' })
test('extends ../templates/blogpost', {type: 'extends_declaration', template: '../templates/blogpost' })
test('append head', {type: 'append_declaration', template: 'head' })
test('p Maecenas sed lorem accumsan, luctus eros eu, tempor dolor. Vestibulum lorem est, bibendum vel vulputate eget, vehicula eu elit. Donec interdum cursus felis, vitae posuere libero. Cras et lobortis velit. Pellentesque in imperdiet justo. Suspendisse dolor mi, aliquet at luctus a, suscipit quis lectus. Etiam dapibus venenatis sem, quis aliquam nisl volutpat vel. Aenean scelerisque dapibus sodales. Vestibulum in pretium diam. Quisque et urna orci.', {type: 'tag', name: 'p', therest: 'Maecenas sed lorem accumsan, luctus eros eu, tempor dolor. Vestibulum lorem est, bibendum vel vulputate eget, vehicula eu elit. Donec interdum cursus felis, vitae posuere libero. Cras et lobortis velit. Pellentesque in imperdiet justo. Suspendisse dolor mi, aliquet at luctus a, suscipit quis lectus. Etiam dapibus venenatis sem, quis aliquam nisl volutpat vel. Aenean scelerisque dapibus sodales. Vestibulum in pretium diam. Quisque et urna orci.' })

test('+project(\'Images\', \'On going\')', { type: 'mixin_call', name: 'project', params: "'Images', 'On going'" })
test("+project('Moddable Two (2) Case', 'Needing Documentation ', ['print'])", { type: 'mixin_call', name: 'project', params: "'Moddable Two (2) Case', 'Needing Documentation ', ['print']" })
test('| . The only "gotcha" was I originally had "www.adamkoch.com" as the A record instead of "adamkoch.com". Not a big deal and easy to rectify.', { type: 'text', text: '. The only "gotcha" was I originally had "www.adamkoch.com" as the A record instead of "adamkoch.com". Not a big deal and easy to rectify.' })
test('<TEXT>| #start-resizable-editor-section{display:none}.wp-block-audio figcaption{color:#555;font-size:13px;', {"type":"text","text":"#start-resizable-editor-section{display:none}.wp-block-audio figcaption{color:#555;font-size:13px;" })
test('mixin sensitive()', { name: 'sensitive', type: 'mixin_declaration' })
test('- ', { type: 'js', val: '' })
};

