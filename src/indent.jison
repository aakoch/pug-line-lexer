/* 
*/

%lex

spc  [ \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]

%s TEXT
%s ATTRS
%%


// Remove blank lines
^{spc}*$ ;

// Added this because dedent wasn't being calculated for things that started the line.
[\n](?=[^\s])  %{
  debug('lex.--none--.newline', 'stack[0]=' + stack[0]);
  let tokens1 = [];
  tokens1.unshift('NEWLINE')
  while (0 < stack[0]) {
    tokens1.unshift("DEDENT");
    stack.shift();
  }
  if (tokens1.length) {
    debug('lex.--none--.newline_top', 'returning ' + tokens1)
    return tokens1;
  }
%}

// Text prefixed with a pipe ('|') and a space
// '| ' %{
//   debug('lex.--none--.pipe_space')
//   this.pushState('TEXT')
//   return 'PIPE_SPACE'
// %}

// // Known HTML tags
// <INITIAL>^('a'|'abbr'|'acronym'|'address'|'applet'|'area'|'article'|'aside'|'audio'|'b'|'base'|'basefont'|'bdi'|'bdo'|'bgsound'|'big'|'blink'|'blockquote'|'body'|'br'|'button'|'canvas'|'caption'|'center'|'cite'|'code'|'col'|'colgroup'|'content'|'data'|'datalist'|'dd'|'del'|'details'|'dfn'|'dialog'|'dir'|'div'|'dl'|'dt'|'em'|'embed'|'fieldset'|'figcaption'|'figure'|'font'|'footer'|'form'|'frame'|'frameset'|'h1'|'head'|'header'|'hgroup'|'hr'|'html'|'i'|'iframe'|'image'|'img'|'input'|'ins'|'kbd'|'keygen'|'label'|'legend'|'li'|'link'|'main'|'map'|'mark'|'marquee'|'math'|'menu'|'menuitem'|'meta'|'meter'|'nav'|'nobr'|'noembed'|'noframes'|'noscript'|'object'|'ol'|'optgroup'|'option'|'output'|'p'|'param'|'picture'|'plaintext'|'portal'|'pre'|'progress'|'q'|'rb'|'rp'|'rt'|'rtc'|'ruby'|'s'|'samp'|'script'|'section'|'select'|'shadow'|'slot'|'small'|'source'|'spacer'|'span'|'strike'|'strong'|'style'|'sub'|'summary'|'sup'|'svg'|'table'|'tbody'|'td'|'template'|'textarea'|'tfoot'|'th'|'thead'|'time'|'title'|'tr'|'track'|'tt'|'u'|'ul'|'var'|'video'|'wbr'|'xmp')\b %{
//   debug('lex.INITIAL.tags', 'yytext=' + yytext);
//   return 'THEREST'
// %}

// <TEXT>\([^\r\n]+\)\s* %{
//   return 'THEREST'
// %}

// // HTML attributes designated between parenthesis
// // No prefix defined
// // Suffix of 0 or more spaces
// <INITIAL>\([^\r\n]+\)\s* %{
//   debug('lex.INITIAL.???notnewlinethenspaces', yy.lexer.conditionStack, this.topState())
//   return 'ATTRS_BLOCK'
// %}

// Text with a period at the end of the line.
// Overwriting default handling because the period is just part of the text and this isn't the start of text but the end.
<TEXT>\.\s*(?=[\r\n]+)  %{ // '.'\s*[\r\n]+ %{
  debug('lex.TEXT.DOT_NEWLINE_IN_TEXT', yy.lexer.conditionStack, this.topState())
  debug('lex.TEXT.DOT_NEWLINE_IN_TEXT', 'popping top state of ' + this.topState() + ' because of ' + yytext)
  this.popState()
  yytext = yytext.trim()
  return 'THEREST'
%}

// A period at the end of the line.
'.'\s*(?=[\r\n]+) %{
  debug('lex.--none--.DOT_NEWLINE', yy.lexer.conditionStack, this.topState())
  debug('lex.--none--.DOT_NEWLINE', 'pushing TEXT state twice')

  // doing this twice because the first one is removed by the following newline
  this.pushState('TEXT')
  this.pushState('TEXT')

  // added "return 'NEWLINE'" for line 25-26:
  // script(type='text/javascript').
  //   word;
  return 'NEWLINE'
%}

