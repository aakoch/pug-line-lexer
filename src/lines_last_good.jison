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
  { $$ = [{value: $BLOCK, indent: 0}]  }
  | BLOCK indent_block ENDOFFILE
  { console.log('BLOCK indent_block ENDOFFILE=', $BLOCK, 'INDENT', 'EOF'); 
  $$ = [{value: $BLOCK, indent: 0}, $indent_block] }
  ;

indent_block_ident
  : indent_block INDENT
  ;

indent_block
  : INDENT BLOCK
  { console.log('1: INDENT=%d BLOCK=%s', yyloc.first_column, $BLOCK); 
    console.log('first_column', yyloc.first_column); 
    $$ = [{value: $BLOCK, indent: yyloc.first_column}]}
  // | indent_block INDENT BLOCK
  // { 
  //   console.log('2: indent_block INDENT BLOCK', $indent_block, 'INDENT', $BLOCK); 
  //   console.log('yylloc', yyloc); 
  //   $indent_block.push(BLOCK); 
  //   $$ = $indent_block  }
  | indent_block INDENT indent_block
  { 
    console.log('\nprevIndent', prevIndent);
    console.log('prevIndent', prevIndent);
    console.log('$$', $$); 
    console.log('3: indent_block INDENT indent_block=', $indent_block1, 'INDENT', $indent_block2); 
    // console.log('first_column', yyloc.first_column); 
    console.log('$indent_block1[0].indent', $indent_block1[0].indent);
    console.log('$indent_block2[0].indent', $indent_block2[0].indent);

    let temp
    if ($indent_block1[0].indent == $indent_block2[0].indent) {
      console.log('same indentation')
      // $indent_block1.push($indent_block2[0]); 
      temp = [ $indent_block1, $indent_block2 ].flat()
    }
    else {
      console.log('different indentation');
      $indent_block1.push($indent_block2); 
      temp = $indent_block1
    }
    console.log('temp', temp); 
    $$ = temp;
    prevIndent = yyloc.first_column  }
  | BLOCK
  {
    console.log('BLOCK', $BLOCK); 
    $$ = [{value: $BLOCK, indent: yyloc.first_column }];
  }
  ;

// block
//   // : INDENT block
//   // { $block.push($$); console.log('indent block: ', $$);  }
//   : block
//   { console.log('block', $block);  }
//   | INDENT
//   { console.log('INDENT', $INDENT);  }
//   | ANYTHING
//   { console.log('ANYTHING', $ANYTHING);  }
//   | NEWLINE
//   { console.log('NEWLINE', $NEWLINE);  }
//   | ENDOFFILE
//   { console.log('ENDOFFILE', $ENDOFFILE);  }
//   // { console.log('line NEWLINE', $$) }
//   ;

// line
//   : KEYWORD
//   { console.log('KEYWORD', $$); $$ = {type:'KEYWORD', value:$$} }
//   | TAG
//   { console.log('TAG', $$); $$ = {type:'TAG', value:$$} }
//   | TAG LPAR ANYTHING RPAR
//   { console.log('TAG', $$); $$ = {type:'TAG', value:$$} }
//   | NEWLINE
//   { $$ = 'NEWLINE' }
//   | SPACE
//   { $$ = {type:'SPACE', value:$SPACE} }
//   | ANYTHING
//   { $$ = {type:'ANYTHING', value:$ANYTHING} }
//   ;

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
var prevIndent = 0;

parser.main = function () {

  function test(input, expected) {
    console.log(`\n\n****************************\nTesting '${input}'...`)
    var actual = parser.parse(input)
    console.log(' ==> ', JSON.stringify(actual))
    assert.deepEqual(actual, expected)
  }

  test(``, [])

  test(`html`, [{value: 'html', indent: 0}])

  test(`html
  body`, [{value: 'html', indent: 0}, [ { indent: 2, value: 'body' }]])


  test(`html
  body
    div`, [ {value: 'html', indent: 0}, [ { indent: 2, value: 'body' }, [ { indent: 4, value: 'div' } ] ] ])


  test(`html
  body
    div
    div2`, [
  {value: 'html', indent: 0},
  [
    {
      indent: 2,
      value: 'body'
    },
    [
      {
        indent: 4,
        value: 'div'
      },
      {
        indent: 4,
        value: 'div2'
      }
    ]
  ]
])

  test(`html
  head
  body
    div
    div2`, [
  {value: 'html', indent: 0},
  [
    {
      indent: 2,
      value: 'head'
    },
    {
      indent: 2,
      value: 'body'
    },
    [
      {
        indent: 4,
        value: 'div'
      },
      {
        indent: 4,
        value: 'div2'
      }
    ]
  ]
])


};
