/* simple parser */

/* lexical grammar */
%lex

word         [a-zA-Z]+
number       [0-9]+
space        [ ]+
other        [^a-zA-Z0-9 \n]+ // must put it as "not", but I don't know why

%%

{word}       return 'WORD';
{number}     return 'NUMBER';
{other}      return 'OTHER';
{space}      return 'SPACE';
<<EOF>>      return 'ENDOFFILE';
\n           ; // ignore newlines

/lex

%% 

/* language grammar */

start
  : ENDOFFILE
  { console.log("empty string"); $$ = [] }
  | list ENDOFFILE
  { console.log("list ENDOFFILE", $1); $list = [] }
  ;

list
  : list token
  { $list.push($token); $$ = $list; }
  | token
  { $$ = [$token]; }
  ;

token
  : WORD
  { console.log("WORD=%s", $$); }
  | NUMBER 
  { console.log("NUMBER=%s", $$); $$ = parseInt($$) }
  | OTHER
  | SPACE
  { console.log("SPACE=%s", $$); }
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

  test('', [])

  test('abc', [ 'abc' ])

  test('123', [123])

  test('abc 123', ['abc',' ', 123])

  test('!@#$%^&*()_+-=[]\;\',./<>?:"{}|', [`!@#$%^&*()_+-=[];',./<>?:"{}|`])

  test("abc\n123", ['abc', 123])


};
