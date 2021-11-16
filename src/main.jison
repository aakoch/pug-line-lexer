/* Pug single line parser */

/* lexical grammar */
%lex

%options case-insensitive

// ID          [A-Z-]+"?"?
// NUM         ([1-9][0-9]+|[0-9])
space  [ \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]
tag         (a|abbr|acronym|address|applet|area|article|aside|audio|b|base|basefont|bdi|bdo|bgsound|big|blink|blockquote|body|br|button|canvas|caption|center|cite|code|col|colgroup|content|data|datalist|dd|del|details|dfn|dialog|dir|div|dl|dt|em|embed|fieldset|figcaption|figure|font|foo|footer|form|frame|frameset|h1|h2|h3|h4|h5|h6|head|header|hgroup|hr|html|i|iframe|image|img|input|ins|kbd|keygen|label|legend|li|link|main|map|mark|marquee|math|menu|menuitem|meta|meter|nav|nobr|noembed|noframes|noscript|object|ol|optgroup|option|output|p|param|picture|plaintext|portal|pre|progress|q|rb|rp|rt|rtc|ruby|s|samp|section|select|shadow|slot|small|source|spacer|span|strike|strong|sub|summary|sup|svg|table|tbody|td|template|textarea|tfoot|th|thead|time|title|tr|track|tt|u|ul|var|video|wbr|xmp)\b

keyword             (append|block|case|default|doctype|each|else|extends|for|if|include|mixin|unless|when|while)\b
filter              \:[a-z0-9-]+\b

// classname               \.[a-z0-9-]+
classname               \.-?[_a-zA-Z]+[_a-zA-Z0-9-]*
tag_id                  #[a-z0-9-]+
mixin_call              \+[a-z]+\b
conditional             -?(if|else if|else)
interpolation_start     #\{
interpolation           #\{.+\}

%x TEXT
%x TEXT_START
%x AFTER_TAG_NAME
%x ATTRS_STARTED
%x ATTR_TEXT
%x MIXIN_CALL_START
%s ATTRS_END
%x CODE_START
%x UNBUF_CODE
%x MULTI_LINE_ATTRS
%x COMMENT
%x AFTER_ATTRS
%x AFTER_TEXT_TAG_NAME
%x AFTER_KEYWORD
%x NO_MORE_SPACE
%x ASSIGNMENT_VALUE
%x COND_START
%x MULTI_LINE_ATTRS_END
%x INTERPOLATION_START
%x MIXIN_PARAMS_STARTED

%%

<INITIAL>{keyword}
%{
  this.pushState('AFTER_KEYWORD');
                                          return 'KEYWORD';
%}
<INITIAL>{tag}
%{
  this.pushState('AFTER_TAG_NAME');
                                          return 'TAG';
%}
<INITIAL>('script'|'style')
%{
if (TEXT_TAGS_ALLOW_SUB_TAGS) {
  this.pushState('AFTER_TAG_NAME');
                                          return 'TAG';
}
else {
  this.pushState('AFTER_TEXT_TAG_NAME');
                                          return 'TEXT_TAG';
}
%}
<INITIAL>{tag_id}
%{
  this.pushState('AFTER_TAG_NAME');
  yytext = yytext.substring(1);
                                          return 'TAG_ID';
%}
<INITIAL>{mixin_call}
%{
  yytext = yytext.substring(1);
  this.pushState('MIXIN_CALL_START');
                                          return 'MIXIN_CALL';
%}

<INITIAL>'}'
%{
  this.pushState('AFTER_KEYWORD');
                                          return 'RCURLY';
%}

<INITIAL>{conditional}
%{
  this.pushState('COND_START');
  if (yytext.startsWith('-')) {
    yytext = yytext.substring(1);
  }
                                          return 'CONDITIONAL';
%}
<COND_START>'('
%{
  this.pushState('COND_START');
                                          return 'LPAREN';
%}
<COND_START>.+')'
%{
  this.popState();
  yytext = yytext.substring(0, yytext.length - 1)
                                          return ['RPAREN', 'CONDITION'];
%}

// for lines that start with a )
<MULTI_LINE_ATTRS_END>')'
%{
  debug('<MULTI_LINE_ATTRS_END>\')\'')
  this.popState();
                                          return 'MULTI_LINE_ATTRS_END';
%}

// <INITIAL>'-'{space}*(?:\w+)
// %{
//   debug('10 this.matches=', this.matches)
//   debug('10 this.matches.length=', this.matches.length)
//   debug('10 yytext=', yytext)
//   this.pushState('AFTER_TAG_NAME');
//   yytext = yytext.substring(1);
//   if (yytext.startsWith(' ')) {
//     yytext = yytext.substring(1);
//   }
//                                           return 'CODE';
// %}
<INITIAL>'-'
%{
  this.pushState('CODE_START');
                                          return 'CODE_START';
%}
<INITIAL>{classname}
%{
  // debug('<INITIAL>{classname}')
  this.pushState('AFTER_TAG_NAME');
  yytext = yytext.substring(1);
                                          return 'CLASSNAME';
%}
<INITIAL>"//"             
%{
  this.pushState('TEXT');
                                          return 'COMMENT';
%}
<INITIAL>'<'[A-Z_]+'>'
%{
  this.pushState(yytext.substring(1, yytext.length - 1));
%}
<INITIAL,TEXT>"| "
%{
  this.pushState('TEXT');
                                           return 'PIPE';
%}
<INITIAL>"|."
%{
  this.pushState('TEXT');
  this.unput('.');
%}
<INITIAL>'|'<<EOF>>
%{
  this.pushState('TEXT');
                                           return 'SPACE'; // only because it is an empty object 
%}

