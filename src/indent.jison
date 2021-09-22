%lex

id			[a-zA-Z_][a-zA-Z0-9_]*
spc			[\t \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]


%%


'{'   return 'OCURL'; // open curly brace
'}'   return 'CCURL'; // close curly brace
.+   return 'ID';
<<EOF>>				return "ENDOFFILE";
<INITIAL>\s*<<EOF>>		%{
  // remaining DEDENTs implied by EOF, regardless of tabs/spaces
  var tokens = [];

  while (0 < stack[0]) {
    this.popState();
    tokens.unshift("DEDENT");
    stack.shift();
  }
    
  if (tokens.length) return tokens;
%}
[\n\r]+{spc}*/![^\n\r]		/* eat blank lines */
<INITIAL>[\n\r]({spc}{spc}|\t)+		%{
  var indentation = yyleng - yytext.search(/\s/) - 1;
  if (indentation > stack[0]) {
    stack.unshift(indentation);
    return 'INDENT';
  }

  var tokens = [];

  while (indentation < stack[0]) {
    this.popState();
    tokens.unshift("DEDENT");
    stack.shift();
  }
  if (tokens.length) return tokens;
%}
{spc}+				/* ignore all other whitespace */
[\n] ; 
/lex


%options token-stack

%%

start
	: line ENDOFFILE
	{ console.log("AST: %j", $line); }
	;

line
	: line stmt
	{ $line.push($stmt); $$ = $line; }
	| stmt
	{ $$ = [$stmt]; }
	;

stmt
  : keyword
  | punct
  | block
	;

keyword
  : ID
  { $$ = { type: 'TAG', val: $ID, loc: toLoc(yyloc) } }
  ;

punct
  : OCURL
  { $$ = { type: 'OPEN_CURLY_BRACE', loc: toLoc(yyloc) } }
  | CCURL
  { $$ = { type: 'CLOSE_CURLY_BRACE', loc: toLoc(yyloc) } }
  ;

stmt_list
	: stmt
	{ $$ = [$stmt] }
	| stmt_list stmt
	{ $stmt_list.push($stmt); $$ = $stmt_list; }
	;

block
	: INDENT stmt_list DEDENT
	{ $$ = $stmt_list; }
	;

%% 

var stack = [0];

function toLoc(yyloc) {
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
}

var filename;
var stripDown = false;

var util = require('util')

function strip(arr) {
  return arr
    .filter(el => {
      return util.isArray(el) || el.val
    })
    .map(el => {
      if (util.isArray(el)) {
        return strip(el);
      }
      return el.val
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