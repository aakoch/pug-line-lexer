/* Pug single line parser */

/* lexical grammar */
%lex

%options case-insensitive

// ID          [A-Z-]+"?"?
// NUM         ([1-9][0-9]+|[0-9])
space  [ \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]
tag_name              (a|abbr|acronym|address|applet|area|article|aside|audio|b|base|basefont|bdi|bdo|bgsound|big|blink|blockquote|body|br|button|canvas|caption|center|cite|code|col|colgroup|content|data|datalist|dd|del|details|dfn|dialog|dir|div|dl|dt|em|embed|fieldset|figcaption|figure|font|foo|footer|form|frame|frameset|h1|h2|h3|h4|h5|h6|head|header|hgroup|hr|html|i|iframe|image|img|input|ins|kbd|keygen|label|legend|li|link|main|map|mark|marquee|math|menu|menuitem|meta|meter|nav|nobr|noembed|noframes|noscript|object|ol|optgroup|option|output|p|param|picture|plaintext|portal|pre|progress|q|rb|rp|rt|rtc|ruby|s|samp|section|select|shadow|slot|small|source|spacer|span|strike|strong|sub|summary|sup|svg|table|tbody|td|template|textarea|tfoot|th|thead|time|title|tr|track|tt|u|ul|var|video|wbr|xmp)\b

filter_name         (cdata)\b


// short_tag_start           #\[
// short_tag_end             \]
// dot                       \.

%x AFTER_TAG_START
%x AFTER_TAG_START_END
%x ASSIGNMENT_STARTED

%%


'\#'
%{
                                            return 'TEXT'
%}

(?:'#['\s*){tag_name}
%{
  '])'
  yytext = this.matches[1]
  this.pushState('TAG_STARTED')
                                          return 'TAG_START'
%}

(?:'#['\s*)':'{filter_name}
%{
  '])'
  yytext = this.matches[1]
  this.pushState('TAG_STARTED')
                                          return 'FILTER_START'
%}

