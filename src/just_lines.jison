/* 
 * This parses out lines. That's it. This was merged with line.jison to create line_combo.jison.
 */

/* lexical grammar */
%lex

dot     [^\n ]
space			[ \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]

%%

[\n\u000B]+         return 'NEWLINE';
{dot}+      return 'ANYTHING';
{space}+     return 'SPACES';
<<EOF>>      return 'ENDOFFILE';

/lex

%ebnf

%options token-stack

%% 

/* language grammar */

start
  : lines ENDOFFILE
  ;

lines
  // : lines line
  // { $lines.push($line); $$ = $lines }
  : line+
  ;

line
  : NEWLINE
  | SPACES ANYTHING
  {  
    // console.log(lexer.describeYYLLOC())
    console.log(lexer.unput("SPACES"))
    $$ = $ANYTHING
  }
  | ANYTHING
  // { $$ = {type:'LINE', value:$ANYTHING} }
  ;

%% 


// feature of the GH fork: specify your own main.
//
// compile with
// 
//      jison -o test.js --main path/to/simple.jison
//
// then run
//
//      node ./test.js
//
// to see the output.
var stack = [0];
location = false

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