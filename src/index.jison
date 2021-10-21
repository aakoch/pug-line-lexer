/* Pug single line parser */

/* lexical grammar */
%lex

%options case-insensitive

// ID          [A-Z-]+"?"?
// NUM         ([1-9][0-9]+|[0-9])
space  [ \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]
tag         (a|abbr|acronym|address|applet|area|article|aside|audio|b|base|basefont|bdi|bdo|bgsound|big|blink|blockquote|body|br|button|canvas|caption|center|cite|code|col|colgroup|content|data|datalist|dd|del|details|dfn|dialog|dir|div|dl|dt|em|embed|fieldset|figcaption|figure|font|foo|footer|form|frame|frameset|h1|h2|h3|h4|h5|h6|head|header|hgroup|hr|html|i|iframe|image|img|input|ins|kbd|keygen|label|legend|li|link|main|map|mark|marquee|math|menu|menuitem|meta|meter|nav|nobr|noembed|noframes|noscript|object|ol|optgroup|option|output|p|param|picture|plaintext|portal|pre|progress|q|rb|rp|rt|rtc|ruby|s|samp|section|select|shadow|slot|small|source|spacer|span|strike|strong|sub|summary|sup|svg|table|tbody|td|template|textarea|tfoot|th|thead|time|title|tr|track|tt|u|ul|var|video|wbr|xmp)\b

pug_keyword             (append|block|case|default|doctype|each|else|extends|if|include|mixin|unless|when)\b

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
%x MULTI_LINE_ATTRS

%%

<INITIAL>{pug_keyword}
%{
  // yytext = yytext.substring(0, yytext.length - 1);
  this.pushState('AFTER_PUG_KEYWORD');
                                          return 'PUG_KEYWORD';
%}

<INITIAL>{tag}
%{
  // yytext = this.matches[1]
  this.pushState('AFTER_TAG_NAME');
                                          return 'TAG';
%}
<INITIAL>('script'|'style')
%{
  // yytext = this.matches[1]
  this.pushState('AFTER_TEXT_TAG_NAME');
                                          return 'TEXT_TAG';
%}
// <INITIAL>"!"                              return '!';
// <INITIAL>'"'                              return '"';
<INITIAL>{tag_id}
%{
  this.pushState('AFTER_TAG_NAME');
  yytext = yytext.substring(1);
                                          return 'TAG_ID';
%}
// <INITIAL>"#"                              return '#';
// <INITIAL>"$"                              return '$';
// <INITIAL>"&"                              return '&';
// <INITIAL>"'"                              return "'";
// <INITIAL>"("                              return '(';
// <INITIAL>")"                              return ')';
// <INITIAL>"*"                              return '*';
<INITIAL>{mixin_call}
%{
  yytext = yytext.substring(1);
  this.pushState('MIXIN_CALL_START');
                                          return 'MIXIN_CALL';
%}
// <INITIAL>"+"                              return '+';
<INITIAL>"-"(?:{space})?
%{
  this.pushState('AFTER_TAG_NAME');
  yytext = yytext.substring(1);
                                          return 'CODE';
%}
<INITIAL>{classname}
%{
  // debug('{classname}{space}?')
  this.pushState('AFTER_TAG_NAME');
  yytext = yytext.substring(1);
  // if (yytext.endsWith(' ')) {
  //   yytext = yytext.substring(0, yytext.length - 1)
  //   debug('10 yytext=', yytext)
  // }
  // else {
  //   debug('10 yytext doesn\'t end with a space')
  // }
                                          return 'CLASSNAME';
%}
// <INITIAL>"."                              return '.';
<INITIAL>"//"             
%{
  this.pushState('TEXT');
                                          return 'COMMENT';
%}
// <INITIAL>"/"                              return '/';
// <INITIAL>{digit}                          return 'DIGIT'
// <INITIAL>":"                              return ':';
<INITIAL>'<'[A-Z_]+'>'
%{
  this.pushState(yytext.substring(1, yytext.length - 1));
%}
// <INITIAL>"<"                              return '<';
// <INITIAL>"?"                              return '?';
// <INITIAL>"@"                              return '@';
// <INITIAL>"["                              return '[';
// <INITIAL>"]"                              return ']';
// <INITIAL>"_"                              return '_';
<INITIAL>"| "                             return 'PIPE';
<INITIAL>"|."
%{
  this.pushState('TEXT');
  this.unput('.');
%}

