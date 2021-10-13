/* simple parser */

/* lexical grammar */
%lex

%options case-insensitive

// ID          [A-Z-]+"?"?
// NUM         ([1-9][0-9]+|[0-9])
space			[ \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]
tag         \b(a|abbr|acronym|address|applet|area|article|aside|audio|b|base|basefont|bdi|bdo|bgsound|big|blink|blockquote|body|br|button|canvas|caption|center|cite|code|col|colgroup|content|data|datalist|dd|del|details|dfn|dialog|dir|div|dl|dt|em|embed|fieldset|figcaption|figure|font|footer|form|frame|frameset|h1|h2|h3|h4|h5|h6|head|header|hgroup|hr|html|i|iframe|image|img|input|ins|kbd|keygen|label|legend|li|link|main|map|mark|marquee|math|menu|menuitem|meta|meter|nav|nobr|noembed|noframes|noscript|object|ol|optgroup|option|output|p|param|picture|plaintext|portal|pre|progress|q|rb|rp|rt|rtc|ruby|s|samp|section|select|shadow|slot|small|source|spacer|span|strike|strong|sub|summary|sup|svg|table|tbody|td|template|textarea|tfoot|th|thead|time|title|tr|track|tt|u|ul|var|video|wbr|xmp)\b

pug_keyword                \b(append|block|doctype|extends|include|mixin)\b

letter                  [a-z] // case insensitive
digit                   [0-9]
classname               \.[a-z0-9-]+
tag_id                  #[a-z-]+
mixin_call              \+[a-z]+\b

%x TEXT
%x TEXT_START
%x AFTER_TAG_NAME
%x ATTRS_STARTED
%x ATTR_TEXT
%x MIXIN_CALL_START
%s ATTRS_END
%x UNBUF_CODE_START
%x UNBUF_CODE
%x ONLY_FOR_SYNTAX_COLORING

%%

<INITIAL>{pug_keyword}{space}    
%{
  yytext = yytext.substring(0, yytext.length - 1);
  this.pushState('TEXT');
                                          return 'PUG_KEYWORD';
%}

// case for the 'block' keyword is used inside of a mixin declaration but doesn't have a space after
<INITIAL>'block'    
%{
  this.pushState('TEXT');
                                          return 'PUG_KEYWORD';
%}
<INITIAL>{tag}(?:' '?)
%{
  yytext = this.matches[1]
  this.pushState('AFTER_TAG_NAME');
                                          return 'TAG';
%}
<INITIAL>('script'|'style')(?:' '?)
%{
  yytext = this.matches[1]
  this.pushState('AFTER_TAG_NAME');
                                          return 'TEXT_TAG';
%}
<INITIAL>"!"                              return '!';
<INITIAL>'"'                              return '"';
<INITIAL>{tag_id}
%{
  this.pushState('AFTER_TAG_NAME');
  yytext = yytext.substring(1);
                                          return 'TAG_ID';
%}
<INITIAL>"#"                              return '#';
<INITIAL>"$"                              return '$';
<INITIAL>"&"                              return '&';
<INITIAL>"'"                              return "'";
<INITIAL>"("                              return '(';
<INITIAL>")"                              return ')';
<INITIAL>"*"                              return '*';
<INITIAL>{mixin_call}
%{
  yytext = yytext.substring(1);
  this.pushState('MIXIN_CALL_START');
                                          return 'MIXIN_CALL';
%}
<INITIAL>"+"                              return '+';
<INITIAL>"-"(?:' ')?
%{
  this.pushState('AFTER_TAG_NAME');
  yytext = yytext.substring(1);
                                          return 'CODE';
%}
<INITIAL>{classname}
%{
  yytext = yytext.substring(1);
                                          return 'CLASSNAME';
%}
<INITIAL>"."                              return '.';
<INITIAL>"//"             
%{
  this.pushState('TEXT');
                                          return 'COMMENT';
%}
<INITIAL>"/"                              return '/';
<INITIAL>{digit}                          return 'DIGIT'
<INITIAL>":"                              return ':';
<INITIAL>'<'[A-Z_]+'>'
%{
  this.pushState(yytext.substring(1, yytext.length - 1));
%}
<INITIAL>"<"                              return '<';
<INITIAL>"?"                              return '?';
<INITIAL>"@"                              return '@';
<INITIAL>"["                              return '[';
<INITIAL>"]"                              return ']';
<INITIAL>"_"                              return '_';
<INITIAL>"| "                             return 'PIPE';
<INITIAL>"}"                              return '}';
<INITIAL>\s+                             ;


