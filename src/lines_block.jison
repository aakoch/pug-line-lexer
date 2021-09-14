/* simple parser */

/* lexical grammar */
%lex

dot     [^\n ]+
// number       [0-9]+
space			[\t \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]
// other        [^a-zA-Z0-9 \n]+ 

%%

// ^space$       ;
// {space}*  {
//   // console.log("yylloc.first_column", yylloc.first_column); 
//   // console.log("indentStack", indentStack); 

//   // if (yylloc.first_column > indentStack[0]) {
//   //   console.log('unshifting');
//   //   indentStack.unshift(yylloc.first_column)
//   //   console.log("indentStack is now", indentStack); 
//   // }
//   // else {
//   //   console.log('shifting');
//   //   indentStack.shift(0)
//   //   console.log("indentStack is now", indentStack); 
//   // }
//   console.log("yytext", yy_.text)
//   return 'INDENT';
// }
$^ return 'ENDOFFILE';
<INITIAL>\s*<<EOF>>		%{
  // remaining DEDENTs implied by EOF, regardless of tabs/spaces
  var tokens = [];

  while (0 < indentStack[0]) {
    this.popState();
    tokens.unshift("DEDENT");
    indentStack.shift();
  }
    
  if (tokens.length) return tokens;
%}
[\n\r]+{space}*/![^\n\r]		/* eat blank lines */
<INITIAL>[\n\r]{space}*		%{
  var indentation = yyleng - yytext.search(/\s/) - 1;
  if (indentation > indentStack[0]) {
    indentStack.unshift(indentation);
    console.log('returning INDENT')
    return 'INDENT';
  }

  var tokens = [];

  while (indentation < indentStack[0]) {
    this.popState();
    tokens.unshift("DEDENT");
    indentStack.shift();
  }
  if (tokens.length) return tokens;
%}

\n      ;//    return 'NEWLINE';
{dot}      return 'BLOCK';
<<EOF>>      return 'ENDOFFILE';

/lex

%% 




start
	: ENDOFFILE
  { $$ = [] }
	| proglist ENDOFFILE
	// { console.log("AST: %j", $proglist); }
	;

proglist
	: proglist group
	{ 
    console.log("proglist group", $proglist, $group); 
    // $proglist.unshift($group); 
    // $proglist[0].children = $group;
    // $proglist.children = $group
    $proglist.push($group)
    $$ = $proglist;
    console.log('$$ is now', $$)
   }
   | group
  // | proglist BLOCK
	// { 
  //   console.log("proglist BLOCK", $proglist, $BLOCK); 
  //   // $proglist.unshift($group); 
  //   // $proglist[0].children = $group;
  //   // $proglist.children = $group
  //   $proglist.push({ indent: indentStack[0], value: $BLOCK })
  //   $$ = $proglist;
  //   console.log('$$ is now', $$)
  //  }
	;


group
  : INDENT
  { console.log('INDENT', indentStack); }
  | INDENT BLOCK
	{ console.log('INDENT BLOCK', indentStack); 
  $$ = [{ indent: indentStack[0], value: $BLOCK }]; 
    console.log('$$ is now', $$)}
	| BLOCK
	{ console.log("BLOCK", $BLOCK); $$ = [{ indent: 0, value: $BLOCK }]; }
  | proglist BLOCK
	{ 
    console.log("proglist BLOCK", $proglist, $BLOCK); 
    // $proglist.unshift($group); 
    // $proglist[0].children = $group;
    // $proglist.children = $group
    $proglist.push({ indent: indentStack[0], value: $BLOCK })
    $$ = $proglist;
    console.log('$$ is now', $$)
   }
  ;

// if_stmt
// 	: IF LPAREN expr RPAREN COLON stmt_block
// 	{ $$ = [ "if", $expr, $stmt_block ]; }
// 	| IF LPAREN expr RPAREN COLON stmt_block ELSE COLON stmt_block
// 	{ $$ = [ "if", $expr, $6, $9 ]; }
// 	;

