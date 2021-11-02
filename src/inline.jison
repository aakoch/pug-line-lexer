/* Pug single line parser */

/* lexical grammar */
%lex

%options case-insensitive

// ID          [A-Z-]+"?"?
// NUM         ([1-9][0-9]+|[0-9])
space  [ \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]
tag_name              (a|abbr|acronym|address|applet|area|article|aside|audio|b|base|basefont|bdi|bdo|bgsound|big|blink|blockquote|body|br|button|canvas|caption|center|cite|code|col|colgroup|content|data|datalist|dd|del|details|dfn|dialog|dir|div|dl|dt|em|embed|fieldset|figcaption|figure|font|foo|footer|form|frame|frameset|h1|h2|h3|h4|h5|h6|head|header|hgroup|hr|html|i|iframe|image|img|input|ins|kbd|keygen|label|legend|li|link|main|map|mark|marquee|math|menu|menuitem|meta|meter|nav|nobr|noembed|noframes|noscript|object|ol|optgroup|option|output|p|param|picture|plaintext|portal|pre|progress|q|rb|rp|rt|rtc|ruby|s|samp|section|select|shadow|slot|small|source|spacer|span|strike|strong|sub|summary|sup|svg|table|tbody|td|template|textarea|tfoot|th|thead|time|title|tr|track|tt|u|ul|var|video|wbr|xmp)\b
pug_tag_start         #\[(a|abbr|acronym|address|applet|area|article|aside|audio|b|base|basefont|bdi|bdo|bgsound|big|blink|blockquote|body|br|button|canvas|caption|center|cite|code|col|colgroup|content|data|datalist|dd|del|details|dfn|dialog|dir|div|dl|dt|em|embed|fieldset|figcaption|figure|font|foo|footer|form|frame|frameset|h1|h2|h3|h4|h5|h6|head|header|hgroup|hr|html|i|iframe|image|img|input|ins|kbd|keygen|label|legend|li|link|main|map|mark|marquee|math|menu|menuitem|meta|meter|nav|nobr|noembed|noframes|noscript|object|ol|optgroup|option|output|p|param|picture|plaintext|portal|pre|progress|q|rb|rp|rt|rtc|ruby|s|samp|section|select|shadow|slot|small|source|spacer|span|strike|strong|sub|summary|sup|svg|table|tbody|td|template|textarea|tfoot|th|thead|time|title|tr|track|tt|u|ul|var|video|wbr|xmp)\b

html_tag_end             \<\/\w+\>
pug_tag_end             \]
word                    \w
dot                     \.

%x AFTER_TAG_START
%x AFTER_TAG_START_END

%%

<INITIAL,AFTER_TAG_START_END>'<'\s*({tag_name})
%{
  // yytext = yytext.substring(1, yytext.length - 1)
  debug('start tag: ' + this.matches[1])
  this.pushState('AFTER_TAG_START')
  tags.push(this.matches[1])
  yytext = this.matches[1]
                                          return 'TAG_START';
%}

<AFTER_TAG_START>(?!\\)'>'
%{
  debug('TAG_START_END')
  this.popState()
  this.pushState('AFTER_TAG_START_END')
                                          return 'TAG_START_END';
%}

<AFTER_TAG_START_END>'</'\s*(\w+)\s*'>'
%{
  debug('30 this.matches=', this.matches)
  debug('yytext = ' + yytext)
  debug('tags = ' + tags)
  if (this.matches[1] == tags.pop()) {
    debug('inside')
    this.popState()
                                          return 'TAG_END';
  }
  else {
    this.unput(this.matches.input)
  }
  // yytext = yytext.substring(1, yytext.length - 1)
  // tags.push(yytext)
%}
// {html_tag_end}
// %{
//   actualTag = yytext.substring(2, yytext.length - 1)
//   let expectedTag = tags.pop()
//   if (expectedTag != actualTag) {
//     throw new Error(`Ending tag "${actualTag}" didn't match start "${expectedTag}"`)
//   }
//                                           return 'TAG_END';
// %}
{pug_tag_start}{space}
%{
  this.pushState('AFTER_TAG_START_END');
  yytext = yytext.substring(2, yytext.length - 1)
                                          return ['TAG_START_END', 'TAG_START'];
%}
<AFTER_TAG_START_END>{pug_tag_end}
%{
  this.popState()
                                          return 'TAG_END';
%}
<INITIAL,AFTER_TAG_START_END>{space}
%{
                                          return 'SPACE';
%}
<INITIAL>{word}+
%{
                                          return 'WORD';
%}
<INITIAL>{dot}
%{
                                          return 'WORD';
%}
<AFTER_TAG_START_END>{word}+
%{
                                          return 'WORD';
%}
<<EOF>>                                   return 'EOF';


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
  : line line_part
  {
    // debug('line line_part: line=', $line, ', line_part=', $line_part)
    // console.log($line_part)

    // just to remove blank lines:
    if (typeof $line_part === 'string' && $line_part.length == 0) {
      $$ = $line
    }
    else {
      $$ = [$line].flat()
      $$.push($line_part)
    }
  }
  | line_part
  {
    $$ = [$line_part]
  }
  ;

