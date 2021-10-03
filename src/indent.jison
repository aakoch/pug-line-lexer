/* 
*/

%lex

spc  [ \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]

%s text

%%

'| ' %{
  this.pushState('text')
  return 'PIPE_SPACE'
%}

<INITIAL>('a'|'abbr'|'acronym'|'address'|'applet'|'area'|'article'|'aside'|'audio'|'b'|'base'|'basefont'|'bdi'|'bdo'|'bgsound'|'big'|'blink'|'blockquote'|'body'|'br'|'button'|'canvas'|'caption'|'center'|'cite'|'code'|'col'|'colgroup'|'content'|'data'|'datalist'|'dd'|'del'|'details'|'dfn'|'dialog'|'dir'|'div'|'dl'|'dt'|'em'|'embed'|'fieldset'|'figcaption'|'figure'|'font'|'footer'|'form'|'frame'|'frameset'|'h1'|'head'|'header'|'hgroup'|'hr'|'html'|'i'|'iframe'|'image'|'img'|'input'|'ins'|'kbd'|'keygen'|'label'|'legend'|'li'|'link'|'main'|'map'|'mark'|'marquee'|'math'|'menu'|'menuitem'|'meta'|'meter'|'nav'|'nobr'|'noembed'|'noframes'|'noscript'|'object'|'ol'|'optgroup'|'option'|'output'|'p'|'param'|'picture'|'plaintext'|'portal'|'pre'|'progress'|'q'|'rb'|'rp'|'rt'|'rtc'|'ruby'|'s'|'samp'|'script'|'section'|'select'|'shadow'|'slot'|'small'|'source'|'spacer'|'span'|'strike'|'strong'|'style'|'sub'|'summary'|'sup'|'svg'|'table'|'tbody'|'td'|'template'|'textarea'|'tfoot'|'th'|'thead'|'time'|'title'|'tr'|'track'|'tt'|'u'|'ul'|'var'|'video'|'wbr'|'xmp')\b return 'TAG_NAME'

(?!^\s{2,})[^\r\n]+ %{
  if (yytext[0] == ' ')
    yytext = yytext.substring(1)
  return 'THEREST'
%}

[\r\n]+ %{
  this.popState()
%};

\s*<<EOF>>		%{
  // remaining DEDENTs implied by EOF, regardless of tabs/spaces
  var tokens = [];
  while (0 < stack[0]) {
    this.popState();
    tokens.unshift("DEDENT");
    stack.shift();
  }
  tokens.unshift("ENDOFFILE")
    
  if (tokens.length) 
    return tokens;
%}

^{spc}*$		/* remove blank lines */

^({spc}{spc}|\t)+  %{
  var indentation = yyleng - yytext.search(/\s/) - 1;

  if (util.isArray(stack[0]) ?  indentation > stack[0][1] : indentation > stack[0]) {
    stack.unshift(util.isArray(stack[0]) ? ['text', indentation] : indentation);
    return 'INDENT';
  }

  var tokens = [];

  while (util.isArray(stack[0]) ?  indentation < stack[0][1] : indentation < stack[0]) {
    this.popState();
    tokens.unshift("DEDENT");
    stack.shift();
  }
  if (tokens.length) {
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

parser.main = function (args) {
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