// ^[^\s]+  %{
//   debug('lex.--none-.no-space', 'text=' + yytext)
//   return 'WAT'
// %}

// Matches words at the beginning of a line or after and indent of 2 or more spaces.
//+ doctype html
//+ | White-space
//-                     var windowOpen;
(?!^\s{2,})[^\r\n]+ %{
  if (yytext[0] == ' ')
    yytext = yytext.substring(1)

  return 'THEREST'
%}

// Matches 1 or more newlines in which we usually want to pop the current state.
// We shouldn't pop the state when in TEXT state
[\r\n]+ %{
  if (this.topState() != 'TEXT') {
    debug('lex.--none--.newline', 'popping top state of ' + this.topState())
    this.popState()
    return 'NEWLINE'
  }
%}

// Remaining DEDENTs implied by EOF, regardless of tabs/spaces
\s*<<EOF>>		%{
  debug('lex.--none--.any_space_EOF', 'stack[0]=' + stack[0]);
  var tokens = [];
  while (0 < stack[0]) {
    debug('lex.--none--.spaces', 'popping top state of ' + this.topState())
    this.popState();
    tokens.unshift("DEDENT");
    stack.shift();
  }
   tokens.unshift("ENDOFFILE")
    
  if (tokens.length) 
    return tokens;
%}

// An indentation or dentation. Groups of 2 spaces or a tab. If the current indentation is less than the current indentation on the stack, then we are dedenting. Is that a word?
^({spc}{spc}|\t)+  %{
  // debug('lex.--none--.indent', 'entering')
  var indentation = yyleng - yytext.search(/\s/);
  // debug('lex.--none--.indent', yy.lexer.conditionStack)
  // debug('lex.--none--.indent', 'yytext=', yytext)
  // debug('lex.--none--.indent', 'stack=', stack)
  // debug('lex.--none--.indent', 'indentation=' + indentation)

  if (indentation == stack[0]) {
    debug('lex.--none--.indent', 'INDENT didn\'t change')
    return;
  }
  else if (indentation > stack[0]) {
    debug('lex.--none--.indent', 'INDENT increased')
    stack.unshift(indentation);
    return 'INDENT';
  }

  var tokens = [];

  while (indentation < stack[0]) {
    debug('lex.--none--.indent', 'popping top state of ' + this.topState())
    this.popState();
    tokens.unshift("DEDENT");

    // Removed so PIPE_SPACE -> newline -> dedent won't report an unexpected NEWLINE
    // tokens.unshift("NEWLINE");
    stack.shift();
  }
  if (tokens.length) {
    debug('lex.--none--.indent', 'returning ' + tokens)
    return tokens;
  }
%}

/lex


%options token-stack

%%

start
	: nodes ENDOFFILE
	;

nodes
  : nodes node
  { $nodes.push($node); $$ = $nodes; }
  | node
  { $$ = [$node]; }
  ;

node
	: something INDENT nodes DEDENT
  { $something.children = $nodes; $$ = $something; }
  // a leaf
  | something
	;

something
  // : PIPE_SPACE THEREST
  // { $$ = { text: $THEREST, loc: toLoc(yyloc), hint: 'PIPE_SPACE THEREST' } }
  // | TAG_NAME
  // {
  //   debug('parse.something.TAG_NAME', 'TAG_NAME=' + $TAG_NAME)
  //   $$ = { tag: $TAG_NAME, loc: toLoc(yyloc) } 
  // }
  // | TAG_NAME ATTRS_BLOCK
  // {
  //   debug('parse.something.TAG_NAME_ATTRS_BLOCK', 'TAG_NAME=' + $TAG_NAME, 'ATTRS_BLOCK=' + $ATTRS_BLOCK)
  //   $$ = { tag: $TAG_NAME, attrs: $ATTRS_BLOCK, loc: toLoc(yyloc) }
  // }
  // | TAG_NAME ATTRS_BLOCK THEREST
  // {
  //   debug('parse.something.TAG_NAME_ATTRS_BLOCK_THEREST', 'TAG_NAME=' + $TAG_NAME, 'ATTRS_BLOCK=' + $ATTRS_BLOCK, 'THEREST=' + $THEREST)
  //   $$ = { tag: $TAG_NAME, attrs: $ATTRS_BLOCK, val: $THEREST, loc: toLoc(yyloc) } 
  // }
  // | TAG_NAME THEREST
  // {
  //   debug('parse.something.TAG_NAME_THEREST_NEWLINE', 'TAG_NAME=' + $TAG_NAME)
  //   $$ = { tag: $TAG_NAME, val: $THEREST, loc: toLoc(yyloc) }
  // }
  : THEREST
  {
    debug('parse.something.THEREST', 'THEREST=' + $1)
    $$ = { something: $1, loc: toLoc(yyloc), hint: 'THEREST' } 
  }
  | THEREST NEWLINE
  {
    debug('parse.something.THEREST_NEWLINE', 'THEREST=' + $1)
    $$ = { something: $1, loc: toLoc(yyloc), hint: 'THEREST NEWLINE' } 
  }
  ;

