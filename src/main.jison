/* Pug single line parser */

/* lexical grammar */
%lex

%options case-insensitive

// ID          [A-Z-]+"?"?
// NUM         ([1-9][0-9]+|[0-9])
space  [ \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]
tag         (a|abbr|acronym|address|applet|area|article|aside|audio|b|base|basefont|bdi|bdo|bgsound|big|blink|blockquote|body|br|button|canvas|caption|center|cite|code|col|colgroup|content|data|datalist|dd|del|details|dfn|dialog|dir|div|dl|dt|em|embed|fb|fieldset|figcaption|figure|font|foo|footer|form|frame|frameset|h1|h2|h3|h4|h5|h6|head|header|hgroup|hr|html|i|iframe|image|img|input|ins|kbd|keygen|label|legend|li|link|main|map|mark|marquee|math|menu|menuitem|meta|meter|nav|nobr|noembed|noframes|noscript|object|ol|optgroup|option|output|p|param|picture|plaintext|portal|pre|progress|q|rb|rp|rt|rtc|ruby|s|samp|section|select|shadow|slot|small|source|spacer|span|strike|strong|sub|summary|sup|svg|table|tbody|td|template|textarea|tfoot|th|thead|time|title|tr|track|tt|u|ul|var|video|wbr|xmp)\b

keyword             (append|block|case|default|doctype|each|else|extends|for|if|include|mixin|prepend|unless|when|while|yield)\b
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
%x MIXIN_CALL
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
%x INTERPOLATION
%x MIXIN_PARAMS_END
%x UNBUF_CODE_START
%x UNBUF_CODE_BLOCK
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
<INITIAL,AFTER_TAG_NAME,ATTRS_END,MIXIN_CALL_START>'&attributes('[^\)]+')'
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

<AFTER_TAG_NAME,AFTER_TEXT_TAG_NAME>{space}
%{
  this.pushState('ATTRS_END');
  debug('<AFTER_TAG_NAME,AFTER_KEYWORD,AFTER_TEXT_TAG_NAME>{space}');
                                                              return 'SPACE';
%}

<AFTER_KEYWORD>{space}
%{
  this.pushState('ATTRS_END');
  debug('<AFTER_KEYWORD>{space}');
                                                              return 'SPACE';
%}


<ATTRS_END,MIXIN_PARAMS_END>{space}
%{
  this.pushState('TEXT');
  debug('<ATTRS_END>{space}');
                                                              return 'SPACE';
%}
<AFTER_TAG_NAME,AFTER_TEXT_TAG_NAME,ATTRS_END>'.'\s*<<EOF>>             return 'DOT_END';




<AFTER_TAG_NAME,AFTER_TEXT_TAG_NAME,NO_MORE_SPACE>.+
%{
  // if (yytext.startsWith(' ') {
  //   yytext = yytext.substring(1);
  // }
  debug('70 yytext=', yytext);
                                          return 'TEXT';
%}

// <AFTER_KEYWORD>{keyword}
// %{
//   // if (yytext.startsWith(' ') {
//   //   yytext = yytext.substring(1);
//   // }
//   debug('75 yytext=', yytext);
//   // this.pushState('BLOCK_BODY_BLOCK')
//                                           return 'KEYWORD';
// %}

