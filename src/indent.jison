/* 
*/

%lex

spc  [ \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]

%s TEXT
%s ATTRS
%%

// Text prefixed with a pipe ('|') and a space
'| ' %{
  debug('lex.--none--.pipe_space')
  this.pushState('TEXT')
  return 'PIPE_SPACE'
%}

// Known HTML tags
<INITIAL>('a'|'abbr'|'acronym'|'address'|'applet'|'area'|'article'|'aside'|'audio'|'b'|'base'|'basefont'|'bdi'|'bdo'|'bgsound'|'big'|'blink'|'blockquote'|'body'|'br'|'button'|'canvas'|'caption'|'center'|'cite'|'code'|'col'|'colgroup'|'content'|'data'|'datalist'|'dd'|'del'|'details'|'dfn'|'dialog'|'dir'|'div'|'dl'|'dt'|'em'|'embed'|'fieldset'|'figcaption'|'figure'|'font'|'footer'|'form'|'frame'|'frameset'|'h1'|'head'|'header'|'hgroup'|'hr'|'html'|'i'|'iframe'|'image'|'img'|'input'|'ins'|'kbd'|'keygen'|'label'|'legend'|'li'|'link'|'main'|'map'|'mark'|'marquee'|'math'|'menu'|'menuitem'|'meta'|'meter'|'nav'|'nobr'|'noembed'|'noframes'|'noscript'|'object'|'ol'|'optgroup'|'option'|'output'|'p'|'param'|'picture'|'plaintext'|'portal'|'pre'|'progress'|'q'|'rb'|'rp'|'rt'|'rtc'|'ruby'|'s'|'samp'|'script'|'section'|'select'|'shadow'|'slot'|'small'|'source'|'spacer'|'span'|'strike'|'strong'|'style'|'sub'|'summary'|'sup'|'svg'|'table'|'tbody'|'td'|'template'|'textarea'|'tfoot'|'th'|'thead'|'time'|'title'|'tr'|'track'|'tt'|'u'|'ul'|'var'|'video'|'wbr'|'xmp')\b return 'TAG_NAME'

// <TEXT>\([^\r\n]+\)\s* %{
//   return 'THEREST'
// %}

// HTML attributes designated between parenthesis
// No prefix defined
// Suffix of 0 or more spaces
<INITIAL>\([^\r\n]+\)\s* %{
  debug('lex.INITIAL.???notnewlinethenspaces', yy.lexer.conditionStack, this.topState())
  return 'ATTRS_BLOCK'
%}

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
  debug('pushing TEXT state')
  this.pushState('TEXT')
%}

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
[\r\n]+ %{
  debug('lex.--none--.newline', 'popping top state of ' + this.topState())
  this.popState()
%};

// Remaining DEDENTs implied by EOF, regardless of tabs/spaces
\s*<<EOF>>		%{
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

// Remove blank lines
^{spc}*$ ;

// An indentation or dentation. Groups of 2 spaces or a tab. If the current indentation is less than the current indentation on the stack, then we are dedenting. Is that a word?
^({spc}{spc}|\t)+  %{
  debug('lex.--none--.indent', 'entering')
  var indentation = yyleng - yytext.search(/\s/) - 1;
  debug('lex.--none--.indent', yy.lexer.conditionStack)
  // debug('lex.--none--.indent', 'yytext=', yytext)
  debug('lex.--none--.indent', 'stack=', stack)
  debug('lex.--none--.indent', 'indentation=' + indentation)

  if (indentation > stack[0]) {
    debug('lex.--none--.indent', 'returning INDENT')
    stack.unshift(util.isArray(stack[0]) ? ['text', indentation] : indentation);
    return 'INDENT';
  }

  var tokens = [];

  while (indentation < stack[0]) {
    debug('lex.--none--.indent', 'popping top state of ' + this.topState())
    this.popState();
    tokens.unshift("DEDENT");
    stack.shift();
  }
  if (tokens.length) {
    debug('lex.--none--.indent', 'returning ' + tokens)
    return tokens;
  }
%}

/lex


%ebnf


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
	| something
	;

something
  : PIPE_SPACE THEREST
  { $$ = { text: $THEREST, loc: toLoc(yyloc) } }
  | TAG_NAME
  { $$ = { tag: $TAG_NAME, loc: toLoc(yyloc) } }
  | TAG_NAME ATTRS_BLOCK
  { $$ = { tag: $TAG_NAME, attrs: $ATTRS_BLOCK, loc: toLoc(yyloc) } }
  | TAG_NAME ATTRS_BLOCK THEREST
  { $$ = { tag: $TAG_NAME, attrs: $ATTRS_BLOCK, val: $THEREST, loc: toLoc(yyloc) } }
  | TAG_NAME THEREST
  { $$ = { tag: $TAG_NAME, val: $THEREST, loc: toLoc(yyloc) } }
  | THEREST
  { $$ = { something: $THEREST, loc: toLoc(yyloc) } }
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
    console.log(arguments[0] + ' is not enabled')
  }
}

parser.main = function (args) {
  lexer.options.post_lex = function(l) {
      console.log(parser.getSymbolName(l))
      // console.log(parser.describeSymbol(l))
  }
     if (!args[1]) {
        console.log('Usage:', path.basename(args[0]) + ' FILE');
        process.exit(1);
    }
    filename = args[1]
    var source = fs.readFileSync(path.normalize(args[1]), 'utf8');
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