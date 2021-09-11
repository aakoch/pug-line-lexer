/* simple parser */

/* lexical grammar */
%lex
// probably needs changed:
valid_path_section [a-zA-Z0-9]+
valid_block_name [a-zA-Z0-9]+



anything     [^\n()]+
// number       [0-9]+
space			[\t \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]
// other        [^a-zA-Z0-9 \n]+ 
anything_without_ending_in_space [^\n()]+[\t \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]$
%%

\n          return 'NEWLINE';
block  return 'BLOCK';
\s-  return 'DASH';
extends  return 'EXTENDS';
append  return 'APPEND';
'('       return 'LPAR';
')'     return 'RPAR';
(script|style)  return 'TAG';
{space}   {
  console.log(yylloc)
  if (yylloc.first_column == 0)
    return 'FIRST_SPACE';

  return 'SPACE'
};

// might need to split this out again:
{valid_block_name} return 'COMBO';
// {valid_path_section} return 'DIR';
// {valid_block_name} return 'BLOCK';

\.\.\/   return 'DIR_UP';
\.    return 'DOT';
{anything_without_ending_in_space}      return 'ANYTHING_BUT';
{anything}      return 'ANYTHING';
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
  { console.log('lines line', $lines); $lines.push($line); $$ = $lines; console.log('lines line');  }
  | line
  { console.log('line', $$);  $$ = [$line]  }
  // { console.log('line NEWLINE', $$) }
  ;

line
  // works but I don't think a tokenizer should be combining tokens
  // : KEYWORD SPACE rest
  // { console.log('KEYWORD', $$); console.log(this.yy.lexer.yylloc.first_column); $$ = {type:'KEYWORD', keyword:$$, indent:this.yy.lexer.yylloc.first_column - $$.length - 1 - $rest.length, value: $rest} }
  : KEYWORD
  { console.log('KEYWORD', $$, this.yy.lexer.yylloc.first_column); $$ = {type:'KEYWORD', keyword:$$, indent:this.yy.lexer.yylloc.first_column - $$.length - 1} }
  | DASH SPACE javascript
  { console.log('DASH javascript', $$); $$ = {type:'DASH', value:$$, indent:this.yy.lexer.yylloc.first_column} }
  | BLOCK SPACE block_name
  { console.log('BLOCK block_name', $$); $$ = {type:'BLOCK', value:$$, indent:this.yy.lexer.yylloc.first_column} }
  | EXTENDS SPACE path
  { console.log('EXTENDS path', $path);
    $$ = [ {type:'EXTENDS', value:$EXTENDS, indent:this.yy.lexer.yylloc.first_column}, $path]}

  // { console.log('DIR_UP path', $path); $path.push($DIR_UP); $$ = $path }

  | APPEND SPACE block_name
  { console.log('APPEND block_name', $APPEND, $block_name); $$ = [
      {type:'APPEND', value:$APPEND, indent:this.yy.lexer.yylloc.first_column},
      {type:'block_name', value:$block_name, indent:this.yy.lexer.yylloc.first_column}
      
      ]
       }

  | TAG
  { console.log('TAG', $$); $$ = {type:'TAG', value:$$, indent:this.yy.lexer.yylloc.first_column} }
  | TAG LPAR attrs RPAR
  { console.log('TAG*******', $$); $$ = [
      {type:'TAG', value:$TAG, indent:this.yy.lexer.yylloc.first_column},
      {type:'ATTRS', value:$attrs, indent:this.yy.lexer.yylloc.first_column} 
  ]}
  | NEWLINE
  { $$ = {type: 'NEWLINE'} }
  | SPACE
  { $$ = {type:'SPACE', value:$SPACE, indent:this.yy.lexer.yylloc.first_column} }
  | FIRST_SPACE
  { $$ = {type:'FIRST_SPACE', value:$FIRST_SPACE, indent:this.yy.lexer.yylloc.first_column} }
  | DOT
  { $$ = {type:'DOT', value:$DOT, indent:this.yy.lexer.yylloc.first_column} }
  | ANYTHING_BUT
  { $$ = {type:'ANYTHING_BUT', value:$ANYTHING_BUT, indent:this.yy.lexer.yylloc.first_column} }
  | ANYTHING
  { $$ = {type:'ANYTHING', value:$ANYTHING, indent:this.yy.lexer.yylloc.first_column} }
  | catch_all
  { $$ = {type:'catch_all', value:$catch_all, indent:this.yy.lexer.yylloc.first_column} }
  ;

attrs
  : javascript
  | javascript ANYTHING
  ;

javascript
  : COMBO javascript
  | SPACE javascript
  | COMBO
  | SPACE
  ;

block_name
  : COMBO
  | BLOCK
  ;

path
  : path DIR_UP
  { console.log('DIR_UP path', $path); $path.push({type:'DIR_UP', value:$DIR_UP, indent:this.yy.lexer.yylloc.first_column}); $$ = $path }
  | DIR_UP
  { $$ = [{type:'DIR_UP', value:$DIR_UP, indent:this.yy.lexer.yylloc.first_column}] }
  | COMBO
  | DIR
  | PATH
  | ANYTHING_BUT
  ;

catch_all
  : COMBO
  ;
// rest
//   : DOT rest
//   { $$ = $rest; console.log('DOT rest');  }
//   | ANYTHING rest
//   { $$ = $rest; console.log('ANYTHING rest');  }
//   | DOT
//   | ANYTHING
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

parser.main = function () {

  function test(input, expected) {
    console.log(`\nTesting '${input}'...`)
    var actual = parser.parse(input)
    console.log(input + ' ==> ', JSON.stringify(actual, null, '  '))
    // assert.deepEqual(actual, expected)
  }

  test(`
extends ../../../../templates/blogpost

append variables
  - var title = "Blog title"
  - var posted = '2021-09-08'

block morehead
  script(src='jquery-3.6.0.min.js' integrity='sha256-=' crossorigin='anonymous')
  script(src="/node_modules/../.js")
  
  style.
    #bandwagonLink img {
      vertical-align: top;
    }
  .someclass Some text 
    | more text
`, [])


};