<INITIAL>{interpolation}
%{
  debug('{interpolation}')
  this.pushState('AFTER_TAG_NAME');
                                          return 'INTERPOLATION';
%}

<INITIAL>{interpolation_start}
%{
  debug('{interpolation_start}')
  this.pushState('INTERPOLATION_START');
                                          return 'INTERPOLATION_START';
%}

<AFTER_TAG_NAME>'= '
%{
  this.popState();
  this.pushState('ASSIGNMENT_VALUE');
                                          return 'ASSIGNMENT';
%}
<AFTER_TAG_NAME,AFTER_ATTRS>': '
%{
  this.popState();
                                          return 'NESTED_TAG_START';
%}

<AFTER_KEYWORD>{filter}
%{
  yytext = yytext.substring(1)
                                          return 'FILTER';
%}
<AFTER_TAG_NAME,AFTER_TEXT_TAG_NAME>'('             
%{
  this.pushState('ATTRS_STARTED');
                                          return 'LPAREN';
%}
<ATTRS_END,MIXIN_PARAMS_END>')'
%{      
                                          return 'RPAREN';
%}
// The addition of ATTRS_END is for the edge case of allowing a classname to immediately follow the attributes: a.class(some=attr).class
<INITIAL,ATTRS_END>{classname}
%{
  debug('<INITIAL>{classname}')
  this.pushState('AFTER_TAG_NAME');
  yytext = yytext.substring(1);
                                          return 'CLASSNAME';
%}
<ATTRS_STARTED>(.+)(')')
%{
  this.popState()
  this.pushState('ATTRS_END')
  debug('20 this.matches=', this.matches)
  debug('20 this.matches.length=', this.matches.length)
  debug('20 yytext=', yytext)
  try {
    this.unput(')');
    if (this.matches.length > 1) {    
      yytext = this.matches[1]
      // if (yytext.startsWith(')')) {
      //   yytext = yytext.substring(1)
      // }
    }
  }
  catch (e) {
    console.error(e)
  }
  lparenOpen = false
  debug('20 yytext=', yytext)
                                          return 'ATTR_TEXT';
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
<INITIAL>{space}{2,}
%{
  debug('{space}{2,}');
                                                              return 'SPACE';
%}

<AFTER_TAG_NAME,AFTER_KEYWORD,AFTER_TEXT_TAG_NAME>{space}{space}
%{
  this.pushState('TEXT');
  debug('space space');
  this.unput(' ');
                                                              return 'SPACE';
%}

// This is a bit to unwind. I added this to counter the affect of allowing a classname directly after the attributes.
// If I don't allow that, this isn't needed. 
<AFTER_TAG_NAME,AFTER_KEYWORD,AFTER_TEXT_TAG_NAME>{space}{classname}
%{
  this.pushState('ATTRS_END');
  yytext = yytext.substring(1);
                                          return 'TEXT';
%}

<AFTER_TAG_NAME,AFTER_KEYWORD,AFTER_TEXT_TAG_NAME>{space}
%{
  this.pushState('ATTRS_END');
  debug('<AFTER_TAG_NAME,AFTER_KEYWORD,AFTER_TEXT_TAG_NAME>{space}');
                                                              return 'SPACE';
%}


<ATTRS_END>{space}
%{
  this.pushState('TEXT');
  debug('<ATTRS_END>{space}');
                                                              return 'SPACE';
%}
<AFTER_TAG_NAME,AFTER_TEXT_TAG_NAME,ATTRS_END>'.'\s*<<EOF>>             return 'DOT_END';
<AFTER_TAG_NAME,AFTER_KEYWORD,AFTER_TEXT_TAG_NAME,NO_MORE_SPACE>.+
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
<INITIAL,ATTRS_END>'.'\s*<<EOF>>
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
  // yytext = yytext.substring(1)
  debug('6 yytext=', yytext)
                                          return 'TEXT';
%}

<CODE_START,UNBUF_CODE>{space}
%{
  debug('<CODE_START,UNBUF_CODE>{space}');
                                          return 'SPACE';
%}
<CODE_START,UNBUF_CODE>.+
%{
                                          return 'CODE';
%}

<MIXIN_CALL_START>'('             
%{
  this.popState();
  this.pushState('MIXIN_PARAMS_STARTED');
                                          return 'LPAREN';
%}
<MIXIN_CALL_START>{space}$             
%{
  this.popState();
%}

<ONLY_FOR_SYNTAX_COLORING>'))'             ;

// removed "[^{space}]" from the beginning because of COMMENT
<TEXT>.+
%{
  debug('80 yytext=', yytext)
                                          return 'TEXT';
%}

<MULTI_LINE_ATTRS>')'                     return 'ATTR_TEXT_END';
<MULTI_LINE_ATTRS>.+                      return 'ATTR_TEXT';



