/* Pug single line parser */

/* lexical grammar */
%lex

%options case-insensitive

// ID          [A-Z-]+"?"?
// NUM         ([1-9][0-9]+|[0-9])
space  [ \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]
tag         (a|abbr|acronym|address|applet|area|article|aside|audio|b|base|basefont|bdi|bdo|bgsound|big|blink|blockquote|body|br|button|canvas|caption|center|cite|code|col|colgroup|content|data|datalist|dd|del|details|dfn|dialog|dir|div|dl|dt|em|embed|fb|fieldset|figcaption|figure|font|foo|footer|form|frame|frameset|h1|h2|h3|h4|h5|h6|head|header|hgroup|hr|html|i|iframe|image|img|input|ins|kbd|keygen|label|legend|li|link|main|map|mark|marquee|math|menu|menuitem|meta|meter|nav|nobr|noembed|noframes|noscript|object|ol|optgroup|option|output|p|param|picture|plaintext|portal|pre|progress|q|rb|rp|rt|rtc|ruby|s|samp|section|select|shadow|slot|small|source|spacer|span|strike|strong|sub|summary|sup|svg|table|tbody|td|template|textarea|tfoot|th|thead|time|title|tr|track|tt|u|ul|var|video|wbr|xmp)\b

keyword             (append|block|case|default|doctype|each|else|extends|for|if|include|mixin|prepend|unless|when|while)\b
filter              \:[a-z0-9-]+\b

// classname               \.[a-z0-9-]+
classname               \.-?[_a-zA-Z]+[_a-zA-Z0-9-]*
classname_relaxed       \.-?[_a-zA-Z0-9]+[_a-zA-Z0-9-]*
tag_id                  #[a-z0-9-]+
mixin_call              \+\s*[a-z]+\b
// conditional             -?(if|else if|else)
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
// %x MULTI_LINE_ATTRS_END
%x INTERPOLATION_START
%x MIXIN_PARAMS_STARTED
%x HTML_COMMENT_STARTED
%%

<INITIAL>'#['{tag}
%{
  ']'
                                          return 'TAG'
%}
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
  ')'
  this.pushState('COND_START');
                                          return 'LPAREN';
%}
<COND_START>.+')'
%{
  this.popState();
  yytext = yytext.substring(0, yytext.length - 1)
                                          return ['RPAREN', 'CONDITION'];
%}

// // for lines that start with a )
// <MULTI_LINE_ATTRS_END>')'
// %{
//   debug('<MULTI_LINE_ATTRS_END>\')\'')
//   this.popState();
//                                           return 'MULTI_LINE_ATTRS_END';
// %}

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
<INITIAL>'-'{space}*<<EOF>>
%{
                                          return 'UNBUF_CODE_BLOCK_START'
%}
<INITIAL,UNBUF_CODE>'-'
%{
  this.pushState('UNBUF_CODE_START');
%}
<INITIAL>{classname}
%{
  // debug('<INITIAL>{classname}')
  this.pushState('AFTER_TAG_NAME');
  yytext = yytext.substring(1);
                                          return 'CLASSNAME';
%}
<INITIAL>{classname_relaxed}
%{
  debug('<INITIAL>{classname_relaxed}')
  if (this.yy.parser.options.allowDigitToStartClassName) {
    // debug('<INITIAL>{classname}')
    this.pushState('AFTER_TAG_NAME');
    yytext = yytext.substring(1);
                                          return 'CLASSNAME';
  }
  else {
    throw new Error('Classnames starting with a digit is not allowed. Set allowDigitToStartClassName to true to allow.')
  }
%}
<INITIAL>"//"             
%{
  this.pushState('TEXT');
                                          return 'COMMENT';
%}
<INITIAL>'<'[A-Z_]+'>'
%{
  if (/<[A-Z_]+>/.test(yytext)) {
    this.pushState(yytext.substring(1, yytext.length - 1));
  }
  else {
    this.pushState('TEXT')
                                          return 'TEXT';
  }
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
  yytext = ''
                                           return 'TEXT'; // only because it is an empty object 
%}
<INITIAL,AFTER_TAG_NAME,ATTRS_END>'&attributes('[^\)]+')'
%{
  debug("'&attributes('[^\)]+')'")
                                          return 'AT_ATTRS'
%}
<INITIAL>{interpolation}
%{
  debug('{interpolation}')
  debug('this.matches=', this.matches)
  this.pushState('AFTER_TAG_NAME');
                                          return ['INTERP_END', 'INTERP_VAL', 'INTERP_START'];
%}
<INTERPOLATION>.+
%{
  // debug('<INTERPOLATION>.+')
  // debug('this.matches=', this.matches)
  // this.pushState('INTERPOLATION');
  
                                          return 'INTERP_VAL';
%}