<AFTER_TAG_NAME>': '
%{
  this.popState();
                                          return 'NESTED_TAG_START';
%}
<AFTER_TAG_NAME>'('             
%{
  this.pushState('ATTRS_STARTED');
                                          return 'LPAREN';
%}
<ATTRS_STARTED>(.+)')'\.?\s*<<EOF>>
%{
  this.popState()
  debug('1 this.matches=', this.matches)
  debug('1 this.matches.length=', this.matches.length)
  debug('1 yytext=', yytext)
  try {
  if (this.matches.length > 1) {    
    yytext = this.matches[1]
  }
  }
  catch (e) {
    console.error(e)
  }
  debug('1.2 yytext=', yytext)
                                          return 'ATTR_TEXT';
%}
<ATTRS_STARTED>(.+)')'\.?\s*(.+)<<EOF>>
%{
  this.popState()
  this.pushState('ATTRS_END')
  debug('2 this.matches=', this.matches)
  this.unput(this.matches[2])
  yytext = yytext.substring(0, yytext.indexOf(this.matches[1]) + this.matches[1].length);
  debug('2 yytext=', yytext)
                                          return 'ATTR_TEXT';
%}

<AFTER_TAG_NAME>{tag_id}(?:' '?)
%{
  this.pushState('AFTER_TAG_NAME');
  yytext = this.matches[1].substring(1)
                                          return 'TAG_ID';
%}
<AFTER_TAG_NAME>{classname}(?:' '?)
%{
  yytext = this.matches[1].substring(1);
  debug('3 yytext=', yytext)
                                          return 'CLASSNAME';
%}
<AFTER_TAG_NAME>'.'\s*<<EOF>>             return 'DOT_END';
<AFTER_TAG_NAME>.+
%{
  debug('4 yytext=', yytext)
                                          return 'TEXT';
%}


<ATTRS_END>.+
%{
  debug('4.5 yytext=', yytext)
                                          return 'TEXT';
%}
<UNBUF_CODE_START>.+
%{
  this.pushState('UNBUF_CODE');
                                          return 'UNBUF_CODE_START';
%}
<UNBUF_CODE>.+
%{
                                          return 'UNBUF_CODE';
%}

<MIXIN_CALL_START>'('             
%{
  this.popState();
  this.pushState('ATTRS_STARTED');
                                          return 'LPAREN';
%}

<ONLY_FOR_SYNTAX_COLORING>')'             ;

<TEXT>(?:\|' ')?(.+)             
%{
  debug('5 this.matches=', this.matches)
  yytext = this.matches[1]
  debug('5 yytext=', yytext)
                                          return 'TEXT';
%}

/lex

%ebnf
%options token-stack 

%% 

/* language grammar */

start
  : EOF
  | line EOF
  ;

line
  : first_token
  | first_token TEXT
  {
    debug('first_token TEXT: first_token=', $first_token, ', TEXT=', $TEXT)
    $$ = Object.assign($first_token, { val: $TEXT } )
  }
  | TEXT
  {
    debug('TEXT=', $TEXT)
    $$ = { type: 'text', val: $TEXT }
  }
  | UNBUF_CODE_START
  {
    debug('UNBUF_CODE_START=', $UNBUF_CODE_START)
    $$ = { type: 'unbuffered_code', val: $UNBUF_CODE_START }
  }
  | UNBUF_CODE
  {
    debug('UNBUF_CODE=', $UNBUF_CODE)
    $$ = { type: 'unbuffered_code', val: $UNBUF_CODE }
  }
  | text_tag_line
  | TAG NESTED_TAG_START something_followed_by_text DOT_END?
  {
    $$ = { type: 'tag', name: $TAG, state: 'NESTED', children: [Object.assign($something_followed_by_text, {state: 'TEXT_START'})] }
  }
  | CODE 
  {
    $$ = { type: 'code', val: $CODE, state: 'UNBUF_CODE_START' }
  }
  | CODE TEXT
  {
    $$ = { type: 'code', val: $TEXT }
  }
  ;

text_tag_line
  : TEXT_TAG something_following_text_tag
  {
    $$ = Object.assign({ type: 'tag', name: $TEXT_TAG, state: 'TEXT_START' }, $something_following_text_tag)
  }
  ;