// <INITIAL>"}"                              return '}';
// <INITIAL>\s+                             ;


<AFTER_TAG_NAME,AFTER_ATTRS>':'{space}
%{
  this.popState();
                                          return 'NESTED_TAG_START';
%}
<AFTER_TAG_NAME,AFTER_TEXT_TAG_NAME>'('             
%{
  this.pushState('ATTRS_STARTED');
                                          return 'LPAREN';
%}
<ATTRS_STARTED>(.+)')'
%{
  // ')'\.\s*<<EOF>>
  this.popState()
  this.pushState('ATTRS_END')
  debug('20 this.matches=', this.matches)
  debug('20 this.matches.length=', this.matches.length)
  debug('20 yytext=', yytext)
  try {
    if (this.matches.length > 1) {    
      yytext = this.matches[1]
    }
  }
  catch (e) {
    console.error(e)
  }
  lparenOpen = false
  debug('20 yytext=', yytext)
                                          return ['RPAREN', 'ATTR_TEXT'];
%}
<ATTRS_STARTED>(.+)')'\s*<<EOF>>
%{
  this.popState()
  debug('30 this.matches=', this.matches)
  debug('30 this.matches.length=', this.matches.length)
  debug('30 yytext=', yytext)
  try {
    if (this.matches.length > 1) {    
      yytext = this.matches[1]
    }
  }
  catch (e) {
    console.error(e)
  }
  lparenOpen = false
  debug('30 yytext=', yytext)
                                          return ['RPAREN', 'ATTR_TEXT'];
%}
<ATTRS_STARTED>(.+)')'\.?\s*(.+)<<EOF>>
%{
  this.popState()
  this.pushState('ATTRS_END')
  debug('40 this.matches=', this.matches)
  this.unput(this.matches[2])
  yytext = yytext.substring(0, yytext.indexOf(this.matches[1]) + this.matches[1].length);
  debug('40 yytext=', yytext)
  lparenOpen = false
                                          return ['RPAREN', 'ATTR_TEXT'];
%}
<ATTRS_STARTED>(.+)\.?\s*<<EOF>>
%{
  this.popState()
  debug('50 this.matches=', this.matches)
  debug('50 this.matches.length=', this.matches.length)
  debug('50 yytext=', yytext)
  try {
    if (this.matches.length > 1) {    
      yytext = this.matches[1]
    }
  }
  catch (e) {
    console.error(e)
  }
  debug('50 yytext=', yytext)
                                          return 'ATTR_TEXT_CONT';
%}

<AFTER_TAG_NAME>{tag_id}
%{
  this.pushState('AFTER_TAG_NAME');
  yytext = this.matches[1].substring(1)
                                          return 'TAG_ID';
%}
<AFTER_TAG_NAME>{classname}
%{
  yytext = this.matches[1].substring(1);
  debug('60 yytext=', yytext)
                                          return 'CLASSNAME';
%}
<AFTER_TAG_NAME,AFTER_PUG_KEYWORD,AFTER_TEXT_TAG_NAME>{space}
%{
  debug('space');
                                                              return 'SPACE';
%}
<ATTRS_END>{space}
%{
  this.pushState('TEXT');
  debug('space');
%}
<AFTER_TAG_NAME,AFTER_TEXT_TAG_NAME>'.'\s*<<EOF>>             return 'DOT_END';
<AFTER_TAG_NAME,AFTER_PUG_KEYWORD,AFTER_TEXT_TAG_NAME,NO_MORE_SPACE>.+
%{
  // if (yytext.startsWith(' ') {
  //   yytext = yytext.substring(1);
  // }
  debug('70 yytext=', yytext);
                                          return 'TEXT';
%}


