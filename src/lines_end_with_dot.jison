/* TODO: Fix parsing of head.pug - line 48 is commented and indentation is wrong and the start of the if statement on 46 doesn't work */

%lex

end			.+\.
spc			[ \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]
newline [\n\r]
rest    .+

%x TEXT

%%

{end}  %{ console.log('end') %}
					var indentation = yytext.search(/\w/);
          console.log('indentation=' + indentation + ', yyleng=' + yyleng + ', yytext.search(/\\s/)=' + yytext.search(/\s/)); 
          indent=indentation; 
          this.pushState('TEXT'); 
          return 'END';
<INITIAL>{rest}   console.log('rest'); return 'REST';
{newline}   console.log('newline, lexer.token=' + lexer.token);
<<EOF>> return 'ENDOFFILE'

<TEXT>({spc}{spc}|\t)   %{ console.log('indent') %};
<TEXT>{newline} %{ console.log('newline, this.token=' + util.inspect(this));%}
// <TEXT>{rest}  if (yylloc.first_column < indent) this.popState('TEXT'); return 'TEXT';
<TEXT>.+ %{
  console.log('indent=' + indent + ', first_column=' + yylloc.first_column + ', yytext=' + yytext); 
  if(yylloc.first_column <= indent) {
    if (yytext.endsWith('.')) {
      return 'END'
    }
    else {
      // log('yytext=' + yytext)
      this.popState('TEXT'); 
      return 'REST'
    }
    // lexer.reject()
    // lexer.setInput(yytext)
    // lexer.clear()
  }
  else {
    return 'TEXT'
  }
%}
<TEXT><<EOF>> return 'ENDOFFILE'

/lex

%ebnf

%options token-stack

%%

start
	: lines ENDOFFILE
	{ console.log('getSymbolName', parser.getSymbolName()); log("AST: %j", $lines); }
	;

lines
  : lines line
  { log('lines: lines line'); $lines.push($line); $$ = $lines; log($lines) }
  | line
  { $$ = [$line] }
  | line ENDOFFILE
  { $$ = [$line] }
  // | line ENDOFFILE
  // | block
  ;


line
	// : line stmt
	// { log('line: line stmt'); $line.push($stmt); $$ = $line; }
	: END 
  { log('END=', $END); $$ = $END + ".............." }
	| REST
  { log('REST=', $REST); }
  | TEXT
  { log('TEXT=', $TEXT); $$ = "this is text>>> " + $TEXT }
  | INDENT
  { log('INDENT=', $INDENT); $$ = null}
	;



%% 

var indent = 0;
var stack = [0];

var util = require('util')

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

var isText = false;
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
 parser.lexer.options.backtrack_lexer = true;

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