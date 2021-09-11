/* simple parser */

/* lexical grammar */
%lex

letter      [a-zA-Z]{1}
digit       [0-9]{1}
other       .{1}

%%

{letter}                  return 'LETTER';
{digit}                   return 'DIGIT';
{other}                   return 'OTHER';
<<EOF>>                   return 'ENDOFFILE';
\n                        return 'NEWLINE';

/lex

%% 

/* language grammar */

start
  : ENDOFFILE
  { console.log('empty string'); $$ = [] }
  | list ENDOFFILE
  { $list = [] }
  ;

list
  : list token
  { $list.push($token);  $$ = $list; }
  | token
  { $$ = [$token]; }
  ;

token
  : LETTER
  { console.log('LETTER=%s', $$); }
  | DIGIT 
  { console.log('DIGIT=%s', $$); $$ = parseInt($$) }
  | OTHER
  | NEWLINE
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

var assert = require('assert');

parser.main = function () {

  function test(input, expected) {
    console.log(`\nTesting '${input}'...`)
    var actual = parser.parse(input)
    console.log(input + ' ==> ', JSON.stringify(actual))
    assert.deepEqual(actual, expected)
  }

  test('', [])

  test('abc', [ 'a', 'b', 'c' ])

  test('123', [1, 2, 3])


  test('abc 123', ['a','b','c',' ', 1, 2, 3])

  test('!@#$%^&*()_+-=[]\;\',./<>?:"{}|', ['!','@','#','$','%','^','&','*','(',')','_','+','-','=','[',']',';',"'",',','.','/','<','>','?',':','"','{','}','|'])

};