// print_stmt
// 	: PRINT STRING
// 	{ $$ = ["print", $2]; }
// 	;

// stmt
// 	: if_stmt
// 	| print_stmt
//   | BLOCK
//   // { $$ = "hey" }
// 	;

stmt_list
	: stmt
	{ $$ = ["stmt_list", $stmt]; }
	| stmt_list stmt
	// { $stmt_list.push({ stmt: $stmt, indent: indentStack[0]}); $$ = $stmt_list; }
	{ $stmt_list.push($stmt); $$ = $stmt_list; }
	;

// stmt_block
// 	: INDENT stmt_list DEDENT
// 	{ $$ = $stmt_list; }
// 	;

atom
	: ID
	{ $$ = ["id", $1]; }
	| NATLITERAL
	{ $$ = ["natlit", $1]; }
	| LPAREN expr RPAREN
	{ $$ = ["expr", $2]; }
	;

expr
	: atom
	| expr PLUS atom
	{ $expr.push(["plus", $atom]); $$ = $expr; }
	| expr MINUS atom
	{ $expr.push(["minus", $atom]); $$ = $expr; }
	;





// /* language grammar */

// start
//   : ENDOFFILE
//   { $$ = []; }
//   | BLOCK ENDOFFILE
//   { $$ = [{value: $BLOCK, indent: 0}]  }
//   | BLOCK group ENDOFFILE
//   { console.log('BLOCK group ENDOFFILE=', $BLOCK, $group, 'EOF'); 
//   //$$ = [{value: $BLOCK, indent: 0}, $indent_block] 
//     // $$ = [$group];
//     $$ = [{value: $BLOCK1, indent: 0, children: [$group]}]
//   }
//   | BLOCK group_list ENDOFFILE
//   { console.log('BLOCK group_list ENDOFFILE=', $BLOCK, $group_list, 'EOF'); 
//   //$$ = [{value: $BLOCK, indent: 0}, $indent_block] 
//     // $$ = [$group];
//     $$ = [{value: $BLOCK1, indent: 0, children: [$group_list]}]
//   }

//   // | BLOCK indent_block_ident indent_block_ident indent_block ENDOFFILE
//   // { 
//   //   console.log('2: BLOCK indent_block_ident indent_block_ident indent_block ENDOFFILE=', $BLOCK, $indent_block_ident1, $indent_block_ident2, $indent_block, 'EOF'); 
//   //   console.log('first_column', yyloc.first_column);
//   //   $indent_block_ident2.push($indent_block[0]); $indent_block_ident1.push($indent_block2); $$ = [$BLOCK1, $indent_block_ident1]  }

//   // | group_list 
//   | group_list ENDOFFILE
//   { console.log("4 group_list", $group_list); $$ = [$group_list]}
//   | group 
//   { console.log("1 group", $group); $$ = $group}
//   ;

// group_list
//   : group group_list
//   { 
//     console.log("3 group", $group, "group_list", $group_list); 
//     console.log("$group_list.indent=", $group_list.indent)
//     console.log("$group.indent=", $group.indent)
//     if ($group_list.indent == $group.indent) {
//       $$ = [$group, $group_list];
//     }
//     else if ($group_list.indent < $group.indent) {
//       $$ = $group_list;
//       console.log('pop indent?')
//     }
//     else {
//       $group.children = [$group_list];
//       $$ = $group;
//     }

//     console.log('returning', $$)
  
//   }
//   | group
//   { console.log("2 group", $group); $$ = $group}
//   // | BLOCK
//   // | group
//   // { console.log("2 group", $group); }
//   ;