<MIXIN_PARAMS_STARTED>(.+)(')')
%{
  this.popState()
  this.pushState('MIXIN_PARAMS_END')
  debug('120 this.matches=', this.matches)
  debug('120 this.matches.length=', this.matches.length)
  debug('120 yytext=', yytext)
  try {
    this.unput(')');
    if (this.matches.length > 1) {    
      yytext = this.matches[1]
      // if (yytext.startsWith(')')) {
      //   yytext = yytext.substring(1)
      // }
    }
  }
  catch (e) {
    console.error(e)
  }
  lparenOpen = false
  debug('120 yytext=', yytext)
                                          return 'MIXIN_PARAMS';
%}
// <MIXIN_PARAMS_STARTED>(.+)')'\s*<<EOF>>
// %{
//   this.popState()
//   debug('130 this.matches=', this.matches)
//   debug('130 this.matches.length=', this.matches.length)
//   debug('130 yytext=', yytext)
//   try {
//     if (this.matches.length > 1) {    
//       yytext = this.matches[1]
//     }
//   }
//   catch (e) {
//     console.error(e)
//   }
//   lparenOpen = false
//   debug('130 yytext=', yytext)
//                                           return ['RPAREN', 'MIXIN_PARAMS'];
// %}
// <MIXIN_PARAMS_STARTED>(.+)')'\.?\s*(.+)<<EOF>>
// %{
//   this.popState()
//   this.pushState('MIXIN_PARAMS_END')
//   debug('140 this.matches=', this.matches)
//   this.unput(this.matches[2])
//   yytext = yytext.substring(0, yytext.indexOf(this.matches[1]) + this.matches[1].length);
//   debug('140 yytext=', yytext)
//   lparenOpen = false
//                                           return ['RPAREN', 'MIXIN_PARAMS'];
// %}

// // Can mixin parameters span lines?
// <MIXIN_PARAMS_STARTED>(.+)\.?\s*<<EOF>>
// %{
//   this.popState()
//   debug('150 this.matches=', this.matches)
//   debug('150 this.matches.length=', this.matches.length)
//   debug('150 yytext=', yytext)
//   try {
//     if (this.matches.length > 1) {    
//       yytext = this.matches[1]
//     }
//   }
//   catch (e) {
//     console.error(e)
//   }
//   debug('150 yytext=', yytext)
//                                           return 'MIXIN_PARAMS_CONT';
// %}

/lex

%ebnf
%options token-stack 

%% 

/* language grammar */

start
  : EOF
  | line EOF
  | MULTI_LINE_ATTRS_END EOF
  {
    $$ = { state: 'MULTI_LINE_ATTRS_END' }
  }
  ;

line
  : line_start
  // if I change TEXT to line_end, I get a bunch of conflicts. I don't want to deal with them now
  | line_start TEXT
  {
    $$ = merge($line_start, { type: 'text', val: $TEXT })
  }
  | line_start CODE
  {
    $$ = merge($line_start, { type: 'code', val: $CODE })
  }
  | line_start line_splitter line_end
  {
    $$ = merge($line_start, [$line_splitter, $line_end])
  }
  | line_start NESTED_TAG_START line
  {
    $$ = merge($line_start, { state: 'NESTED', children: [$line] })
  }
  | ATTR_TEXT_END
  {
    $$ = { type: 'multiline_attrs_end' }
  }
  ;

line_start
  : first_token
  | first_token tag_part
  {
    debug('line_start: first_token tag_part')
    $$ = merge($first_token, $tag_part)
  }
  | first_token attrs
  {
    debug('line_start: first_token attrs')
    $$ = merge($first_token, $attrs)
  }
  | first_token LPAREN ATTR_TEXT_CONT?
  {
    debug('line_start: first_token LPAREN ATTR_TEXT_CONT?')
    $$ = merge($first_token, { type: 'tag_with_multiline_attrs', state: 'MULTI_LINE_ATTRS' })
    if ($3) {
      $$ = merge($first_token, { type: 'tag_with_multiline_attrs', attrs: [$3] })
    }
  }
  | first_token tag_part LPAREN ATTR_TEXT_CONT
  {
    debug('line_start: first_token tag_part LPAREN ATTR_TEXT_CONT')
    $$ = merge($first_token, [$tag_part, $ATTR_TEXT_CONT])
  }
  | first_token tag_part attrs
  {
    debug('line_start: first_token tag_part attrs')
    $$ = merge($first_token, [$tag_part, $attrs])
  }
  // Rule for the edgecase a.foo(class='bar').baz
  | first_token tag_part attrs CLASSNAME
  {
    $$ = merge($first_token, [$tag_part, $attrs, { classes: $CLASSNAME }])
  }
  | ATTR_TEXT
  {
    debug('line_start: ATTR_TEXT')
    $$ = { type: 'attrs_cont', attrs: [$ATTR_TEXT] }
  }
  | first_token LPAREN MIXIN_PARAMS RPAREN
  {
    $$ = merge($first_token, { params: $MIXIN_PARAMS })
  }
  ;

