/* 
*/

%lex

spc  [ \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]

%%

(?!^\s+)[^\r\n]+ return 'THEREST'

[\r\n]+ ;

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
	: lines ENDOFFILE
	;

lines
  : lines INDENT lines DEDENT
  { $lines1.push($lines2); $$ = $lines1 }
  | INDENT lines DEDENT
  { $$ = $lines }
  | lines stmt
  { $lines.push($stmt); $$ = $lines }
  | stmt
  { $$ = [$stmt] }
  ;

// line
// 	:  
// 	| INDENT lines DEDENT
//   | THEREST
// 	;

// block
// 	: INDENT line+ DEDENT
// 	;

stmt
  : THEREST
  { $$ = { val: $THEREST } }
  ;

// the_rest
//   : THEREST
//   ;

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
var location = false;

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