something_following_text_tag
  : TEXT
  {
    $$ = { val: $TEXT }
  }
  | DOT_END
  {
    $$ = { }
  }
  | LPAREN ATTR_TEXT
  {
    $$ = { attrs: [$ATTR_TEXT] }
  }
  ;

first_token
  : something_followed_by_text
  {
    yy.lexer.pushState('TEXT')
    debug('something_followed_by_text=', $something_followed_by_text)
  }
  | PUG_KEYWORD
  {
    $$ = { type: 'pug_keyword', name: $PUG_KEYWORD }
  }
  | MIXIN_CALL tag_part?
  {
    debug('MIXIN_CALL=', $1)
    $$ = { type: 'mixin_call', mixin_name: $1 }
    if ($2) {
      Object.assign($$, $2)
    }
  }
  ;

something_followed_by_text
  : tag_part+
  {
    $$ = { }
    $1.forEach(obj => {
      debug('obj=', obj)
      $$ = merge($$, obj)
    })
    if (!$$.hasOwnProperty('type')) {
        $$ = Object.assign($$, { type: 'tag' })
    }
  }
  | PIPE
  {
    $$ = { type: 'text' }
  }
  | TEXT_START
  {
    $$ = { type: 'TEXT_START', val: $1 }
  }
  | COMMENT
  {
    $$ = { type: 'comment', state: 'TEXT_START' }
  }
  ;

tag_part
  : TAG
  {
    $$ = { name: $TAG }
  }
  | TAG_ID
  {
    $$ = { id: $TAG_ID }
  }
  | CLASSNAME
  {
    $$ = { classes: [$1] }
  }
  | LPAREN ATTR_TEXT
  {
    $$ = { attrs: [$ATTR_TEXT] }
  }
  ;

%% 
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
    debug('merging', 'inside _mergeWith', key, objValue, srcValue)
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
         return objValue + srcValue
      }
      else {
         return objValue.concat(srcValue)
      }
    }
  })
  debug('merging', ' returning', ret)
   return ret
  //  return Object.assign(obj, src);
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

// test('div(style="display:none" class= tag.replaceAll(" ", "_"))', {})

test('+sensitive', {
  mixin_name: 'sensitive',
  type: 'mixin_call'
})

test('html', { type: 'tag', name: 'html' })

// test("doctype html", { type: 'doctype', val: 'html' })
test('doctype html', { type: 'pug_keyword', name: 'doctype', val: 'html' })

test("html(lang='en-US')", {"type":"tag","name":"html","attrs":["lang='en-US'"]})

// test("include something", { type: 'include_directive', params: 'something' })
test('include something', { type: 'pug_keyword', name: 'include', val: 'something' })

// test("block here", { type: 'directive', name: 'block', params: 'here' })
test("block here", { type: 'pug_keyword', name: 'block', val: 'here' })

test("head", { type: 'tag', name: 'head' })
test("meta(charset='UTF-8')", {"type":"tag","name":"meta","attrs":["charset='UTF-8'"]})
test("meta(name='viewport' content='width=device-width')", { type: 'tag', name: 'meta', attrs: ["name='viewport' content='width=device-width'"]})
test("title", {"type":"tag","name":"title"})
test("| White-space and character 160 | Adam Koch ", {"type":"text","val":"White-space and character 160 | Adam Koch "})
test("script(async src=\"https://www.googletagmanager.com/gtag/js?id=UA-452464-5\")", {"type":"tag","name":"script","attrs":["async src=\"https://www.googletagmanager.com/gtag/js?id=UA-452464-5\""], state: 'TEXT_START'})
test("script.  ", {"type":"tag","name":"script","state":"TEXT_START"})
test("<TEXT>window.dataLayer = window.dataLayer || [];   ", { type: 'text', val: 'window.dataLayer = window.dataLayer || [];   ' })
test("<TEXT>gtag('config', 'UA-452464-5');", {"type":"text","val":"gtag('config', 'UA-452464-5');"})
test("", "")
test("script test", {"type":"tag","name":"script","state":"TEXT_START","val":"test"})
test(".classname", { type: 'tag', classes: ['classname'] })

//test("// some text", { type: 'comment', state: 'TEXT_START' })
test("// some text", { type: 'comment', state: 'TEXT_START', val: ' some text' })

// test("// ", { type: 'comment', state: 'TEXT_START' })
test("// ", { type: 'comment', val: ' ', state: 'TEXT_START' })