<ATTRS_END>'='{space}
%{
  this.popState();
  this.pushState('ASSIGNMENT_VALUE');
                                          return 'ASSIGNMENT';
%}
<ATTRS_END>'.'
%{
  this.popState();
                                          return 'DOT_END';
%}
<ASSIGNMENT_VALUE>.+
%{
  this.popState();
                                          return 'ASSIGNMENT_VALUE';
%}
<ATTRS_END>.+
%{
  yytext = yytext.substring(1)
  debug('6 yytext=', yytext)
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
<MIXIN_CALL_START>{space}$             
%{
  this.popState();
%}

<ONLY_FOR_SYNTAX_COLORING>'))'             ;

<TEXT>(?:\|' ')?(.+)             
%{
  debug('80 this.matches=', this.matches)
  yytext = this.matches[1]
  debug('80 yytext=', yytext)
                                          return 'TEXT';
%}

<MULTI_LINE_ATTRS>')'                     return 'ATTR_TEXT_END';
<MULTI_LINE_ATTRS>.+                      return 'ATTR_TEXT';

// <INITIAL>{space}.+      
// %{
//   debug('<INITIAL>{space}.+ yytext=', yytext)
//   yytext = yytext.substring(1);
//                                           return 'TEXT';
// %}
/lex

%ebnf
%options token-stack 

%% 

/* language grammar */

start
  : EOF
  | line EOF
  {
    if (lparenOpen && !$line.hasOwnProperty('state')) {
      $$ = Object.assign($line, { state: 'MULTI_LINE_ATTRS' })
    }
  }
  ;

line
  : first_token
  | first_token line_end
  {
    debug('line:first_token line_end: first_token=', $first_token, ', line_end=', $line_end)
    $$ = merge($first_token, $line_end)
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
  | tag_part NESTED_TAG_START line
  {
    debug('tag_part+ NESTED_TAG_START line DOT_END? tag_part=', $1, 'line=', $3)
    $$ = merge({ type: 'tag', state: 'NESTED', children: [$3] }, $1)
  }
  | CODE
  {
    $$ = { type: 'code', val: $CODE, state: 'UNBUF_CODE_START' }
  }
  | CODE TEXT
  {
    $$ = { type: 'code', val: $TEXT }
  }
  | ATTR_TEXT_END
  {
    $$ = { type: 'multiline_attrs_end' }
  }
  | ATTR_TEXT
  {
    $$ = { attrs: [$ATTR_TEXT] }
  }
  ;

line_splitter
  : SPACE
  {
    $$ = undefined
  }
  ;

text_tag_line
  : TEXT_TAG line_splitter? something_following_text_tag
  {
    $$ = Object.assign({ type: 'tag', name: $TEXT_TAG, state: 'TEXT_START' }, $3)
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
  | LPAREN ATTR_TEXT RPAREN?
  {
    if ($ATTR_TEXT.endsWith(')') || $ATTR_TEXT.match(/[^\)]+\)\.?\s*/)) {
      lparenOpen = false
    }
    else {
      debug('LPAREN ATTR_TEXT: didn\'t end with ): ' + $ATTR_TEXT)
    }
    $$ = { attrs: [$ATTR_TEXT] }
  }
  | LPAREN ATTR_TEXT RPAREN DOT_END
  {
    $$ = { attrs: [$ATTR_TEXT], state: 'TEXT_START' }
  }
  ;

first_token
  : something_followed_by_text
  {
    yy.lexer.pushState('TEXT')
    debug('first_token: something_followed_by_text=', $1)
  }
  | PUG_KEYWORD SPACE
  {
    $$ = { type: 'pug_keyword', name: $PUG_KEYWORD }
  }
  ;

something_followed_by_text
  : tag_part
  {
      debug('something_followed_by_text: tag_part=', $tag_part)
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
  | SPACE
  {
    $$ = { state: 'TEXT_START' }
  }
  ;

first_token_for_reals
  : TAG
  {
    $$ = { name: $TAG, type: 'tag' }
  }
  | MIXIN_CALL
  {
    debug('MIXIN_CALL=', $1)
    $$ = { type: 'mixin_call', mixin_name: $1 }
  }
  | TAG_ID
  {
    $$ = { id: $TAG_ID }
  }
  | CLASSNAME 
  {
    $$ = { type: 'tag', classes: [$1] }
  }
  ;

after_tags
  : after_tags after_tag
  {
    $$ = merge($after_tags, $after_tag)
  }
  | after_tag
  ;

after_tag
  : LPAREN ATTR_TEXT RPAREN
  {
    $$ = { attrs: [$2] }
  }
  | LPAREN ATTR_TEXT_CONT
  {
    $$ = { attrs: [$2], state: 'MULTI_LINE_ATTRS' }
  }
  | LPAREN
  {
    $$ = { state: 'MULTI_LINE_ATTRS' }
  }
  | ASSIGNMENT ASSIGNMENT_VALUE
  {
    $$ = { assignment: true, assignment_val: $ASSIGNMENT_VALUE }
  }
  | CLASSNAME
  {
    $$ = { type: 'tag', classes: [$1] }
  }
  | TAG_ID
  {
    $$ = { id: $TAG_ID }
  }
  ;

tag_part
  : first_token_for_reals
  | first_token_for_reals after_tags
  {
    $$ = $1
    if ($2) 
      $$ = merge($$, $2)
  }
  | first_token_for_reals line_splitter
  {
    $$ = $1
    if ($2) 
      $$ = merge($$, $2)
  }
  | first_token_for_reals line_splitter after_tags
  {
    $$ = $1
    if ($3) 
      $$ = merge($$, $3) 
    if ($2) 
      $$ = merge($$, $2)
  }
  ;

line_end
  : TEXT
  {
    debug('line_end: TEXT=', $TEXT)
    // if ($TEXT.trim().length)
    $$ = { type: 'text', val: $TEXT }
  }
  | DOT_END
  {
    debug('line_end: DOT_END')
    $$ = { state: 'TEXT_START' }
  }
  ;

%% 
__module_imports__

const debug = debugFunc('pug-line-lexer')

let tagAlreadyFound = false
let obj
var lparenOpen = false
const keysToMergeText = ['therest']

function rank(type1, type2) {
  if (type2 === 'text') {
    return type1
  }
  else if (type1 === type2) {
    return type1
  }
  else {
    return type1.concat(type2)
  }
} 

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
         return rank(objValue, srcValue)
      }
    }
  })
  debug('merging', ' returning', ret)
  return ret
  //  return Object.assign(obj, src);
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