<INITIAL>(\w|{space}|[^#])+               return 'TEXT'

<TAG_STARTED>'='
%{
  this.popState()
  this.pushState('ASSIGNMENT_STARTED')
                                          return 'EQ'
%}
<ASSIGNMENT_STARTED>[ ']
%{
                                          return 'ASSIGN_PART'
%}
<ASSIGNMENT_STARTED>'['
%{
  ']'
  this.pushState('ASSIGNMENT_STARTED_BRACKET_ADDED')
                                          return 'ASSIGN_PART'
%}
<ASSIGNMENT_STARTED_BRACKET_ADDED>']'
%{
  this.popState()
                                          return 'ASSIGN_PART'
%}
<ASSIGNMENT_STARTED,ASSIGNMENT_STARTED_BRACKET_ADDED>\w+
%{
                                          return 'ASSIGN_PART'
%}
<ASSIGNMENT_STARTED>']'
%{
  this.popState()
                                          return 'TAG_END'
%}

<TAG_STARTED,BODY_STARTED>'['
%{
  '])'
  this.pushState('BRACKET_ADDED')
                                          return 'ATTR'
%}


<TAG_STARTED,BODY_STARTED>'['
%{
  '])'
  this.pushState('BRACKET_ADDED')
                                          return 'LBRACKET'
%}
<BRACKET_ADDED>']'
%{
  this.popState()
                                          return 'RBRACKET'
%}

<ATTRS_STARTED>'('
%{
  '])'
  this.pushState('PARENS_ADDED')
                                          return 'LPAREN'
%}
<PARENS_ADDED>')'
%{
  this.popState()
                                          return 'RPAREN'
%}

<TAG_STARTED>']'
%{
                                          return 'TAG_END'
%}
<TAG_STARTED>'('
%{
  ')'
  this.popState()
  this.pushState('ATTRS_STARTED')
%}

<TAG_STARTED>{space}
%{
  this.popState()
  this.pushState('BODY_STARTED')
%}

<ATTRS_STARTED>\w+
%{
                                          return 'ATTR'
%}
<ATTRS_STARTED>{space}+
%{
                                          return 'ATTR'
%}
<ATTRS_STARTED>[^()\]]+
%{
                                          return 'ATTR'
%}

<ATTRS_STARTED>')'
%{
  this.popState()
                                          return 'TAG_END'
%}

<BODY_STARTED,ATTRS_STARTED>\w+
%{
                                          return 'BODY'
%}
<BODY_STARTED,ATTRS_STARTED>{space}+
%{
                                          return 'BODY'
%}
<BODY_STARTED>']'
%{
  this.popState()
                                          return 'TAG_END'
%}


<<EOF>>                                   return 'EOF';
/lex

%ebnf
%options token-stack 

%% 

start
  : line EOF
  ;

line
  : line line_part
  {
    debug('line: line line_part: $line=', $line, ', $line_part=', $line_part)
    if (Array.isArray($line)) {
      $$ = $line
    }
    else {
      $$ = [ $line ]
    }
    $$.push($line_part)
  }
  | line_part
  {
    debug('line: line_part: $line_part=', $line_part)
    if (Array.isArray($line_part)) {
      $$ = $line_part
    }
    else {
      $$ = [ $line_part ]
    }
  }
  ;

line_part
  : 
  | TAG
  {
    let [tag_name, attrs, body] = $TAG
    debug('$TAG=', $TAG)
    debug('tag_name=', tag_name)
    debug('attrs=', attrs)
    debug('body=', body)
    const obj1 = { type: 'tag', name: tag_name, attrs: attrs }
    if (attrs == undefined) delete obj1.attrs
    if (body == '') {
      delete obj1.val
    }
    else if (body.includes('<') && body.includes('>')) {
      debug('parsing ', body)
      recursive++
      let parsedBody = yy.parser.parse(body)
      recursive--
      debug('parsedBody=', parsedBody)
      if (parsedBody.length == 1 && parsedBody[0].type == 'text' && !parsedBody[0].hasOwnProperty('children')) {
        obj1.val = parsedBody[0].val
      }
      else {
        obj1.children = obj1.hasOwnProperty('children') ? obj1.children.push(...parsedBody) : parsedBody
      }
    }
    else {
      obj1.val = body
    }
    $$ = obj1
  }
  | TEXT+
  {
    $$ = { type: 'text', val: $1.join('') }
  }
  | TAG_START TAG_END
  {
    $$ = { type: 'tag', name: $TAG_START }
  }
  | TAG_START BODY+ TAG_END
  {
    $$ = { type: 'tag', name: $TAG_START, val: $2.join('') }
  }
  | TAG_START BODY+ TAG_END
  {
    $$ = { type: 'tag', name: $TAG_START, val: $2.join('') }
  }
  | TAG_START ATTR+ TAG_END
  {
    $$ = { type: 'tag', name: $TAG_START, attrs: parseAttrs.parse($2.join('')) }
  }
  | TAG_START ATTR+ BODY+ TAG_END
  {
    $$ = { type: 'tag', name: $TAG_START, val: $3.join(''), attrs: parseAttrs.parse($2.join('')) }
  }
  | TAG_START ATTR+ BODY+ TAG_END
  {
    $$ = { type: 'tag', name: $TAG_START, val: $3.join(''), attrs: parseAttrs.parse($2.join('')) }
  }
  | FILTER_START TAG_END
  {
    $$ = { type: 'filter', name: $FILTER_START }
  }
  | FILTER_START BODY+ TAG_END
  {
    $$ = { type: 'filter', name: $FILTER_START, val: $2.join('') }
  }
  | FILTER_START BODY+ TAG_END
  {
    $$ = { type: 'filter', name: $FILTER_START, val: $2.join('') }
  }
  | FILTER_START ATTR+ TAG_END
  {
    $$ = { type: 'filter', name: $FILTER_START, attrs: parseAttrs.parse($2.join('')) }
  }
  | FILTER_START ATTR+ BODY+ TAG_END
  {
    $$ = { type: 'filter', name: $FILTER_START, val: $3.join(''), attrs: parseAttrs.parse($2.join('')) }
  }
  | FILTER_START ATTR+ BODY+ TAG_END
  {
    $$ = { type: 'filter', name: $FILTER_START, val: $3.join(''), attrs: parseAttrs.parse($2.join('')) }
  }

  | TAG_START EQ ASSIGN_PART+ TAG_END
  {
    $$ = { type: 'tag', name: $TAG_START, assignment: $3.join('') }
  }
  | TAG_START EQ ASSIGN_PART+ ATTR+ TAG_END
  {
    $$ = { type: 'tag', name: $TAG_START, assignment: $3.join(''), attrs: parseAttrs.parse($5.join('')) }
  }
  | TAG_START EQ ASSIGN_PART+ BODY+ TAG_END
  {
    $$ = { type: 'tag', name: $TAG_START, assignment: $3.join(''), val: $5.join('') }
  }
  | TAG_START EQ ASSIGN_PART+ ATTR+ BODY+ TAG_END
  {
    $$ = { type: 'tag', name: $TAG_START, assignment: $3.join(''), val: $6.join(''), attrs: parseAttrs.parse($5.join('')) }
  }
  ;

%% 

__module_imports__

const TEXT_TAGS_ALLOW_SUB_TAGS = true

const debug = debugFunc('pug-line-lexer:inline')

let tagAlreadyFound = false
let obj
var lparenOpen = false
const keysToMergeText = ['therest']
const tags = []

const adam = "div"
var recursive = 1

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
    debug(input + ' ==> ', util.inspect(actual, false, 8))
    
    let compareFunc
    if (strict)
      compareFunc = assert.deepEqual
    else 
      compareFunc = dyp

    // fs.writeFileSync('actual.json', JSON.stringify(actual))
    // fs.writeFileSync('expected.json', JSON.stringify(expected))

    compareFunc.call({}, actual, expected)
  }

test('#[br]', [{ type: 'tag', name: 'br' }])
test('#[strong mighty]', [{ type: 'tag', name: 'strong', val: 'mighty' }])
test('A #[strong strongly worded phrase] that cannot be #[em ignored].', [
  { type: 'text', val: 'A ' },
  { type: 'tag', name: 'strong', val: 'strongly worded phrase' },
  { type: 'text', val: ' that cannot be ' },
  { type: 'tag', name: 'em', val: 'ignored' },
  { type: 'text', val: '.' }
])
test('This is a very long and boring paragraph that spans multiple lines. Suddenly there is a #[strong strongly worded phrase] that cannot be #[em ignored].', [
  {
    type: 'text',
    val: 'This is a very long and boring paragraph that spans multiple lines. Suddenly there is a '
  },
  { type: 'tag', name: 'strong', val: 'strongly worded phrase' },
  { type: 'text', val: ' that cannot be ' },
  { type: 'tag', name: 'em', val: 'ignored' },
  { type: 'text', val: '.' }
])
test('And here\'s an example of an interpolated tag with an attribute: #[q(lang="es") ¡Hola Mundo!]', [
  {
    type: 'text',
    val: "And here's an example of an interpolated tag with an attribute: "
  },
  { type: 'tag', name: 'q', attrs: [ { name: 'lang', val: '"es"' } ] },
  { type: 'text', val: ' ¡Hola Mundo!]' }
])

try {
  test('#[strong a}', {})
  fail('expected exception')
} catch (expected) {}

test('before #[:cdata inside] after', [
  { type: 'text', val: 'before ' },
  { type: 'filter', name: 'cdata', val: 'inside' },
  { type: 'text', val: ' after' }
])
test('bing #[strong foo] bong', [
  { type: 'text', val: 'bing ' },
  { type: 'tag', name: 'strong', val: 'foo' },
  { type: 'text', val: ' bong' }
])

test("bing #[strong foo] #[strong= '[foo]'] bong",  [
  { type: 'text', val: 'bing ' },
  { type: 'tag', name: 'strong', val: 'foo' },
  { type: 'text', val: ' ' },
  { type: 'tag', name: 'strong', assignment: " '[foo]'" },
  { type: 'text', val: ' bong' }
])

// TODO:
// test("bing #[- var foo = 'foo]'] bong", {})

test('\\#[strong escaped]', [ { type: 'text', val: '\\#[strong escaped]' } ])
test('\\#[#[strong escaped]', [
  { type: 'text', val: '\\#[' },
  { type: 'tag', name: 'strong', val: 'escaped' }
])

// TODO:
// test("#[a.rho(href='#', class='rho--modifier') with inline link]", {})
// test("Some text #[a.rho(href='#', class='rho--modifier')]", {})
// test("Some text #[a.rho(href='#', class='rho--modifier') with inline link]", {})
// test("This also works #[+linkit('http://www.bing.com')] so hurrah for Pug", {})

};