test("//", { type: 'comment', state: 'TEXT_START' })


test('a.url.fn.n(href=\'https://wordpress.adamkoch.com/author/admin/\' title=\'View all posts by Adam\' rel=\'author\') Adam',  {
  type: 'tag',
  name: 'a',
  classes: [ 'url', 'fn', 'n' ],
  val: 'Adam',
  attrs: ["href='https://wordpress.adamkoch.com/author/admin/' title='View all posts by Adam' rel='author'"]
})
test('style(id=\'wp-block-library-inline-css\' type=\'text/css\').', {"type":"tag","name":"style","attrs":["id='wp-block-library-inline-css' type='text/css'"],"state":"TEXT_START"})
test('| #start-resizable-editor-section{figcaption{color:hsla(0,0%,100%,.65)}', {"type":"text","val":"#start-resizable-editor-section{figcaption{color:hsla(0,0%,100%,.65)}"})
test('body.post-template-default.single.single-post.postid-1620.single-format-standard.wp-embed-responsive.single-author.singular.two-column.right-sidebar', {"type":"tag","name":"body","classes":["post-template-default","single","single-post","postid-1620","single-format-standard","wp-embed-responsive","single-author","singular","two-column","right-sidebar"]})
test('#page.hfeed', {"type":"tag","id":"page","classes":["hfeed"]})
test('header#branding(role=\'banner\')', {"type":"tag","name":"header","id":"branding","attrs":["role='banner'"]})
test('h1#site-title', {type: 'tag', name: 'h1', id: 'site-title'})
test('a(href=\'https://www.adamkoch.com/\' rel=\'home\') Adam Koch', {type: 'tag', name: 'a', attrs: ['href=\'https://www.adamkoch.com/\' rel=\'home\''], val: 'Adam Koch'})
test('h2#site-description Software Developer and Clean Code Advocate', {type: 'tag', name: 'h2', id: 'site-description', val: 'Software Developer and Clean Code Advocate' })
test('h3.assistive-text Main menu', {type: 'tag', name: 'h3', classes: ['assistive-text'], val: 'Main menu' })
test('ul#menu-header.menu', {type: 'tag', name: 'ul', id: 'menu-header', classes: ['menu']})
test('a(href=\'https://wordpress.adamkoch.com/posts/\') Posts', {type: 'tag', name: 'a', attrs: ['href=\'https://wordpress.adamkoch.com/posts/\''], val: 'Posts'})
test('span.sep  by', {type:'tag', name: 'span', classes: ['sep'], val: ' by' })
test('style.', {"type":"tag","name":"style","state":"TEXT_START"})
test('p I came across a problem in Internet Explorer (it wasn\'t a problem with Firefox) when I was trying to compare two strings. To me, one string looked to have an extra space in the front. No problem, I\'ll just call the', {
  type: 'tag',
  name: 'p',
  val: "I came across a problem in Internet Explorer (it wasn't a problem with Firefox) when I was trying to compare two strings. To me, one string looked to have an extra space in the front. No problem, I'll just call the"
})
test('.sd-content', { type: 'tag', classes: [ 'sd-content' ] })
test('th  Browser', { type: 'tag', name: 'th', val: ' Browser' })
test('.sharedaddy.sd-sharing-enabled', {"type":"tag","classes":['sharedaddy', 'sd-sharing-enabled']})
test('time(datetime=\'2009-07-28T01:24:04-06:00\') 2009-07-28 at 1:24 AM', { type: 'tag', name: 'time', attrs: ['datetime=\'2009-07-28T01:24:04-06:00\''], val: '2009-07-28 at 1:24 AM'} )
test('- var title = \'Fade Out On MouseOver Demo\'', { type: 'code', val: 'var title = \'Fade Out On MouseOver Demo\'' })
test('<TEXT>}).join(\' \')', { type: 'text', val: "}).join(' ')" })
test('  ', '')
test('#content(role=\'main\')', { type: 'tag', id: 'content', attrs: ['role=\'main\'']})
test('pre: code(class="language-scss").', { type: 'tag', name: 'pre', children: [ { type: 'tag', name: 'code', attrs: ['class="language-scss"'], state: 'TEXT_START'} ], state: 'NESTED'})