<AFTER_KEYWORD>.+
%{
  // if (yytext.startsWith(' ') {
  //   yytext = yytext.substring(1);
  // }
  debug('77 yytext=', yytext);
  // this.pushState('BLOCK_BODY_BLOCK')
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

<MIXIN_CALL_START>{classname}
%{
  yytext = yytext.substring(1);
                                          return 'CLASSNAME';
%}

<MIXIN_CALL_START>{tag_id}
%{
  yytext = yytext.substring(1);
                                          return 'TAG_ID';
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

// a line that may or might not be code will start with this
<UNBUF_CODE_FOLLOWER>.+
%{
  this.popState()
  this.unput(yytext)
%}
<UNBUF_CODE,UNBUF_CODE_BLOCK>.+
%{
                                          return this.popState();
%}
<MIXIN_CALL>.
%{
  this.popState()
  this.unput(yytext)
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
    $$ = merge($line_start, { type: 'unbuf_code', val: $UNBUF_CODE, state: 'UNBUF_CODE_FOLLOWER' })
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
  // | line_start AT_ATTRS
  // {
  //   debug('line: line_start AT_ATTRS: $AT_ATTRS=', $AT_ATTRS)
  //   if ($AT_ATTRS.includes('{') && $AT_ATTRS.includes('}')) {
  //     let func = Function('return (' + $AT_ATTRS.substring(12, $AT_ATTRS.length - 1) + ')')
  //     let entries2 = Object.entries(func())
  //     debug('entries2=', entries2)
  //     let attrs2 = Object.entries(entries2).map(([index, [key, value]]) => {
  //       debug('name=', key, 'value=', value)
  //       return { name: key, val: value }
  //     })
  //     $$ = merge($line_start, { type: 'tag', attrs: attrs2 })
  //   }
  //   else {
  //     $$ = merge($line_start, 
  //       { type: 'tag', attrs: [{ val: $AT_ATTRS.substring(12, $AT_ATTRS.length - 1) }]}
  //     )
  //   }
  // }
  // | line_start AT_ATTRS line_splitter line_end
  // {
  //   debug('line: line_start AT_ATTRS line_splitter line_end: $AT_ATTRS=', $AT_ATTRS)
  //   if ($AT_ATTRS.includes('{') && $AT_ATTRS.includes('}')) {
  //     let func = Function('return (' + $AT_ATTRS.substring(12, $AT_ATTRS.length - 1) + ')')
  //     let entries2 = Object.entries(func())
  //     debug('entries2=', entries2)
  //     let attrs2 = Object.entries(entries2).map(([index, [key, value]]) => {
  //       debug('name=', key, 'value=', value)
  //       return { name: key, val: value }
  //     })
  //     $$ = merge($line_start, { type: 'tag', attrs: attrs2 })
  //   }
  //   else {
  //     $$ = merge($line_start, 
  //       { type: 'tag', attrs: [{ val: $AT_ATTRS.substring(12, $AT_ATTRS.length - 1) }]}
  //     )
  //   }
  // }
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
    $$ = { type: 'unbuf_code_block', state: 'UNBUF_CODE_BLOCK_START' }
  }
  ;

line_start
  : first_token
  | first_token tag_part+
  {
    debug('line_start: first_token tag_part+')
    $$ = merge($first_token, $2)
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
  // handle +foo.hello(class="world")
  | first_token tag_part LPAREN MIXIN_PARAMS RPAREN
  {
    debug('line_start: first_token tag_part LPAREN MIXIN_PARAMS RPAREN')
    $$ = merge(merge($first_token, $tag_part), { params: $MIXIN_PARAMS })
  }
  | first_token tag_part attrs
  {
    debug('line_start: first_token tag_part attrs')
    $$ = merge($first_token, [$tag_part, $attrs])
  }


  // Rule for the edgecase a(class='bar').baz
  | first_token attrs CLASSNAME
  {
    debug('first_token attrs CLASSNAME: first_token=', $first_token, ', attrs=', $attrs, ', CLASSNAME=', $CLASSNAME)
    $$ = merge($first_token, [$attrs, { attrs: [ { name: 'class', val: quote($CLASSNAME) } ] }])
  }
  // Rule for the edgecase a.foo(class='bar').baz
  | first_token tag_part attrs CLASSNAME
  {
    debug('first_token tag_part attrs CLASSNAME: first_token=', $first_token, ', tag_part=', $tag_part, ', attrs=', $attrs, ', CLASSNAME=', $CLASSNAME)
    $$ = merge($first_token, [$tag_part, $attrs, { attrs: [ { name: 'class', val: quote($CLASSNAME) } ] }])
  }


  // Rule for the edgecase div(id=id)&attributes({foo: 'bar', fred: 'bart'})
  | first_token attrs AT_ATTRS
  {
    debug('first_token attrs AT_ATTRS: first_token=', $first_token, ', $attrs=', $attrs, ', AT_ATTRS=', $AT_ATTRS)
    let attrArr = $attrs.attrs
    debug('1 attrArr=', attrArr)
    let atAttrObj = Function('return ' + $AT_ATTRS.slice(12, -1))();
    debug('2 atAttrObj=', atAttrObj)

    var atAttrObjToArray = Object.entries(atAttrObj).map(([name, val]) => ({name,val}));
    debug('3 atAttrObjToArray=', atAttrObjToArray)
    attrArr = attrArr.concat(atAttrObjToArray)
    debug('4 attrArr=', attrArr)

    $$ = merge($first_token, { attrs: attrArr })
  }



  // | ATTR_TEXT
  // {
  //   debug('line_start: ATTR_TEXT')
  //   $$ = { type: 'attrs_cont', attrs_start: parseAttrs.parse($ATTR_TEXT) }
  // }
  | first_token LPAREN MIXIN_PARAMS RPAREN
  {
    debug('first_token LPAREN MIXIN_PARAMS RPAREN: first_token=', $first_token, ', MIXIN_PARAMS=', $MIXIN_PARAMS)
    $$ = merge($first_token, { params: $MIXIN_PARAMS })
  }
  // | first_token tag_part AT_ATTRS
  // {
  //   debug('line:_start first_token tag_part AT_ATTRS=', $AT_ATTRS)
  //   if ($AT_ATTRS.includes('{') && $AT_ATTRS.includes('}')) {
  //     let func = Function('return (' + $AT_ATTRS.substring(12, $AT_ATTRS.length - 1) + ')')
  //     let entries2 = Object.entries(func())
  //     debug('entries2=', entries2)
  //     let attrs2 = Object.entries(entries2).map(([index, [key, value]]) => {
  //       debug('name=', key, 'value=', value)
  //       return { name: key, val: value }
  //     })
  //     $$ = merge($first_token, { type: 'tag', attrs: attrs2 })
  //   }
  //   else {
  //     $$ = merge($first_token, 
  //       { type: 'tag', attrs: [{ val: $AT_ATTRS.substring(12, $AT_ATTRS.length - 1) }]}
  //     )
  //   }
  // }
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
    if ($COMMENT[0] == '-') {
      $$ = { type: 'comment', state: 'TEXT_START' }
    }
    else {
      $$ = { type: 'html_comment', state: 'TEXT_START' }
    }
  }
  // | UNBUF_CODE_START
  // {
  //   debug('CODE_START')
  //   $$ = { type: 'code', state: 'CODE_START' }
  // }
  | UNBUF_CODE
  {
    $$ = { type: 'unbuf_code', val: $UNBUF_CODE, state: 'UNBUF_CODE_FOLLOWER' }
  }
  | UNBUF_CODE_BLOCK
  {
    $$ = { type: 'unbuf_code', val: $UNBUF_CODE_BLOCK, state: 'UNBUF_CODE_BLOCK' }
  }
  | MIXIN_CALL
  {
    debug('first_token MIXIN_CALL, $MIXIN_CALL=', $1)
    $$ = { type: 'mixin_call', name: $1.trim(), state: 'MIXIN_CALL' }
  }
  | KEYWORD
  {
    // %include ../src/keywords.js
    $$ = { type: $KEYWORD }
  }
  // | KEYWORD SPACE KEYWORD
  // {
  //   $$ = { type: $1, extraKeyword: $3 }
  // }
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
  | MIXIN_CALL_TODO
  {
    debug('line: MIXIN_CALL_TODO: $MIXIN_CALL_TODO=', $MIXIN_CALL_TODO)
    $$ = {}
  }
  ;

// tag_parts
//   : tag_part+
//   ;

tag_part
  : TAG_ID
  {
    $$ = { id: $TAG_ID }
  }
  // | TAG_ID classnames
  // {
  //   $$ = merge({ id: $TAG_ID }, $classnames)
  // }
  // | classnames
  // | classnames TAG_ID
  // {
  //   $$ = merge({ id: $TAG_ID }, $classnames)
  // }
  | CLASSNAME+
  {
    let attrs1 = $1.map(cn => {
      return { name: 'class', val: quote(cn) } 
    })
    $$ = { type: 'tag', attrs: attrs1 }
  }
  // | CLASSNAME
  // {
  //   $$ = { type: 'tag', attrs: [{ name: 'class', val: quote($CLASSNAME) }] }
  // }
  | FILTER
  {
    $$ = { filter: $FILTER }
  }
  | AT_ATTRS
  {
    debug('tag_part AT_ATTRS: $AT_ATTRS=', $AT_ATTRS)
    if ($AT_ATTRS.includes('{') && $AT_ATTRS.includes('}')) {
      let func = Function('return (' + $AT_ATTRS.substring(12, $AT_ATTRS.length - 1) + ')')
      let entries2 = Object.entries(func())
      debug('entries2=', entries2)
      let attrs2 = Object.entries(entries2).map(([index, [key, value]]) => {
        debug('name=', key, 'value=', value)
        return { name: key, val: value }
      })
      $$ = { type: 'tag', attrs: attrs2 }
    }
    else {
      $$ = { type: 'tag', attrs: [{ val: $AT_ATTRS.substring(12, $AT_ATTRS.length - 1) }]}
    }
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

// classnames
//   : CLASSNAME+
//   {
//     let attrs1 = $1.map(cn => {
//       return { name: 'class', val: quote(cn) } 
//     })
//     $$ = { type: 'tag', attrs: attrs1 }
//   }
//   // : CLASSNAME
//   // {
//   //   $$ = { type: 'tag', attrs: [{ name: 'class', val: quote($CLASSNAME) }] }
//   // }
//   ;

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
    $$ = { type: 'unbuf_code', val: $UNBUF_CODE, state: 'UNBUF_CODE_FOLLOWER' }
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
  else if (type1 == 'tag' && type2 == 'mixin_call') {
    return type2
  }
  else if (type1 == 'mixin_call' && type2 == 'tag') {
    return type1
  }
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

