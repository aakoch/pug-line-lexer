/* simple parser */

/* lexical grammar */
%lex

not_newline     [^\n ]
// number       [0-9]+
space			[ \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]
// other        [^a-zA-Z0-9 \n]+ 

%%


({space}{space}|\t)+
%{
  // debug('lex.__all__.spc_spc', yy)
  const indentation3 = yytext.length
  debug('lex.__all__.spc_spc', 'yytext=>' + yytext.replaceAll(' ', '·') + '<=, yytext.length=' + indentation3 + (indentation3 < stack[0] ? ' <' : ' >=') + ' stack[0]=' + stack[0]);

  if(indentation3 > stack[0]) {
    stack.unshift(indentation3)
    debug('returning INDENT')
    return 'INDENT'
  }

  let tokens3 = []

  while (indentation3 < stack[0]) {
    tokens3.unshift("DEDENT");
    stack.shift();
  }
  
  this.popState()
  this.popState()

  if (tokens3.length) {
    debug('returning ' + tokens)
    return tokens3;
  }
%}


\s*<<EOF>>		%{
  // remaining DEDENTs implied by EOF, regardless of tabs/spaces
  return cleanEof.apply(this)
%}	

\n          return 'NEWLINE';
(?!{space}+|\t){not_newline}+      return 'ANYTHING';
<<EOF>>      return 'ENDOFFILE';

/lex

%ebnf

%options token-stack

%% 
/* language grammar */

start
  : line+ ENDOFFILE
  ;

line
  : ANYTHING (NEWLINE|ENDOFFILE)?
  { debug('lex.line.ANYTHING NEWLINE'); }
  | INDENT ANYTHING (NEWLINE|ENDOFFILE)?
  { $$ = ['INDENT', $ANYTHING]; }
  | DEDENT ANYTHING (NEWLINE|ENDOFFILE)?
  { $$ = ['DEDENT', $ANYTHING]; }
  ;

%% 
var stack = [0];


function cleanEof() {
  resetState.apply(this);

  var tokens = [];
  while (0 < stack[0]) {
    tokens.unshift("DEDENT");
    stack.shift();
  }
    
  tokens.unshift('ENDOFFILE')
  return tokens;
}

function resetState() {
  while (this.topState() != 'INITIAL') {
    this.popState()
  }
}


function debug() {
  
    console.log(arguments[0], ...Array.from(arguments).slice(1))
}


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

// var assert = require("assert");

// parser.main = function () {

//   function test(input, expected) {
//     console.log(`\nTesting '${input}'...`)
//     var actual = parser.parse(input)
//     console.log(input + ' ==> ', JSON.stringify(actual))
//     // assert.deepEqual(actual, expected)
//   }

//   test(`extends ../../../../templates/blogpost

// append variables
//   - var title = "Moving off Wordpress and on to Netlify"
//   - var posted = '2021-09-08'

// block morehead
//   script(src='https://code.jquery.com/jquery-3.6.0.min.js' integrity='sha256-/xUj+3OJU5yExlq6GSYGSHk7tPXikynS7ogEvDej/m4=' crossorigin='anonymous')
//   script(src="/node_modules/jquerykeyframes/dist/jquery.keyframes.min.js")
  
//   style.
//     #bandwagonLink img {
//       vertical-align: top;
//     }
//   .someclass
// `, [])


// };
