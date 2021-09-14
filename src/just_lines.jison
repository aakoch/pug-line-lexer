/* 
 * This parses out lines. That's it. This was merged with line.jison to create line_combo.jison.
 */

/* lexical grammar */
%lex

dot     [^\n]+

%%

[\n\u000B]         return 'NEWLINE';
{dot}      return 'ANYTHING';
<<EOF>>      return 'ENDOFFILE';

/lex

%% 

/* language grammar */

start
  : lines ENDOFFILE
  ;

lines
  : lines line
  { $lines.push($line); $$ = $lines }
  | line
  { $$ = [$line]  }
  ;

line
  : NEWLINE
  | ANYTHING
  { $$ = {type:'LINE', value:$ANYTHING, loc: toLoc(yyloc)} }
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


function toLoc(yyloc) {
  return {
        end: {
          column: yyloc.last_column + 1,
          line: yyloc.last_line
        },
        start: {
          column: yyloc.first_column + 1,
          line: yyloc.first_line
        }
      
     }
}


var assert = require("assert");

parser.main = function () {

  function test(input, expected) {
    var actual = parser.parse(input)
    console.log(input + ' ==> ', JSON.stringify(actual))
    // assert.deepEqual(actual, expected)
  }

  test(`extends ../../../../templates/blogpost

append variables
  - var title = "Moving off Wordpress and on to Netlify"
  - var posted = '2021-09-08'

block morehead
  script(src='https://code.jquery.com/jquery-3.6.0.min.js' integrity='sha256-/xUj+3OJU5yExlq6GSYGSHk7tPXikynS7ogEvDej/m4=' crossorigin='anonymous')
  script(src="/node_modules/jquerykeyframes/dist/jquery.keyframes.min.js")
  
  style.
    #bandwagonLink img {
      vertical-align: top;
    }
  .someclass
`, [])


};