line_part
  : words
  {
    $$ = { type: 'text', val: $words.flat().join('') }
  }
  | tag
  ;

words
  : words word
  {
    $words.push($word)
    $$ = $words
  }
  | word
  {
    $$ = [$word]
  }
  ;

word
  // : words words
  // {
  // //   debug('words SPACE WORD: words=', $words, ', WORD=', $WORD)
  //   $$ = [$words1].flat()
  //   $$.push($words2)
  // }
  // | words SPACE
  // {
  //   debug('words SPACE: words=', $words)
  //   $$ = [$words].flat()
  //   $$.push($SPACE)
  // }
  // | SPACE words
  // {
  //   debug('SPACE words: words=', $words)
  //   $$ = [$SPACE].flat()
  //   $$.push($words)
  // }
  : SPACE
  {
    debug('SPACE')
    $$ = [$SPACE]
  }
  | WORD
  {
    debug('WORD: WORD=', $WORD)
    $$ = [$WORD]
  }
  ;

line_parts
  : line_parts line_part
  | line_part 
  ;

tag
  : opening_tag line_part TAG_END
  {
    debug('TAG_START line_part TAG_END: TAG_START=', $opening_tag, ', line_part=', $line_part)
    if ($line_part.type === 'text') {
      $$ = { type: 'tag', name: $opening_tag, val: $line_part.val }
    }
    else {
      $$ = { type: 'tag', name: $opening_tag, val: $line_part }
    }
  }
  | opening_tag line_part line_parts TAG_END
  {
    debug('TAG_START line_part line_parts TAG_END: TAG_START=', $opening_tag, ', line_part=', $line_part, ', line_parts=', $line_parts)
    if ($line_part.type === 'text') {
      $$ = { type: 'tag', name: $opening_tag, val: $line_part.val }
    }
    else {
      $$ = { type: 'tag', name: $opening_tag, val: $line_part }
    }
  }
  | opening_tag TAG_END
  {
    $$ = { type: 'tag', name: $opening_tag }
  }
  | TAG_SELF_CLOSING
  {
    $$ = { type: 'tag', name: $TAG_SELF_CLOSING }
  }
  ;

opening_tag
  : TAG_START TAG_START_END
  ;

%% 
var assert = require("assert");
var util = require("util");
var _ = require("lodash");
var debugFunc = require('debug')
const dyp = require('dyp');

const TEXT_TAGS_ALLOW_SUB_TAGS = true

const debug = debugFunc('pug-line-lexer:inline')

let tagAlreadyFound = false
let obj
var lparenOpen = false
const keysToMergeText = ['therest']
const tags = []

const adam = "div"

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


test('<div></div>', [{ type: 'tag', name: 'div' }])
test('<div></div>a', [
  {
    name: 'div',
    type: 'tag'
  },
  {
    type: 'text',
    val: 'a'
  }
])

// test('A sentence with a <span><strong>strongly</strong> worded phrase</span> that cannot be <em>ignored</em>.', [
//     { type: 'text', val: 'A sentence with a ' },
//     { type: 'tag', name: 'strong', val: 'strongly worded phrase' },
//     { type: 'text', val: ' that cannot be ' },
//     { type: 'tag', name: 'em', val: 'ignored' },
//     { type: 'text', val: '.' }
//   ])
test('A sentence with a #[strong strongly worded phrase] that cannot be #[em ignored].', [
    { type: 'text', val: 'A sentence with a ' },
    { type: 'tag', name: 'strong', val: 'strongly worded phrase' },
    { type: 'text', val: ' that cannot be ' },
    { type: 'tag', name: 'em', val: 'ignored' },
    { type: 'text', val: '.' }
  ])
test('A sentence with a <strong>strongly worded phrase</strong> that cannot be <em>ignored</em>.', [
    { type: 'text', val: 'A sentence with a ' },
    { type: 'tag', name: 'strong', val: 'strongly worded phrase' },
    { type: 'text', val: ' that cannot be ' },
    { type: 'tag', name: 'em', val: 'ignored' },
    { type: 'text', val: '.' }
  ])
};

