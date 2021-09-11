/* simple parser */

/* lexical grammar */
%lex

dot     [^\n()]+
// number       [0-9]+
space			[\t \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]
// other        [^a-zA-Z0-9 \n]+ 

%%

\n          return 'NEWLINE';
(extends|append|block|-)  return 'KEYWORD';
'('       return 'LPAR';
')'     return 'RPAR';
(script)  return 'TAG';
{space}   return 'SPACE';
{dot}      return 'ANYTHING';
<<EOF>>      return 'ENDOFFILE';

/lex

%% 


/* language grammar */

start
  : lines ENDOFFILE
  { console.log('lines ENDOFFILE', $$);  $lines = []  }
  ;

lines
  : lines line
  { $lines.push($line); $$ = $lines; console.log('lines line: ', $lines);  }
  | line
  { console.log('line', $$);  $$ = [$line]  }
  // { console.log('line NEWLINE', $$) }
  ;

line
  : KEYWORD
  { console.log('KEYWORD', $$); $$ = {type:'KEYWORD', value:$$} }
  | TAG
  { console.log('TAG', $$); $$ = {type:'TAG', value:$$} }
  | TAG LPAR ANYTHING RPAR
  { console.log('TAG', $$); $$ = {type:'TAG', value:$$} }
  | NEWLINE
  { $$ = 'NEWLINE' }
  | SPACE
  { $$ = {type:'SPACE', value:$SPACE} }
  | ANYTHING
  { $$ = {type:'ANYTHING', value:$ANYTHING} }
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

var assert = require("assert");

parser.main = function () {

  function test(input, expected) {
    console.log(`\nTesting '${input}'...`)
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
