/* simple parser */

/* lexical grammar */
%lex

word         [a-zA-Z]+
number       [0-9]+
space			[\t \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]
other        [^a-zA-Z0-9 \n]+ 

%%

(mixin|include)        return 'KEYWORD';
{word}       return 'WORD';
{number}     return 'NUMBER';
'('             return 'LPAREN';
')'             return 'RPAREN';
{other}      return 'OTHER';
{space}      return 'SPACE';
<<EOF>>      return 'ENDOFFILE';
\n           return 'NEWLINE'; // ignore newlines

/lex

%% 


/* language grammar */

start
  : ENDOFFILE
  { $$ = [] }
  | list ENDOFFILE
  { $list = [] }
  ;

list
  : list token
  { $list.push($token); $$ = $list; }
  | line
  { $list.push($token); $$ = $list; }
  | token
  { $$ = [$token]; }
  ;

line
  : LPAREN token RPAREN
  ;

token
  : WORD
  { $$ = { type: 'tag', name: $WORD } }
  | NUMBER 
  { $$ = parseInt($$) }
  | OTHER
  | SPACE
  { $$ = 'SPACE' }
  | KEYWORD
  | NEWLINE
  { $$ = 'NEWLINE' }
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
    assert.deepEqual(actual, expected)
  }

  test('html', [{ type: 'tag', name: 'html' }])


};