<INITIAL>{interpolation_start}
%{
  debug('{interpolation_start}')
  debug('this.matches=', this.matches)
  this.pushState('INTERPOLATION_START');
                                          return 'INTERPOLATION_START';
%}

<INITIAL>'</'.+
%{
  this.pushState('TEXT')
                                          return 'TEXT';
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
  ')' // hack for syntax
  debug(`<AFTER_TAG_NAME,AFTER_TEXT_TAG_NAME>'('`)
  this.pushState('ATTRS_STARTED');
                                          return 'LPAREN';
%}
<ATTRS_END>')'
%{
                                          return 'RPAREN';
%}
<MIXIN_PARAMS_END>')'
%{
  // this.popState() // for inline blocks after mixin calls
                                          return 'RPAREN';
%}
// The addition of ATTRS_END is for the edge case of allowing a classname to immediately follow the attributes: a.class(some=attr).class
<INITIAL,ATTRS_END>{classname}
%{
  this.pushState('AFTER_TAG_NAME');
  yytext = yytext.substring(1);
                                          return 'CLASSNAME';
%}
<INITIAL,ATTRS_END>{classname_relaxed}
%{
  debug('<INITIAL,ATTRS_END>{classname_relaxed}')
  if (this.yy.parser.options.allowDigitToStartClassName) {
    this.pushState('AFTER_TAG_NAME');
    yytext = yytext.substring(1);
                                          return 'CLASSNAME';
  }
  else {
    throw new Error('Classnames starting with a digit is not allowed. Set allowDigitToStartClassName to true to allow.')
  }
%}

// <ATTRS_STARTED>')'
// %{
//   this.popState()
//   this.pushState('ATTRS_END')
//   // that ended quickly ;)
//                                           return 'RPAREN';
// %}

// Match key='answer' value=answer()
<ATTRS_STARTED>(\(.+|.+\().+
%{
  '))'
  debug('15 yytext=', yytext)
  debug('15 this.matches=', this.matches)

  const stack = []
  let i = 0
  for(; i < yytext.length; i++) {
    // debug('yytext[i]=', yytext[i])
    if (/[\)\]}]/.test(yytext[i])) {
      debug('match')
      debug('stack.peek()=', stack.peek())
      if (stack.length == 0 || stack.pop() != yytext[i]) {
        debug('stack.length=', stack.length)
        break;
      }
      // else if () {
      // }
    }
    else {
      switch (yytext[i]) {
        case '(':
          stack.push(')')
          break;
        case '[':
          stack.push(']')
          break;
        case '{':
          stack.push('}')
          break;
      }
      // else if () {
      // }
    }
  }

  this.unput(yytext.substring(i))
  yytext = yytext.substring(0, i)
  debug('15 yytext=', yytext)

  this.popState()
  this.pushState('ATTRS_END')
                                          return 'ATTR_TEXT';
%}

// Don't match `class= (tags || []).map((tag) => tag.replaceAll(" ", "_")).join(" ")`
// But match `a.foo(class='bar').baz`
<ATTRS_STARTED>([^\)]+)(')')(?!\s*\..+')')
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

// // match `class= (tags || []).map((tag) => tag.replaceAll(" ", "_")).join(" ")`
// <ATTRS_STARTED>.+')'
// %{
//   this.popState()
//   this.pushState('ATTRS_END')
//   debug('55 this.matches=', this.matches)
//   debug('55 this.matches.length=', this.matches.length)
//   debug('55 yytext=', yytext)
//   try {
//     this.unput(')');
//     if (this.matches.length > 1) {    
//       yytext = this.matches[1]
//       // if (yytext.startsWith(')')) {
//       //   yytext = yytext.substring(1)
//       // }
//     }
//   }
//   catch (e) {
//     console.error(e)
//   }
//   lparenOpen = false
//   debug('55 yytext=', yytext)
//                                           return 'ATTR_TEXT';
// %}