// group
//   : indent_list BLOCK  
//   { console.log("1 BLOCK", $BLOCK, "indent_list", $indent_list); $$ = {value: $BLOCK, indent: yyloc.first_column}; }
//   | INDENT BLOCK
//   {  console.log('INDENT BLOCK', $BLOCK); $$ = {value: $BLOCK, indent: yyloc.first_column}; }
//   | BLOCK
//   {  console.log('BLOCK', $BLOCK); $$ = [{value: $BLOCK, indent: yyloc.first_column}]; }
//   ;


// indent_list
//   : INDENT
//   | INDENT indent_list
//   { console.log('INDENT indent_list', $indent_list); $$ = [ $indent_list, $INDENT ]}
//   ;

// indent_block_ident
//   : indent_block INDENT
//   { console.log('indent_block', $indent_block); }
//   ;

// indent_block
//   : INDENT BLOCK
//   { console.log('1: INDENT=%d BLOCK=%s', yyloc.first_column, $BLOCK); 
//     $$ = [{value: $BLOCK, indent: yyloc.first_column}]}

    
//   | indent_block INDENT
//   { 
//     console.log('3: indent_block', $indent_block[0]); 
//     $$ = $indent_block[0];
//   }
  
    
  // | indent_block INDENT indent_block
  // { 
  //   console.log('\nprevIndent', prevIndent);
  //   console.log('prevIndent', prevIndent);
  //   console.log('$$', $$); 
  //   console.log('3: indent_block INDENT indent_block=', $indent_block1, 'INDENT', $indent_block2); 
  //   // console.log('first_column', yyloc.first_column); 
  //   console.log('$indent_block1[0].indent', $indent_block1[0].indent);
  //   console.log('$indent_block2[0].indent', $indent_block2[0].indent);

  //   if ($indent_block1[0].indent == $indent_block2[0].indent) {
  //     console.log('same indentation')
  //     $indent_block1.push($indent_block2[0]); 
  //   }
  //   else {
  //     $indent_block1.push($indent_block2); 
  //   }
  //   console.log('indent_block1', $indent_block1); 
  //   $$ = $indent_block1;
  //   prevIndent = yyloc.first_column  }
  // ;

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
var indentStack = [0];

parser.main = function () {

  function run(input) {
    indentStack = [0]
    console.log(`\n\n****************************\nTesting '${input}'...`)
    var actual = parser.parse(input)
    console.log(' ==> ', JSON.stringify(actual, null, '  '))
    return actual;
  }

  function test(input, expected) {
    let actual = run(input);
    assert.deepEqual(actual, expected)
  }

  test(``, [])

  test(`html`, [{value: 'html', indent: 0}])

  test(`html
  body`, 
  // prefered [ { children: [ { indent: 2, value: 'body' } ], indent: 0, value: 'html' } ]
  [
  {
    indent: 0,
    value: 'html'
  },
  [
    {
      indent: 2,
      value: 'body'
    }
  ]
]
  )

  test(`html
  head
  body`, [ { children: [ { indent: 2, value: 'body' }, { indent: 2, value: 'head' } ], indent: 0, value: 'html' } ])


  test(`html
  body
    div`, [{"value":"html","indent":0,"children":[{"value":"body","indent":2,"children":[{"value":"div","indent":4}]}]} ])


  test(`html
  body
    div
    div2`, [ { children: [ { children: [ [ { indent: 4, value: 'div' }, { indent: 4, value: 'div2' } ] ], indent: 2, value: 'body' } ], indent: 0, value: 'html' } ])

  test(`
html`,  [{value: 'html', indent: 0}])

  run(`html
  head
    link
  body
    div
    div
      div`);

  // test(`html
  // head
  // body
  //   div
  //   div2`, [
  //     {value: 'html', indent: 0},
  //     [
  //       {
  //         indent: 2,
  //         value: 'head'
  //       },
  //       {
  //         indent: 2,
  //         value: 'body'
  //       },
  //       [
  //         {
  //           indent: 4,
  //           value: 'div'
  //         },
  //         {
  //           indent: 4,
  //           value: 'div2'
  //         }
  //       ]
  //     ]
  //   ])


};