test('code(class="language-scss").', { name: 'code', type: 'tag', attrs: [ 'class="language-scss"' ], state: 'TEXT_START' })

test('p: a(href="https://www.thingiverse.com/thing:4578862") Thingiverse', {
  children: [
    {
      name: 'a',
      attrs: ['href="https://www.thingiverse.com/thing:4578862"'],
      type: 'tag',
      val: 'Thingiverse'
    }
  ],
  name: 'p',
  state: 'NESTED',
  type: 'tag'
})

test('.project(class= (tags || []).map((tag) => tag.replaceAll(" ", "_")).join(" "))', {
  classes: [ 'project' ],
  attrs: [
    'class= (tags || []).map((tag) => tag.replaceAll(" ", "_")).join(" ")'
  ],
  type: 'tag'
})

test('.status-wrapper Status:', { classes: [ 'status-wrapper' ], type: 'tag', val: 'Status:' })

test('+sensitive ', {
  mixin_name: 'sensitive',
  type: 'mixin_call'
})

test('a(href=url)= url', {
  assignment: true,
  assignment_val: 'url',
  attrs: [
    'href=url'
  ],
  name: 'a',
  type: 'tag'
})
test('a(href=\'/user/\' + id, class=\'button\')', {
  attrs: [
    "href='/user/' + id, class='button'"
  ],
  name: 'a',
  type: 'tag'
})

test('- function answer() { return 42; }', {
  type: 'code',
  val: 'function answer() { return 42; }'
})
test('a(href=\'/user/\' + id, class=\'button\')', {
  attrs: [
    "href='/user/' + id, class='button'"
  ],
  name: 'a',
  type: 'tag'
})
test('a(href  =  \'/user/\' + id, class  =  \'button\')', {
  attrs: [
    "href  =  '/user/' + id, class  =  'button'"
  ],
  name: 'a',
  type: 'tag'
})

test('a(class = [\'class1\', \'class2\'])', {
  attrs: [
    "class = ['class1', 'class2']"
  ],
  name: 'a',
  type: 'tag'
})
test('a.tag-class(class = [\'class1\', \'class2\'])', {
  attrs: [
    "class = ['class1', 'class2']"
  ],
  classes: [
    'tag-class'
  ],
  name: 'a',
  type: 'tag'
})
test('a(href=\'/user/\' + id class=\'button\')', {
  attrs: [
    "href='/user/' + id class='button'"
  ],
  name: 'a',
  type: 'tag'
})
test('a(href  =  \'/user/\' + id class  =  \'button\')', {
  attrs: [
    "href  =  '/user/' + id class  =  'button'"
  ],
  name: 'a',
  type: 'tag'
}
)
test('meta(key=\'answer\' value=answer())', {
  attrs: [
    "key='answer' value=answer()"
  ],
  name: 'meta',
  type: 'tag'
})