<AFTER_TAG_NAME>{tag_id}
%{
  this.pushState('AFTER_TAG_NAME');
  yytext = this.matches[1].substring(1)
                                          return 'TAG_ID';
%}
<AFTER_TAG_NAME>{classname}
%{
  // yytext = this.matches[1].substring(1);
  yytext = yytext.substring(1);
  debug('60 yytext=', yytext)
                                          return 'CLASSNAME';
%}
<AFTER_TAG_NAME>{classname_relaxed}
%{
  // debug('<AFTER_TAG_NAME>{classname_relaxed}')
  // debug('Object.keys(this).length=', Object.keys(this).length)
  // debug('Object.keys(this.yy).length=', Object.keys(this.yy).length)
  // debug('Object.keys(this.yy.parser).length=', Object.keys(this.yy.parser).length)
  // debug('this.yy.parser.options=', util.inspect(this.yy.parser.options, false, 10, true))
  if (this.yy.parser.options.allowDigitToStartClassName) {
    yytext = yytext.substring(1);
                                          return 'CLASSNAME';
  }
  else {
    throw new Error('Classnames starting with a digit is not allowed. Set allowDigitToStartClassName to true to allow.')
  }
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
<AFTER_TAG_NAME,AFTER_KEYWORD,AFTER_TEXT_TAG_NAME>{space}{classname_relaxed}
%{
  debug('<AFTER_TAG_NAME,AFTER_KEYWORD,AFTER_TEXT_TAG_NAME>{space}{classname_relaxed} this.parser.options=', this.parser.options)
  if (this.yy.parser.options.allowDigitToStartClassName) {
    this.pushState('ATTRS_END');
    yytext = yytext.substring(1);
                                          return 'TEXT';
  }
  else {
    throw new Error('Classnames starting with a digit is not allowed. Set allowDigitToStartClassName to true to allow.')
  }
%}

<AFTER_TAG_NAME,AFTER_KEYWORD,AFTER_TEXT_TAG_NAME>{space}
%{
  this.pushState('ATTRS_END');
  debug('<AFTER_TAG_NAME,AFTER_KEYWORD,AFTER_TEXT_TAG_NAME>{space}');
                                                              return 'SPACE';
%}


<ATTRS_END,MIXIN_PARAMS_END>{space}
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

<UNBUF_CODE_START>{space}
%{
  debug('<UNBUF_CODE_START>{space}');
                                          return 'SPACE';
%}
<UNBUF_CODE_START>.+
%{
                                          return 'UNBUF_CODE';
%}

<MIXIN_CALL_START>'('             
%{
  ')'
  this.popState();
  this.pushState('MIXIN_PARAMS_STARTED');
                                          return 'LPAREN';
%}
<MIXIN_CALL_START>{space}$             
%{
  this.popState();
%}

// removed "[^{space}]" from the beginning because of COMMENT
<TEXT>.+
%{
  debug('80 yytext=', yytext)
                                          return 'TEXT';
%}

// <MULTI_LINE_ATTRS>','
// %{
//   // this.popState();
//   // this.pushState('ATTRS_STARTED')
//                                           // return 'COMMA';
// %}
// <MULTI_LINE_ATTRS>')'                     return 'ATTR_TEXT_END';
<MULTI_LINE_ATTRS>','?(.*)')'
%{
  debug('110 this.matches=', this.matches)
  this.popState();
  yytext = this.matches[1]
                                          return 'ATTR_TEXT_END';
%}
<MULTI_LINE_ATTRS>.+                      return 'ATTR_TEXT_CONT';


// immediately closed - solely for `+list()`
<MIXIN_PARAMS_STARTED>')'
%{
  this.popState()
  this.pushState('MIXIN_PARAMS_END')
  yytext = ''
                                          return ['RPAREN', 'MIXIN_PARAMS'];
%}

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

<INITIAL>'<!--'.+'-->'
%{
  yytext = yytext.slice(4, -3)
                                          return 'HTML_COMMENT'
%}

<UNBUF_CODE>.
%{
  this.popState()
  this.unput(yytext)
%}
<UNBUF_CODE_BLOCK>.+
%{
                                          return 'UNBUF_CODE_BLOCK';
%}

// <INITIAL>.+
// %{
//                                           return 'TEXT'
// %}


/lex

%ebnf
%options token-stack 

%% 

/* language grammar */

start
  : EOF
  | line EOF
  // | MULTI_LINE_ATTRS_END EOF
  // {
  //   $$ = { state: 'MULTI_LINE_ATTRS_END' }
  // }
  ;

line
  : line_start
  // if I change TEXT to line_end, I get a bunch of conflicts. I don't want to deal with them now
  | line_start TEXT
  {
    debug('line: line_start TEXT: $line_start=', $line_start, ', $TEXT=', $TEXT)

    // if ($TEXT.includes('#[')) {
    //   debug('Calling parseInline with ', $TEXT)
    //   const possibleTags2 = parseInline.parse($TEXT)
    //   debug('possibleTags2=', possibleTags2)
    // }
    // $$ = { type: 'text', val: $TEXT }
    
    $$ = merge($line_start, { type: 'text', val: $TEXT })
  }
  | line_start UNBUF_CODE
  {
    $$ = merge($line_start, { type: 'unbuf_code', val: $UNBUF_CODE, state: 'UNBUF_CODE' })
  }
  // | line_start UNBUF_CODE_BLOCK
  // {
  //   $$ = merge($line_start, { type: 'unbuf_code', val: $UNBUF_CODE, state: 'UNBUF_CODE' })
  // }
  | line_start line_splitter line_end
  {
    debug('line: line_start line_splitter line_end: $line_start=', $line_start, ', $line_end=', $line_end)
    if ($line_end == undefined) {
      $$ = merge($line_start, $line_splitter)
    }
    else if ($line_end.hasOwnProperty('type') && $line_end.type == 'array') {
      $$ = merge($line_start, [$line_splitter, { children: $line_end.val }])
    }
    else {
      $$ = merge($line_start, [$line_splitter, $line_end])
    }
  }
  | line_start NESTED_TAG_START line
  {
    $$ = merge($line_start, { state: 'NESTED', children: [$line] })
  }
  | ATTR_TEXT_END
  {
    $$ = { type: 'attrs_end', val: parseAttrs.parse($ATTR_TEXT_END) }
  }
  | ATTR_TEXT_CONT
  {
    $$ = { type: 'attrs_cont', val: parseAttrs.parse($ATTR_TEXT_CONT), state: 'MULTI_LINE_ATTRS' }
  }
  | line_start AT_ATTRS
  {
    debug('line: line_start AT_ATTRS: $AT_ATTRS=', $AT_ATTRS)
    if ($AT_ATTRS.includes('{') && $AT_ATTRS.includes('}')) {
      let func = Function('return (' + $AT_ATTRS.substring(12, $AT_ATTRS.length - 1) + ')')
      let entries2 = Object.entries(func())
      debug('entries2=', entries2)
      let attrs2 = Object.entries(entries2).map(([index, [key, value]]) => {
        debug('name=', key, 'value=', value)
        return { name: key, val: value }
      })
      $$ = merge($line_start, { type: 'tag', attrs: attrs2 })
    }
    else {
      $$ = merge($line_start, 
        { type: 'tag', attrs: [{ val: $AT_ATTRS.substring(12, $AT_ATTRS.length - 1) }]}
      )
    }
  }
  | HTML_COMMENT
  {
    debug('$HTML_COMMENT=', $HTML_COMMENT)
    if ($HTML_COMMENT.includes('#')) {
      let elemsReturned = createElems($HTML_COMMENT, this.yy.parser)
      debug('elemsReturned', JSON.stringify(elemsReturned))
      $$ = { type: 'html_comment', children: elemsReturned }
    }
    else {
      $$ = { type: 'html_comment', val: $HTML_COMMENT }
    }
  }
  | UNBUF_CODE_BLOCK_START
  {
    $$ = { type: 'unbuf_code_block', state: 'UNBUF_CODE_BLOCK' }
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
    $$ = merge($first_token, { state: 'MULTI_LINE_ATTRS' })
    if ($3) {
      debug('3 Calling parseAttrs with ', $3)
      try {
        $$ = merge($first_token, {  attrs_start: parseAttrs.parse($3) })
      }
      catch (e) {
        console.error('Could not parse attributes=' +$3, e)
      }
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
  // Rule for the edgecase a(class='bar').baz
  | first_token attrs CLASSNAME
  {
    $$ = merge($first_token, [$attrs, { attrs: [ { name: 'class', val: quote($CLASSNAME) } ] }])
  }
  // Rule for the edgecase a.foo(class='bar').baz
  | first_token tag_part attrs CLASSNAME
  {
    debug('first_token tag_part attrs CLASSNAME: first_token=', $first_token, ', tag_part=', $tag_part, ', attrs=', $attrs, ', CLASSNAME=', $CLASSNAME)
    $$ = merge($first_token, [$tag_part, $attrs, { attrs: [ { name: 'class', val: quote($CLASSNAME) } ] }])
  }
  // | ATTR_TEXT
  // {
  //   debug('line_start: ATTR_TEXT')
  //   $$ = { type: 'attrs_cont', attrs_start: parseAttrs.parse($ATTR_TEXT) }
  // }
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
    $$ = { type: 'tag', attrs: [ { name: 'class', val: quote($CLASSNAME) } ] }
  }
  | TAG_ID
  {
    $$ = { type: 'tag', id: $TAG_ID }
  }
  // TODO: Should separate JS and CSS from regular text
  | TEXT
  {
    // if ($TEXT.includes('#[')) {
    //   debug('Calling parseInline with ', $TEXT)
    //   const possibleTags = parseInline.parse($TEXT)
    //   debug('possibleTags=', possibleTags)
    // }
    $$ = { type: 'text', val: $TEXT }
  }
  | COMMENT
  {
    $$ = { type: 'comment', state: 'TEXT_START' }
  }
  // | UNBUF_CODE_START
  // {
  //   debug('CODE_START')
  //   $$ = { type: 'code', state: 'CODE_START' }
  // }
  | UNBUF_CODE
  {
    $$ = { type: 'unbuf_code', val: $UNBUF_CODE, state: 'UNBUF_CODE' }
  }
  | UNBUF_CODE_BLOCK
  {
    $$ = { type: 'unbuf_code', val: $UNBUF_CODE_BLOCK, state: 'UNBUF_CODE_BLOCK' }
  }
  | MIXIN_CALL
  {
    debug('MIXIN_CALL=', $1)
    $$ = { type: 'mixin_call', name: $1.trim() }
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
    $$ = { }
  }
  | CONDITIONAL
  {
    $$ = { type: 'conditional', name: $CONDITIONAL }
  }
  | INTERP_START INTERP_VAL INTERP_END
  {
    debug('line: INTERP_START INTERP_VAL INTERP_END: $INTERP_VAL=', $INTERP_VAL)
    const resultInterpVal1 = attrResolver.resolve({ name: 'anonymous', val: $INTERP_VAL.slice(2, -1) })
    $$ = { type: 'tag', name: resultInterpVal1.val }
    // $$ = [{ type: 'interpolation', val: $INTERP_VAL.slice(2, -1) }]
  }
  // | INTERPOLATION_START
  // {
  //   debug('line: INTERPOLATION_START')
  //   $$ = { type: 'interpolation_start', state: 'INTERPOLATION_START' }
  // }
  | INTERP_VAL
  {
    debug('line: INTERP_VAL: $INTERP_VAL=', $INTERP_VAL)
    debug('AttrResolver=', AttrResolver)
    const resultInterpVal2 = attrResolver.resolve({ name: 'anonymous', val: $INTERP_VAL })
    debug('AttrResolver returned=', resultInterpVal2)
    $$ = { type: 'text', val: resultInterpVal2.val }
    // parser.parse(result)
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
    debug('1 Calling parseAttrs with ', $2)
    $$ = {}
    try {
      const attrs = parseAttrs.parse($2.trim())
      debug('attrs=', attrs)
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
    } catch (e) {
      console.error('Error parsing ' + $2, e)
    }
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
    let attrs1 = $1.map(cn => {
      return { name: 'class', val: quote(cn) } 
    })
    $$ = { type: 'tag', attrs: attrs1 }
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
  // | ATTR_TEXT_CONT
  // {
  //   debug('line_end: ATTR_TEXT_CONT')
  //   $$ = { attrscont: [$1] }
  // }
  | TEXT
  {
    debug('line_end: TEXT: $TEXT=', $TEXT)
    if ($TEXT.includes('#')) {

      let elemsReturned = createElems($TEXT, this.yy.parser)
      debug('elemsReturned', elemsReturned)
      $$ = { children: elemsReturned }
    }
    else {
      $$ = { type: 'text', val: $TEXT }
    }
  }
  | UNBUF_CODE
  {
    $$ = { type: 'unbuf_code', val: $UNBUF_CODE, state: 'UNBUF_CODE' }
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
    $$ = {}
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
  // | RPAREN
  ;

%% 
__module_imports__

const TEXT_TAGS_ALLOW_SUB_TAGS = true

const debug = debugFunc('pug-line-lexer')

let tagAlreadyFound = false
let obj
var lparenOpen = false
// const keysToMergeText = ['therest']

const attrResolver = new AttrResolver()

function rank(type1, type2) {
  if (type2 === 'text') {
    return type1
  }
  else if (type1 === type2) {
    return type1
  }
  // else if (type1 == 'tag' && type2 == 'tag_with_multiline_attrs') {
  //   return type2
  // }
  // else if (type1 == 'tag_with_multiline_attrs' && type2 == 'tag') {
  //   return type1
  // }
  else {
    return type1.concat(type2)
  }
} 

function isQuoted(str) {
  if (str.trim().slice(-1) === "'" && str.trim().slice(-1) === "'") {
    return true
  }
  if (str.trim().slice(-1) === '"' && str.trim().slice(-1) === "'") {
    return true
  }
  return false
}

function quote(str) {
  return '"' + str + '"'
}

function unquote(str) {
  return str.trim().slice(1, -1);
}

function merge(obj, src) {

  if (obj == undefined || _.isEmpty(obj)) {
    debug('empty/undefined obj, returning src')
    return src
  }
  else if (src == undefined || _.isEmpty(src)) {
    debug('empty/undefined src, returning obj')
    return obj
  }

  if (Array.isArray(src) && src.length > 0) {
    src = src.reduce(merge)
    debug('src reduced to=', src)
  }

  debug('merging', obj, src)

  // if (util.isDeepStrictEqual(src, [ { therest: '' } ]))
  //    return obj

  if (obj.type != 'text' && Object.keys(src).length == 1 && Object.keys(src)[0] == 'children' && src.children.length == 1 && src.children[0].hasOwnProperty('type') && src.children[0].type == 'text') {
    return Object.assign(obj, { val: src.children[0].val })
  }

  // function convertClassAttr(key, obj) {
  //   let ret
  //   if (key === 'attrs' && obj.length == 1 && obj[0].name === 'class') {
  //     ret = [{ classes: obj[0].val }]
  //   }
  //   else {
  //     ret = obj
  //   }
  //   return ret
  // }

  let ret = _.mergeWith(obj, src, function (objValue, srcValue, key, object, source, stack) {
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
    return rank(objValue, srcValue)
    // }
  })

  // if (ret.hasOwnProperty('attrs') && ret.attrs.length == 1 && Object.keys(ret.attrs[0]).length == 1 && Object.keys(ret.attrs[0])[0] == 'classes' && isQuoted(ret.attrs[0].classes)) {
  //   debug('merging', ' found classes')
  //   const classes = unquote(ret.attrs[0].classes)
  //   delete ret.attrs
  //   ret = merge(ret, { classes: classes })
  // }

  debug('merging', ' returning', ret)
  return ret
  //  return Object.assign(obj, src);
}

// creates nodes of text and/or interpolations
function createElems(text, parser) {
  const debug = debugFunc('pug-line-lexer:createElems')
  const matches1 = text.matchAll(/#[\[\{].*?[\]\}]/g)
  let idx = 0
  let elems = []
  for (const match of matches1) {
    debug('match=', match)
    if (idx != match.index) {
      const textToPush = text.substring(idx, match.index);
      debug('pushing text onto element array:', textToPush)
      elems.push({ type: 'text', val: textToPush })
      idx = match.index
    }
    if (match[0][1] == '[') {
      debug('found left bracked')
      const toParse = match[0].slice(2, -1)
      debug('sending to parser:', toParse)
      const results = parser.parse(toParse)
      debug('received from parser:', results)
      elems.push(results)
    }
    else {
      // const toParse = match[0]
      // debug('sending to parser:', toParse)
      // const results = parser.parse(toParse)
      // debug('received from parser:', results)
      // elems.push(...results)
      debug('pushing interpolation value to arr:', match[0].slice(2, -1))
      elems.push({ type: 'interpolation', val: match[0].slice(2, -1)})
    }
    idx += match[0].length
    // debug('match', match)
    // console.log(`Found ${match[0]} start=${match.index} end=${match.index + match[0].length}.`);
  }
  if (idx != text.length) {
    elems.push({ type: 'text', val: text.substring(idx, text.index) })
  }

  debug('returning=', util.inspect(elems, false, 5))
  return elems;
}

parser.main = function () {
  
  tagAlreadyFound = false
  lparenOpen = false

  function test(input, expected, strict = true, options) {

    if (_.isEmpty(options)) {
      debug(`\nTesting '${input}'...`)
    }
    else {
      debug(`\nTesting '${input}' with ${JSON.stringify(options)}...`)
      debug('parser.options before=', parser.options)
      parser.options = Object.assign(parser.options, options)
      debug('parser.options after=', parser.options)
    }

    tagAlreadyFound = false
    lparenOpen = false
    var actual = parser.parse(input)
    debug(input + ' ==> ', util.inspect(actual))
    
    let compareFunc
    if (strict)
      compareFunc = assert.deepEqual
    else 
      compareFunc = dyp

    compareFunc.call({}, actual, expected)
  }



// TODO:
test("<INTERPOLATION>'foo'", { type: 'text', val: "foo" } )


try {
  test('a.3foo', { name: 'a', type: 'tag', attrs: [ { name: 'class', val: '"3foo"' } ] }, null, { allowDigitToStartClassName: false })
//   fail('Should not allow for a class name to start with a digit')
} catch (e) {
  if (e.message != 'Classnames starting with a digit is not allowed. Set allowDigitToStartClassName to true to allow.') {
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

// test(`p.bar&attributes(attributes) One`, {})
// test(`p.baz.quux&attributes(attributes) Two`, {})
// test(`p&attributes(attributes) Three`, {})
// test(`p.bar&attributes(attributes)(class="baz") Four`, {})

// TODO: 
// The next bunch tests "Mixin Attributes"
// Tests include: mixin.merge.pug
// test(`+foo.hello`, {})
// test(`+foo#world`, {})
// test(`+foo.hello#world`, {})
// test(`+foo.hello.world`, {})
// test(`+foo(class="hello")`, {})
// test(`+foo.hello(class="world")`, {})
// test(`+foo`, {})
// test(`+foo&attributes({class: "hello"})`, {})

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
  type: 'tag',
  name: 'div',
  attrs: [{
    name: 'id',
    val: 'id'
  }, {
    name: 'foo',
    val: 'bar'
  }, {
    name: 'fred',
    val: 'bart'
  }]
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

test('include:markdown-it article.md', { type: 'include', val: 'article.md', filter: 'markdown-it' })
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
  name: "foo",
  type: 'tag',
  val: '/'
})

test('li= item', {
  assignment: true,
  assignment_val: 'item',
  name: 'li',
  type: 'tag'
})
// test('<MULTI_LINE_ATTRS_END>)', {
//   state: 'MULTI_LINE_ATTRS_END'
// })
// test('a(:link="goHere" value="static" :my-value="dynamic" @click="onClick()" :another="more") Click Me!', {})

test('-var ajax = true', {type: 'unbuf_code', val: 'var ajax = true', state: 'UNBUF_CODE'})
test('-if( ajax )', {type: 'unbuf_code', val: 'if( ajax )', state: 'UNBUF_CODE'})
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

test('<UNBUF_CODE_BLOCK>var i', {
  type: 'unbuf_code',
  val: 'var i',
  state: 'UNBUF_CODE_BLOCK'
})

test('} else {', {
  type: 'block_end',
  val: 'else {'
})

test("+project('Moddable Two (2) Case', 'Needing Documentation ', ['print'])", { type: 'mixin_call', name: 'project', params: 
    "'Moddable Two (2) Case', 'Needing Documentation ', ['print']"
  })

test('code(class="language-scss").', {
  name: 'code',
  type: 'tag',
  attrs: [ { name: 'class', val: '"language-scss"' } ],
  state: 'TEXT_START'
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
  type: 'mixin_call'
})

test('a(href=url)= url', {
  assignment: true,
  assignment_val: 'url',
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

test('- function answer() { return 42; }', {
  state: 'UNBUF_CODE',
  type: 'unbuf_code',
  val: 'function answer() { return 42; }'
})

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

test('div(id=id)&attributes({foo: \'bar\'})', {
  name: 'div',
  type: 'tag',
  attrs: [ { name: 'id', val: 'id' }, { name: 'foo', val: 'bar' } ]
})
test('div(foo=null bar=bar)&attributes({baz: \'baz\'})', {
  name: 'div',
  type: 'tag',
  attrs: [
    { name: 'foo', val: 'null' },
    { name: 'bar', val: 'bar' },
    { name: 'baz', val: 'baz' }
  ]
})

test('foo(abc', {type: 'tag', name: 'foo', attrs_start: [ { name: 'abc' }], state: 'MULTI_LINE_ATTRS'})
test('foo(abc,', {type: 'tag', name: 'foo', attrs_start: [ { name: 'abc' }], state: 'MULTI_LINE_ATTRS'})
test('<MULTI_LINE_ATTRS>,def)', { type: 'attrs_end', val: [ { name: 'def' } ] })
test('<MULTI_LINE_ATTRS>def)', { type: 'attrs_end', val: [ { name: 'def' } ] })

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
test('<MULTI_LINE_ATTRS>)', { type: 'attrs_end', val: '' })
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


test('+sensitive', {
  name: 'sensitive',
  type: 'mixin_call'
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

//test("// some text", { type: 'comment', state: 'TEXT_START' })
test("// some text", { type: 'comment', state: 'TEXT_START', val: ' some text' })

// test("// ", { type: 'comment', state: 'TEXT_START' })
test("// ", { type: 'comment', val: ' ', state: 'TEXT_START' })

test("//", { type: 'comment', state: 'TEXT_START' })


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
test('- var title = \'Fade Out On MouseOver Demo\'', { type: 'unbuf_code', val: 'var title = \'Fade Out On MouseOver Demo\'', state: 'UNBUF_CODE' })
test('<TEXT>}).join(\' \')', { type: 'text', val: "}).join(' ')" })
test('  ', {})
test('#content(role=\'main\')', {
  type: 'tag',
  id: 'content',
  attrs: [ { name: 'role', val: "'main'" } ]
})
test('pre: code(class="language-scss").', {
  name: 'pre',
  type: 'tag',
  state: 'NESTED',
  children: [
    { name: 'code', type: 'tag', attrs: [
        {
          name: 'class',
          val: '"language-scss"'
        }], state: 'TEXT_START' }
  ]
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

test('+project(\'Images\', \'On going\')', { type: 'mixin_call', name: 'project', params: "'Images', 'On going'" })
test("+project('Moddable Two (2) Case', 'Needing Documentation ', ['print'])", {
  type: 'mixin_call',
  name: 'project',
  params: "'Moddable Two (2) Case', 'Needing Documentation ', ['print']"
})
test('| . The only "gotcha" was I originally had "www.adamkoch.com" as the A record instead of "adamkoch.com". Not a big deal and easy to rectify.', { type: 'text', val: '. The only "gotcha" was I originally had "www.adamkoch.com" as the A record instead of "adamkoch.com". Not a big deal and easy to rectify.' })
test('<TEXT>| #start-resizable-editor-section{display:none}.wp-block-audio figcaption{color:#555;font-size:13px;', {"type":"text","val":"#start-resizable-editor-section{display:none}.wp-block-audio figcaption{color:#555;font-size:13px;" })

test('-', { type: 'unbuf_code_block', state: 'UNBUF_CODE_BLOCK' })
test('- ', { type: 'unbuf_code_block', state: 'UNBUF_CODE_BLOCK' })

test('mixin project(title)', {
  type: 'mixin',
  val: 'project(title)'
})
test('// comment', {
  state: 'TEXT_START',
  type: 'comment',
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

// test(' -', {
//   state: 'UNBUF_CODE_START',
//   type: 'code',
//   val: ''
// })

// if we get the state UNBUF_CODE followed by something other than '-', we should parse it as if the state wasn't there 
test('<UNBUF_CODE>var i', { name: 'var', type: 'tag', val: 'i' })

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
  val: "jq '.' package.json"
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
test("- var attrs = {foo: 'bar', bar: '<baz>'}",  {
  type: 'unbuf_code',
  state: 'UNBUF_CODE',
  val: "var attrs = {foo: 'bar', bar: '<baz>'}"
})
// test("a(foo='foo' \"bar\"=\"bar\")", {})

try {
  test("a(foo='foo' 'bar'='bar'))", {})
  fail('expected exception')
} catch (expected) {}

// TODO:
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
  params: '',
  name: 'list'
})

test(`+ list()`, {
  type: 'mixin_call',
  params: '',
  name: 'list'
})

};