test('mixin sensitive()', { type: 'pug_keyword', name: 'mixin', val: 'sensitive()' })
test('extends ../templates/blogpost', {
  name: 'extends',
  type: 'pug_keyword',
  val: '../templates/blogpost'
})
test('append head', {
  name: 'append',
  type: 'pug_keyword',
  val: 'head'
})
test('p Maecenas sed lorem accumsan, luctus eros eu, tempor dolor. Vestibulum lorem est, bibendum vel vulputate eget, vehicula eu elit. Donec interdum cursus felis, vitae posuere libero. Cras et lobortis velit. Pellentesque in imperdiet justo. Suspendisse dolor mi, aliquet at luctus a, suscipit quis lectus. Etiam dapibus venenatis sem, quis aliquam nisl volutpat vel. Aenean scelerisque dapibus sodales. Vestibulum in pretium diam. Quisque et urna orci.', {type: 'tag', name: 'p', val: 'Maecenas sed lorem accumsan, luctus eros eu, tempor dolor. Vestibulum lorem est, bibendum vel vulputate eget, vehicula eu elit. Donec interdum cursus felis, vitae posuere libero. Cras et lobortis velit. Pellentesque in imperdiet justo. Suspendisse dolor mi, aliquet at luctus a, suscipit quis lectus. Etiam dapibus venenatis sem, quis aliquam nisl volutpat vel. Aenean scelerisque dapibus sodales. Vestibulum in pretium diam. Quisque et urna orci.' })

test('+project(\'Images\', \'On going\')', {
  attrs: [
    "'Images', 'On going'"
  ],
  type: 'mixin_call',
  mixin_name: 'project'
})
// test("+project('Moddable Two (2) Case', 'Needing Documentation ', ['print'])", { type: 'mixin_call', name: 'project', params: "'Moddable Two (2) Case', 'Needing Documentation ', ['print']" })
test("+project('Moddable Two (2) Case', 'Needing Documentation ', ['print'])", {
  attrs: [
    "'Moddable Two (2) Case', 'Needing Documentation ', ['print']"
  ],
  type: 'mixin_call',
  mixin_name: 'project'
})
test('| . The only "gotcha" was I originally had "www.adamkoch.com" as the A record instead of "adamkoch.com". Not a big deal and easy to rectify.', { type: 'text', val: '. The only "gotcha" was I originally had "www.adamkoch.com" as the A record instead of "adamkoch.com". Not a big deal and easy to rectify.' })
test('<TEXT>| #start-resizable-editor-section{display:none}.wp-block-audio figcaption{color:#555;font-size:13px;', {"type":"text","val":"#start-resizable-editor-section{display:none}.wp-block-audio figcaption{color:#555;font-size:13px;" })
test('- ', { type: 'code', val: ' ', state: 'UNBUF_CODE_START' })
test('mixin project(title)', {
  name: 'mixin',
  type: 'pug_keyword',
  val: 'project(title)'
})
test('+code(\'Pretty-print any JSON file\') jq \'.\' package.json',
{
  attrs: [
    "'Pretty-print any JSON file'"
  ],
  mixin_name: 'code',
  type: 'mixin_call',
  val: "jq '.' package.json"
} )
test('// comment', {
  state: 'TEXT_START',
  type: 'comment',
  val: ' comment'
})
test('meta(property=\'og:description\' content=\'I came across a problem in Internet Explorer (it wasn\\\'t a problem with Firefox) when I...\')',  {
  type: 'tag',
  name: 'meta',
  attrs: ["property=\'og:description' content='I came across a problem in Internet Explorer (it wasn\\'t a problem with Firefox) when I...'"]
})

test('-', {
  state: 'UNBUF_CODE_START',
  type: 'code',
  val: ''
})

test(' -', {
  state: 'UNBUF_CODE_START',
  type: 'code',
  val: ''
})

test('<UNBUF_CODE>var i', {
  type: 'unbuffered_code',
  val: 'var i'
})

test("link(rel='alternate' type='application/rss+xml' title='Adam Koch &raquo; White-space and character 160 Comments Feed' href='https://wordpress.adamkoch.com/2009/07/25/white-space-and-character-160/feed/')", {
  attrs: [
    "rel='alternate' type='application/rss+xml' title='Adam Koch &raquo; White-space and character 160 Comments Feed' href='https://wordpress.adamkoch.com/2009/07/25/white-space-and-character-160/feed/'"
  ],
  name: 'link',
  type: 'tag'
})

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

try {
test("tag", { type: 'unknown', name: 'tag' })
throw AssertionError('Expected exception')
} catch (e) {}

};