%% 

var stack = [0];

function toLoc(yyloc) {
  if (location)
  return {
        start: {
          line: yyloc.first_line,
          column: yyloc.first_column
        },
        end: {
          line: yyloc.last_line,
          column: yyloc.last_column
        },
        filename: filename,
     }
  else 
    return ''
}

function log() {
  console.log(...arguments);
}

var filename;
var stripDown = false;
var location = true;

var util = require('util')

function ti(tagId) {
  if (tagId == undefined) 
    return '';

  let arr = []
  if (tagId.class != undefined) {
    arr.push('.')
    arr.push(tagId.class)
  }
  if (tagId.id != undefined) {
    arr.push('#')
    arr.push(tagId.id)
  }
  return arr.join('')
}

function strip(arr) {
  return arr
    .filter(el => {
      return util.isArray(el) || el.val
    })
    .map(el => {
      if (util.isArray(el)) {
        return strip(el);
      }
      return ([el.val, el.param, el.body, ti(el.tag_identifier), (el.attributes || []).map(el => el.key + '=' + el.val)])
        .filter(attr => attr != undefined)
        .map(attr => attr.toString().trim())
        .join(' ')
    })
}


const logLevels = {
  '': true,
  'lex': true,
  'parse': true,
  'parser': true
}

function isEnabled(pkg) {
  function findNearestLogLevel(pkg) {
    while(!logLevels.hasOwnProperty(pkg)) {
      pkg = pkg.substring(0, pkg.lastIndexOf('.') || 0)
    }
    return logLevels[pkg]
  }
  return findNearestLogLevel(pkg);
}

function debug() {
  if (isEnabled(arguments[0])) {
    console.log(...arguments)
    // console.log(arguments[0])
    // Array.from(arguments).slice(1).forEach(arg => {
    //   console.log(util.inspect(arg, false, 10))
    // })
  }
  else {
    // console.log(arguments[0] + ' is not enabled')
  }
}

parser.main = function (args) {
 parser.lexer.options.backtrack_lexer = true;
  lexer.options.post_lex = function(token) {
      // debug('main', parser.getSymbolName(token) || token)
      // // debug('main', 'this=', this)
      // debug('main', 'match=' + this.match)
      // debug('main', 'yytext=' + this.yytext)
      // // console.log(parser.quoteName())
      // // console.log(parser.describeSymbol(l))

      debug('main', (parser.getSymbolName(token) || token) + '=' + this.yytext)
  }


  parser.post_parse = function(yy, retval, parseInfo) { 
      // debug('main', 'yy', yy)
      // debug('main', 'retval', retval)
      // debug('main', 'parseInfo', parseInfo)
      debug('main', 'parseInfo.token', parseInfo.token)
      debug('main', 'parseInfo.value', parseInfo.value)
    return retval;
  }

     if (!args[1]) {
        console.log('Usage:', path.basename(args[0]) + ' FILE');
        process.exit(1);
    }
    filename = args[1]
    var source = fs.readFileSync(path.normalize(args[1]), 'utf8') + '\n';
    var dst = exports.parser.parse(source);

    if (stripDown) 
      dst = strip(dst)

    console.log('parser output:\n\n', {
        type: typeof dst,
        value: dst
    });
    try {
        console.log("\n\nor as JSON:\n", JSON.stringify(dst, null, 2));
    } catch (e) { /* ignore crashes; output MAY not be serializable! We are a generic bit of code, after all... */ }
    var rv = 0;
    if (typeof dst === 'number' || typeof dst === 'boolean') {
        rv = dst;
    }
    return dst;
};