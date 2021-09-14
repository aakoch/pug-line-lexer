/* simple parser */

/* lexical grammar */
%lex

dot     [^\n ]+
// number       [0-9]+
space			[\t \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]
// other        [^a-zA-Z0-9 \n]+ 

%%

^space$       ;
{space}{space}   return 'INDENT';
\n      ;//    return 'NEWLINE';
{dot}      return 'BLOCK';
<<EOF>>      return 'ENDOFFILE';

/lex

%% 


/* language grammar */

start
  : ENDOFFILE
  { $$ = []; }
  | BLOCK ENDOFFILE
  { console.log('BLOCK ENDOFFILE', $$);  $$ = [$BLOCK]  }
  // | BLOCK
  // { console.log('BLOCK ENDOFFILE', $$);  $lines = []  }
  | BLOCK indent_block ENDOFFILE
  { console.log('INDENT ENDOFFILE', $$);  $$ = [$BLOCK1, $indent_block] }
  | BLOCK indent_block INDENT indent_block ENDOFFILE
  { console.log('INDENT ENDOFFILE', $$); $indent_block1.push($indent_block2); $$ = [$BLOCK1, $indent_block1]  }
  | BLOCK indent_block INDENT indent_block INDENT indent_block ENDOFFILE
  { console.log('INDENT ENDOFFILE', $$); $indent_block2.push($indent_block3[0]); $indent_block1.push($indent_block2); $$ = [$BLOCK1, $indent_block1]  }
  ;

indent_block
  : INDENT BLOCK
  { $$ = [$BLOCK] }
  // | indent_block INDENT BLOCK
  // { $indent_block.push($BLOCK); $$ = $indent_block }
  ;

block
  // : INDENT block
  // { $block.push($$); console.log('indent block: ', $$);  }
  : block
  { console.log('block', $block);  }
  | INDENT
  { console.log('INDENT', $INDENT);  }
  | ANYTHING
  { console.log('ANYTHING', $ANYTHING);  }
  | NEWLINE
  { console.log('NEWLINE', $NEWLINE);  }
  | ENDOFFILE
  { console.log('ENDOFFILE', $ENDOFFILE);  }
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
    assert.deepEqual(actual, expected)
  }

  test(``, [])

  test(`html`, ['html'])

  test(`html
  body`, ['html', ['body']])


  test(`html
  body
    div`, ['html', ['body', ['div']]])


  test(`html
  body
    div
    div2`, ['html', ['body', ['div', 'div2']]])


};