first_token
  : TAG
  {
    $$ = { name: $TAG, type: 'tag' }
  }
  | TEXT_TAG
  {
    $$ = { name: $TEXT_TAG, type: 'tag', state: 'TEXT_START' }
  }
  | CLASSNAME
  {
    $$ = { type: 'tag', classes: [$1] }
  }
  | TAG_ID
  {
    $$ = { type: 'tag', id: $TAG_ID }
  }
  | TEXT
  {
    $$ = { type: 'text', val: $TEXT }
  }
  | COMMENT
  {
    $$ = { type: 'comment', state: 'TEXT_START' }
  }
  | CODE_START
  {
    debug('CODE_START')
    $$ = { type: 'code', state: 'CODE_START' }
  }
  | CODE
  {
    $$ = { type: 'code', val: $CODE }
  }
  | MIXIN_CALL
  {
    debug('MIXIN_CALL=', $1)
    $$ = { type: 'mixin_call', name: $1 }
  }
  | KEYWORD
  {
    $$ = { type: $KEYWORD }
  }
  | PIPE
  {
    $$ = { type: 'text' }
  }
  | RCURLY
  {
    $$ = { type: 'block_end' }
  }
  | DOT_END
  {
    debug('line: DOT_END')
    $$ = { state: 'TEXT_START' }
  }
  | SPACE
  {
    $$ = {type: 'empty'}
  }
  | CONDITIONAL
  {
    $$ = { type: 'conditional', name: $CONDITIONAL }
  }
  | INTERPOLATION
  {
    $$ = { type: 'interpolation', name: $INTERPOLATION }
  }
  | INTERPOLATION_START
  {
    $$ = { type: 'interpolation_start', state: 'INTERPOLATION_START' }
  }
  ;

tag_part
  : TAG_ID
  {
    $$ = { id: $TAG_ID }
  }
  | TAG_ID classnames
  {
    $$ = merge({ id: $TAG_ID }, $classnames)
  }
  | classnames
  | classnames TAG_ID
  {
    $$ = merge({ id: $TAG_ID }, $classnames)
  }
  | FILTER
  {
    $$ = { filter: $FILTER }
  }
  ;

attrs
  : LPAREN ATTR_TEXT RPAREN
  {
    debug('Calling parseAttrs with ', $2)
    const attrs = parseAttrs.parse($2)
    debug('attrs=', attrs)
    $$ = {}
    attrs.forEach(attr => {
      // if (attr.hasOwnProperty('key') && attr.key == 'class' && !attr.assignment) {
      //   $$ = merge($$, { classes: attr.val.split(' ') } )
      //   delete attr.class
      // }
      // else if (attr.hasOwnProperty('id')) {
      //   $$ = merge($$, { id: attr.id } )
      //   delete attr.id
      // }
      // else 
      if (!_.isEmpty(attr)) {
        $$ = merge($$, { attrs: [attr] })
      }
    })
  }
  | LPAREN CONDITION RPAREN
  {
    debug('attrs: LPAREN CONDITION RPAREN')
    $$ = { condition: $2 }
  }
  ;

classnames
  : CLASSNAME+
  {
    $$ = { type: 'tag', classes: $1 }
  }
  ;

line_end
  : 
  {
    debug('line_end: <blank>')
  }
  | DOT_END
  {
    debug('line_end: DOT_END')
    $$ = { state: 'TEXT_START' }
  }
  | ASSIGNMENT_VALUE
  {
    $$ = { assignment_val: $ASSIGNMENT_VALUE }
  }
  | ATTR_TEXT_CONT
  {
    debug('line_end: ATTR_TEXT_CONT')
    $$ = { attrscont: [$1] }
  }
  | TEXT
  {
    $$ = { type: 'text', val: $TEXT }
  }
  | CODE
  {
    $$ = { type: 'code', val: $CODE }
  }
  | RPAREN
  {
    $$ = { type: 'text', val: $RPAREN }
  }
  ;

line_splitter
  : SPACE
  {
    debug('line_splitter: SPACE')
    $$ = undefined
  }
  | ASSIGNMENT
  {
    $$ = { assignment: true }
  }
  | DOT_END
  {
    debug('line_splitter: DOT_END')
    $$ = { state: 'TEXT_START' }
  }
  | RPAREN
  ;

%% 
__module_imports__