test('div(id=id)&attributes({foo: \'bar\'})', {
  attrs: [
    "id=id)&attributes({foo: 'bar'}"
  ],
  name: 'div',
  type: 'tag'
})
test('div(foo=null bar=bar)&attributes({baz: \'baz\'})', {
  attrs: [
    "foo=null bar=bar)&attributes({baz: 'baz'}"
  ],
  name: 'div',
  type: 'tag'
})

test('foo(abc', {type: 'tag', name: 'foo', attrs: ['abc'], state: 'MULTI_LINE_ATTRS'})
test('<MULTI_LINE_ATTRS>,def)', { attrs: [',def)'] })

test('span(', {type: 'tag', name: 'span', state: 'MULTI_LINE_ATTRS'})
test('<MULTI_LINE_ATTRS>v-for="item in items"', {
  attrs: [
    'v-for="item in items"'
  ]
})
test('<MULTI_LINE_ATTRS>:key="item.id"', {
  attrs: [
    ':key="item.id"'
  ]
})
test('<MULTI_LINE_ATTRS>:value="item.name"', {
  attrs: [
    ':value="item.name"'
  ]
})
test('<MULTI_LINE_ATTRS>)', {type: 'multiline_attrs_end'})
test('a(:link="goHere" value="static" :my-value="dynamic" @click="onClick()" :another="more") Click Me!', {
  attrs: [
    ':link="goHere" value="static" :my-value="dynamic" @click="onClick()" :another="more"'
  ],
  name: 'a',
  type: 'tag',
  val: 'Click Me!'
})

test('foo(data-user=user)', {
  attrs: [
    'data-user=user'
  ],
  name: 'foo',
  type: 'tag'
})
test('foo(data-items=[1,2,3])', {
  attrs: [
    'data-items=[1,2,3]'
  ],
  name: 'foo',
  type: 'tag'
})
test('foo(data-username=\'tobi\')', {
  attrs: [
    "data-username='tobi'"
  ],
  name: 'foo',
  type: 'tag'
})
test('foo(data-escaped={message: "Let\'s rock!"})', {
  attrs: [
    `data-escaped={message: "Let's rock!"}`
  ],
  name: 'foo',
  type: 'tag'
})
test('foo(data-ampersand={message: "a quote: &quot; this & that"})', {
  attrs: [
    'data-ampersand={message: "a quote: &quot; this & that"}'
  ],
  name: 'foo',
  type: 'tag'
})
test('foo(data-epoc=new Date(0))', {
  attrs: [
    'data-epoc=new Date(0)'
  ],
  name: 'foo',
  type: 'tag'
})


test('+sensitive', {
  mixin_name: 'sensitive',
  type: 'mixin_call'
})

test('html', { type: 'tag', name: 'html' })
test('html ', { type: 'tag', name: 'html' }, false)

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

test('pre.', {
  name: 'pre',
  state: 'TEXT_START',
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

test('|. The only "gotcha" was I originally had "www.adamkoch.com" as the A record instead of "adamkoch.com". Not a big deal and easy to rectify.', { type: 'text', val: '. The only "gotcha" was I originally had "www.adamkoch.com" as the A record instead of "adamkoch.com". Not a big deal and easy to rectify.' })

test('.rule: p.', {
  children: [
    {
      name: 'p',
      type: 'tag',
      state: 'TEXT_START'
    }
  ],
  classes: ['rule'],
  state: 'NESTED',
  type: 'tag'
})
test('.rule.unratified: p.', {
  children: [
    {
      name: 'p',
      type: 'tag',
      state: 'TEXT_START'
    }
  ],
  classes: ['rule', 'unratified'],
  state: 'NESTED',
  type: 'tag'
})
try {
  test("tag", { type: 'unknown', name: 'tag' })
throw AssertionError('Expected exception')
} catch (e) {}

};