const TEXT_TAGS_ALLOW_SUB_TAGS = true

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
  else if (type1 == 'tag' && type2 == 'tag_with_multiline_attrs') {
    return type2
  }
  else if (type1 == 'tag_with_multiline_attrs' && type2 == 'tag') {
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


// commenting this all out for now while I test pug-attr {
// test(`a(class=['foo', 'bar', 'baz'])`, { type: 'tag', name: 'a', classes: ['foo', 'bar', 'baz'] })
// test(`a.foo(class='bar').baz`, { type: 'tag', name: 'a', classes: ['foo', 'bar', 'baz'] })
// test(`a.foo-bar_baz`, { type: 'tag', name: 'a', classes: ['foo-bar_baz'] })
// test(`a(class={foo: true, bar: false, baz: true})`, { type: 'tag', name: 'a', classes: ['foo', 'baz'] })

// test('span(v-for="item in items" :key="item.id" :value="item.name")', {
//   attrs: [
//     {
//       key: 'v-for',
//       val: 'item in items'
//     },
//     {
//       key: ':key',
//       val: 'item.id'
//     },
//     {
//       key: ':value',
//       val: 'item.name'
//     }
//   ],
//   name: 'span',
//   type: 'tag'
// })
// // test('p A sentence with a #[strong strongly worded phrase] that cannot be #[em ignored].', {})
// // test('p <strong>strongly worded phrase</strong> that cannot be <em>ignored</em>', {})

// test('span &boxv;', { type: 'tag', name: 'span', val: '&boxv;'})
// test('include:markdown-it article.md', { type: 'include', val: 'article.md', filter: 'markdown-it' })
// test('span.hljs-section )', { type: 'tag', name: 'span', classes: ['hljs-section'], val: ')'})
// test("#{'foo'}(bar='baz') /", {
//   attrs: [
//     {
//       key: 'bar',
//       val: 'baz'
//     }
//   ],
//   name: "#{'foo'}",
//   type: 'interpolation',
//   val: '/'
// })

// test('li= item', {
//   assignment: true,
//   assignment_val: 'item',
//   name: 'li',
//   type: 'tag'
// })
// test('<MULTI_LINE_ATTRS_END>)', {
//   state: 'MULTI_LINE_ATTRS_END'
// })
// // test('a(:link="goHere" value="static" :my-value="dynamic" @click="onClick()" :another="more") Click Me!', {})

// test('-var ajax = true', {type: 'code', val: 'var ajax = true', state: 'CODE_START' })
// test('-if( ajax )', {type: 'conditional', name: 'if', condition: ' ajax '})
// test('span.font-monospace .htmlnanorc', {
//   type: 'tag', name: 'span', classes: ['font-monospace'], val: '.htmlnanorc'})

// test('.container.post#post-20210905', {
//   type: 'tag',
//   id: 'post-20210905',
//   classes: ['container', 'post']
// })

// test('<UNBUF_CODE>var i', {
//   type: 'code',
//   val: 'var i'
// })

// test('} else {', {
//   type: 'block_end',
//   val: 'else {'
// })

// test("+project('Moddable Two (2) Case', 'Needing Documentation ', ['print'])", { type: 'mixin_call', name: 'project', params: 
//     "'Moddable Two (2) Case', 'Needing Documentation ', ['print']"
//   })

// test('code(class="language-scss").', { name: 'code', type: 'tag', classes: [ 'language-scss' ], state: 'TEXT_START' })

// test('p: a(href="https://www.thingiverse.com/thing:4578862") Thingiverse', {
//   children: [
//     {
//       name: 'a',
//       attrs: [{key: 'href', val: 'https://www.thingiverse.com/thing:4578862'}],
//       type: 'tag',
//       val: 'Thingiverse'
//     }
//   ],
//   name: 'p',
//   state: 'NESTED',
//   type: 'tag'
// })

// test('.project(class= (tags || []).map((tag) => tag.replaceAll(" ", "_")).join(" "))', {
//   classes: [ 'project' ],
//   attrs: [
//     {
//       assignment: true,
//       key: 'class',
//       val: '(tags || []).map((tag) => tag.replaceAll(" ", "_")).join(" ")'
//     }
//   ],
//   type: 'tag'
// })

// test('.status-wrapper Status:', { classes: [ 'status-wrapper' ], type: 'tag', val: 'Status:' })

// test('+sensitive ', {
//   name: 'sensitive',
//   type: 'mixin_call'
// })

// test('a(href=url)= url', {
//   assignment: true,
//   assignment_val: 'url',
//   attrs: [
//     { key: 'href', assignment: true, val: 'url' }
//   ],
//   name: 'a',
//   type: 'tag'
// })

// // I'm not supporting this right now
// // test('a(href=\'/user/\' + id, class=\'button\')', {
// //   attrs: [
// //     "href='/user/' + id, class='button'"
// //   ],
// //   name: 'a',
// //   type: 'tag'
// // })

// test('- function answer() { return 42; }', {
//   state: 'CODE_START',
//   type: 'code',
//   val: 'function answer() { return 42; }'
// })

// // I'm not supporting this right now
// // test('a(href=\'/user/\' + id, class=\'button\')', {
// //   attrs: [
// //     "href='/user/' + id, class='button'"
// //   ],
// //   name: 'a',
// //   type: 'tag'
// // })
// // test('a(href  =  \'/user/\' + id, class  =  \'button\')', {
// //   attrs: [
// //     "href  =  '/user/' + id, class  =  'button'"
// //   ],
// //   name: 'a',
// //   type: 'tag'
// // })

// test('a(class = [\'class1\', \'class2\'])', {
//   attrs: [
//     "class = ['class1', 'class2']"
//   ],
//   name: 'a',
//   type: 'tag'
// })
// test('a.tag-class(class = [\'class1\', \'class2\'])', {
//   attrs: [
//     "class = ['class1', 'class2']"
//   ],
//   classes: [
//     'tag-class'
//   ],
//   name: 'a',
//   type: 'tag'
// })
// test('a(href=\'/user/\' + id class=\'button\')', {
//   attrs: [
//     "href='/user/' + id class='button'"
//   ],
//   name: 'a',
//   type: 'tag'
// })
// test('a(href  =  \'/user/\' + id class  =  \'button\')', {
//   attrs: [
//     "href  =  '/user/' + id class  =  'button'"
//   ],
//   name: 'a',
//   type: 'tag'
// }
// )
// test('meta(key=\'answer\' value=answer())', {
//   attrs: [
//     "key='answer' value=answer()"
//   ],
//   name: 'meta',
//   type: 'tag'
// })

// test('div(id=id)&attributes({foo: \'bar\'})', {
//   attrs: [
//     "id=id)&attributes({foo: 'bar'}"
//   ],
//   name: 'div',
//   type: 'tag'
// })
// test('div(foo=null bar=bar)&attributes({baz: \'baz\'})', {
//   attrs: [
//     "foo=null bar=bar)&attributes({baz: 'baz'}"
//   ],
//   name: 'div',
//   type: 'tag'
// })

// test('foo(abc', {type: 'tag_with_multiline_attrs', name: 'foo', attrs: ['abc'], state: 'MULTI_LINE_ATTRS'})
// test('<MULTI_LINE_ATTRS>,def)', { type: 'attrs_cont', attrs: [',def)'] })

// test('span(', {type: 'tag_with_multiline_attrs', name: 'span', state: 'MULTI_LINE_ATTRS'})
// test('<MULTI_LINE_ATTRS>v-for="item in items"', {
//   type: 'attrs_cont',
//   attrs: [
//     'v-for="item in items"'
//   ]
// })
// test('<MULTI_LINE_ATTRS>:key="item.id"', {
//   type: 'attrs_cont',
//   attrs: [
//     ':key="item.id"'
//   ]
// })
// test('<MULTI_LINE_ATTRS>:value="item.name"', {
//   type: 'attrs_cont',
//   attrs: [
//     ':value="item.name"'
//   ]
// })
// test('<MULTI_LINE_ATTRS>)', {type: 'multiline_attrs_end'})
// test('a(:link="goHere" value="static" :my-value="dynamic" @click="onClick()" :another="more") Click Me!', {
//   type: 'attrs_cont',
//   attrs: [
//     ':link="goHere" value="static" :my-value="dynamic" @click="onClick()" :another="more"'
//   ],
//   name: 'a',
//   type: 'tag',
//   val: 'Click Me!'
// })

// test('foo(data-user=user)', {
//   attrs: [
//     'data-user=user'
//   ],
//   name: 'foo',
//   type: 'tag'
// })
// test('foo(data-items=[1,2,3])', {
//   attrs: [
//     'data-items=[1,2,3]'
//   ],
//   name: 'foo',
//   type: 'tag'
// })
// test('foo(data-username=\'tobi\')', {
//   attrs: [
//     "data-username='tobi'"
//   ],
//   name: 'foo',
//   type: 'tag'
// })
// test('foo(data-escaped={message: "Let\'s rock!"})', {
//   attrs: [
//     `data-escaped={message: "Let's rock!"}`
//   ],
//   name: 'foo',
//   type: 'tag'
// })
// test('foo(data-ampersand={message: "a quote: &quot; this & that"})', {
//   attrs: [
//     'data-ampersand={message: "a quote: &quot; this & that"}'
//   ],
//   name: 'foo',
//   type: 'tag'
// })
// test('foo(data-epoc=new Date(0))', {
//   attrs: [
//     'data-epoc=new Date(0)'
//   ],
//   name: 'foo',
//   type: 'tag'
// })


// test('+sensitive', {
//   name: 'sensitive',
//   type: 'mixin_call'
// })

// test('html', { type: 'tag', name: 'html' })
// test('html ', { type: 'tag', name: 'html' }, false)

// // test("doctype html", { type: 'doctype', val: 'html' })
// test('doctype html', { type: 'doctype', val: 'html' })

// test("html(lang='en-US')", {"type":"tag","name":"html","attrs":["lang='en-US'"]})

// // test("include something", { type: 'include_directive', params: 'something' })
// test('include something', { type: 'include', val: 'something' })

// // test("block here", { type: 'directive', name: 'block', params: 'here' })
// test("block here", { type: 'block', val: 'here' })

// test("head", { type: 'tag', name: 'head' })
// test("meta(charset='UTF-8')", {"type":"tag","name":"meta","attrs":["charset='UTF-8'"]})
// test("meta(name='viewport' content='width=device-width')", { type: 'tag', name: 'meta', attrs: ["name='viewport' content='width=device-width'"]})
// test("title", {"type":"tag","name":"title"})
// test("| White-space and character 160 | Adam Koch ", {"type":"text","val":"White-space and character 160 | Adam Koch "})
// if (!TEXT_TAGS_ALLOW_SUB_TAGS)
//   test("script(async src=\"https://www.googletagmanager.com/gtag/js?id=UA-452464-5\")", {"type":"tag","name":"script","attrs":["async src=\"https://www.googletagmanager.com/gtag/js?id=UA-452464-5\""], state: 'TEXT_START'})
// test("script.  ", {"type":"tag","name":"script","state":"TEXT_START"})
// test("<TEXT>window.dataLayer = window.dataLayer || [];   ", { type: 'text', val: 'window.dataLayer = window.dataLayer || [];   ' })
// test("<TEXT>gtag('config', 'UA-452464-5');", {"type":"text","val":"gtag('config', 'UA-452464-5');"})
// test("", "")
// if (!TEXT_TAGS_ALLOW_SUB_TAGS)
//   test("script test", {"type":"tag","name":"script","state":"TEXT_START","val":"test"})
// test(".classname", { type: 'tag', classes: ['classname'] })

// //test("// some text", { type: 'comment', state: 'TEXT_START' })
// test("// some text", { type: 'comment', state: 'TEXT_START', val: ' some text' })

// // test("// ", { type: 'comment', state: 'TEXT_START' })
// test("// ", { type: 'comment', val: ' ', state: 'TEXT_START' })

// test("//", { type: 'comment', state: 'TEXT_START' })


// test('a.url.fn.n(href=\'https://wordpress.adamkoch.com/author/admin/\' title=\'View all posts by Adam\' rel=\'author\') Adam',  {
//   type: 'tag',
//   name: 'a',
//   classes: [ 'url', 'fn', 'n' ],
//   val: 'Adam',
//   attrs: ["href='https://wordpress.adamkoch.com/author/admin/' title='View all posts by Adam' rel='author'"]
// })
// test('style(id=\'wp-block-library-inline-css\' type=\'text/css\').', {"type":"tag","name":"style","attrs":["id='wp-block-library-inline-css' type='text/css'"],"state":"TEXT_START"})
// test('| #start-resizable-editor-section{figcaption{color:hsla(0,0%,100%,.65)}', {"type":"text","val":"#start-resizable-editor-section{figcaption{color:hsla(0,0%,100%,.65)}"})
// test('body.post-template-default.single.single-post.postid-1620.single-format-standard.wp-embed-responsive.single-author.singular.two-column.right-sidebar', {"type":"tag","name":"body","classes":["post-template-default","single","single-post","postid-1620","single-format-standard","wp-embed-responsive","single-author","singular","two-column","right-sidebar"]})
// test('#page.hfeed', {"type":"tag","id":"page","classes":["hfeed"]})
// test('header#branding(role=\'banner\')', {"type":"tag","name":"header","id":"branding","attrs":["role='banner'"]})
// test('h1#site-title', {type: 'tag', name: 'h1', id: 'site-title'})
// test('a(href=\'https://www.adamkoch.com/\' rel=\'home\') Adam Koch', {type: 'tag', name: 'a', attrs: ['href=\'https://www.adamkoch.com/\' rel=\'home\''], val: 'Adam Koch'})
// test('h2#site-description Software Developer and Clean Code Advocate', {type: 'tag', name: 'h2', id: 'site-description', val: 'Software Developer and Clean Code Advocate' })
// test('h3.assistive-text Main menu', {type: 'tag', name: 'h3', classes: ['assistive-text'], val: 'Main menu' })
// test('ul#menu-header.menu', {type: 'tag', name: 'ul', id: 'menu-header', classes: ['menu']})
// test('a(href=\'https://wordpress.adamkoch.com/posts/\') Posts', {type: 'tag', name: 'a', attrs: ['href=\'https://wordpress.adamkoch.com/posts/\''], val: 'Posts'})
// test('span.sep  by', {type:'tag', name: 'span', classes: ['sep'], val: ' by' })
// test('style.', {"type":"tag","name":"style","state":"TEXT_START"})
// test('p I came across a problem in Internet Explorer (it wasn\'t a problem with Firefox) when I was trying to compare two strings. To me, one string looked to have an extra space in the front. No problem, I\'ll just call the', {
//   type: 'tag',
//   name: 'p',
//   val: "I came across a problem in Internet Explorer (it wasn't a problem with Firefox) when I was trying to compare two strings. To me, one string looked to have an extra space in the front. No problem, I'll just call the"
// })
// test('.sd-content', { type: 'tag', classes: [ 'sd-content' ] })
// test('th  Browser', { type: 'tag', name: 'th', val: ' Browser' })
// test('.sharedaddy.sd-sharing-enabled', {"type":"tag","classes":['sharedaddy', 'sd-sharing-enabled']})
// test('time(datetime=\'2009-07-28T01:24:04-06:00\') 2009-07-28 at 1:24 AM', { type: 'tag', name: 'time', attrs: ['datetime=\'2009-07-28T01:24:04-06:00\''], val: '2009-07-28 at 1:24 AM'} )
// test('- var title = \'Fade Out On MouseOver Demo\'', { type: 'code', val: 'var title = \'Fade Out On MouseOver Demo\'', state: 'CODE_START' })
// test('<TEXT>}).join(\' \')', { type: 'text', val: "}).join(' ')" })
// test('  ', {
//   type: 'empty'
// })
// test('#content(role=\'main\')', { type: 'tag', id: 'content', attrs: ['role=\'main\'']})
// test('pre: code(class="language-scss").', { type: 'tag', name: 'pre', children: [ { type: 'tag', name: 'code', attrs: ['class="language-scss"'], state: 'TEXT_START'} ], state: 'NESTED'})

// test('mixin sensitive()', { type: 'mixin', val: 'sensitive()' })
// test('extends ../templates/blogpost', {
//   type: 'extends',
//   val: '../templates/blogpost'
// })
// test('append head', {
//   type: 'append',
//   val: 'head'
// })
// test('p Maecenas sed lorem accumsan, luctus eros eu, tempor dolor. Vestibulum lorem est, bibendum vel vulputate eget, vehicula eu elit. Donec interdum cursus felis, vitae posuere libero. Cras et lobortis velit. Pellentesque in imperdiet justo. Suspendisse dolor mi, aliquet at luctus a, suscipit quis lectus. Etiam dapibus venenatis sem, quis aliquam nisl volutpat vel. Aenean scelerisque dapibus sodales. Vestibulum in pretium diam. Quisque et urna orci.', {type: 'tag', name: 'p', val: 'Maecenas sed lorem accumsan, luctus eros eu, tempor dolor. Vestibulum lorem est, bibendum vel vulputate eget, vehicula eu elit. Donec interdum cursus felis, vitae posuere libero. Cras et lobortis velit. Pellentesque in imperdiet justo. Suspendisse dolor mi, aliquet at luctus a, suscipit quis lectus. Etiam dapibus venenatis sem, quis aliquam nisl volutpat vel. Aenean scelerisque dapibus sodales. Vestibulum in pretium diam. Quisque et urna orci.' })

// test('+project(\'Images\', \'On going\')', {
//   attrs: [
//     "'Images', 'On going'"
//   ],
//   type: 'mixin_call',
//   name: 'project'
// })
// test("+project('Moddable Two (2) Case', 'Needing Documentation ', ['print'])", {
//   attrs: [
//     "'Moddable Two (2) Case', 'Needing Documentation ', ['print']"
//   ],
//   type: 'mixin_call',
//   name: 'project'
// })
// test('| . The only "gotcha" was I originally had "www.adamkoch.com" as the A record instead of "adamkoch.com". Not a big deal and easy to rectify.', { type: 'text', val: '. The only "gotcha" was I originally had "www.adamkoch.com" as the A record instead of "adamkoch.com". Not a big deal and easy to rectify.' })
// test('<TEXT>| #start-resizable-editor-section{display:none}.wp-block-audio figcaption{color:#555;font-size:13px;', {"type":"text","val":"#start-resizable-editor-section{display:none}.wp-block-audio figcaption{color:#555;font-size:13px;" })

// // test('- ', { type: 'code', val: ' ', state: 'UNBUF_CODE_START' })
// test('- ', { type: 'code', state: 'CODE_START' })

// test('mixin project(title)', {
//   type: 'mixin',
//   val: 'project(title)'
// })
// test('+code(\'Pretty-print any JSON file\') jq \'.\' package.json',
// {
//   attrs: [
//     "'Pretty-print any JSON file'"
//   ],
//   name: 'code',
//   type: 'mixin_call',
//   val: "jq '.' package.json"
// } )
// test('// comment', {
//   state: 'TEXT_START',
//   type: 'comment',
//   val: ' comment'
// })
// test('meta(property=\'og:description\' content=\'I came across a problem in Internet Explorer (it wasn\\\'t a problem with Firefox) when I...\')',  {
//   type: 'tag',
//   name: 'meta',
//   attrs: ["property=\'og:description' content='I came across a problem in Internet Explorer (it wasn\\'t a problem with Firefox) when I...'"]
// })

// test('-', {
//   type: 'code',
//   state: 'CODE_START'
// })

// // test(' -', {
// //   state: 'UNBUF_CODE_START',
// //   type: 'code',
// //   val: ''
// // })

// test('<UNBUF_CODE>var i', {
//   type: 'code',
//   val: 'var i'
// })

// test("link(rel='alternate' type='application/rss+xml' title='Adam Koch &raquo; White-space and character 160 Comments Feed' href='https://wordpress.adamkoch.com/2009/07/25/white-space-and-character-160/feed/')", {
//   attrs: [
//     "rel='alternate' type='application/rss+xml' title='Adam Koch &raquo; White-space and character 160 Comments Feed' href='https://wordpress.adamkoch.com/2009/07/25/white-space-and-character-160/feed/'"
//   ],
//   name: 'link',
//   type: 'tag'
// })

// test('pre.', {
//   name: 'pre',
//   state: 'TEXT_START',
//   type: 'tag'
// })

// test('pre: code.', {
//   children: [
//     {
//       name: 'code',
//       state: 'TEXT_START',
//       type: 'tag'
//     }
//   ],
//   name: 'pre',
//   state: 'NESTED',
//   type: 'tag'
// })

// test('|. The only "gotcha" was I originally had "www.adamkoch.com" as the A record instead of "adamkoch.com". Not a big deal and easy to rectify.', { type: 'text', val: '. The only "gotcha" was I originally had "www.adamkoch.com" as the A record instead of "adamkoch.com". Not a big deal and easy to rectify.' })

// test('.rule: p.', {
//   children: [
//     {
//       name: 'p',
//       type: 'tag',
//       state: 'TEXT_START'
//     }
//   ],
//   classes: ['rule'],
//   state: 'NESTED',
//   type: 'tag'
// })
// test('.rule.unratified: p.', {
//   children: [
//     {
//       name: 'p',
//       type: 'tag',
//       state: 'TEXT_START'
//     }
//   ],
//   classes: ['rule', 'unratified'],
//   state: 'NESTED',
//   type: 'tag'
// })

// test("style(id='wp-block-library-inline-css' type='text/css'). ", {
//   attrs: [
//     "id='wp-block-library-inline-css' type='text/css'"
//   ],
//   name: 'style',
//   state: 'TEXT_START',
//   type: 'tag'
// })

// test('|', {
//   type: 'empty'
// })
// test('.', { state: 'TEXT_START' })

// try {
//   test("tag", { type: 'unknown', name: 'tag' })
// throw AssertionError('Expected exception')
// } catch (e) {}
// }

};

