/* 
 * This parses ONLY lines. Any newline is rejected. It looks for indentations and everything else. This was merged with just_lines.jison to create line_combo.jison.
 */

/* lexical grammar */
%lex

dot     [^\n]+
space			[ \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]

%%

'|'             return 'PIPE';
[\n]          ;
(html|head|body|menu)   return 'KEYWORD';
<<EOF>>      return 'ENDOFFILE';
<INITIAL>\s*<<EOF>>		%{
					// remaining DEDENTs implied by EOF, regardless of tabs/spaces
					var tokens = [];
				
        // log('$$', $$)
        debug('1 stack before', stack)
        while (0 < stack[0]) {
          this.popState();
          tokens.unshift("DEDENT");
          stack.shift();
        }
        debug('1 stack after', stack)
        debug('1 tokens', tokens)
				    
        // tokens.unshift('INDENT')

        // return "DEDENT"
        if (tokens.length) return tokens;
				%}
[\n\r]+{space}*/![^\n\r]		/* eat blank lines */
// ^({space}{space}|\t)  %{
<INITIAL>^({space}{space}|\t)		%{
            debug('\n>>>>>>\n2 yyleng', yyleng)
            // console.log('yystate', yy.parser.terminals_[yy.parser.yystate]);
            // log('yy.lexer.conditionStack', yy.lexer.conditionStack); 
            // debug('2 yytext', yytext)
            // debug('2 yytext.search(/\\s/)', yytext.search(/\s/))
            var indentation = yyleng; //yyleng - yytext.search(/\s/) ;
            debug('2 indentation', indentation)


            // debug('2 stack before', stack)

            if (indentation > stack[0]) {
              debug('2 adding INDENT')
              stack.unshift(indentation);
              return 'INDENT';
            }

            debug('2 not adding INDENT.. DEDENT?')

            var tokens = [];

            while (indentation < stack[0]) {
              console.log('popState', this.popState());
              tokens.unshift("DEDENT");
              debug('2 adding DEDENT')
              stack.shift();
            }

            debug('2 stack after', stack)
            debug('2 tokens', tokens)
            if (tokens.length == 1) 
              return tokens;
            // else 
            //   $$ = ['dedents', 'DEDENT']
				%}
{dot}      return 'ANYTHING';

/lex

// %options token-stack

%% 

/* language grammar */

start
  // : ENDOFFILE
  // { $$ = [] }
  : lines ENDOFFILE
  { $$ = $lines }
  ;

lines
  // TODO: figure out the differences between these 2
  // : line line
  // { $$ = [$line1, $line2] }
  : lines line
  { console.info('lines line', $lines, $line); $lines[$lines.length - 1].children.push($line); $$ = $lines }
  // | line lines
  // { $lines.push($line); $$ = $lines }

	// | INDENT lines DEDENT
	// { $$ = $stmt_list; }

  // | lines INDENT line DEDENT
  // { console.log('INDENT lines DEDENT'); 
  // // $lines.push('INDENT'); $lines.push('DEDENT');
  // $$ = [ {type:'INDENT'} , $lines, {type:'DEDENT'}] }

  | line
  { console.log('line', $line); $$ = [$line] }
  ;

line

  : PIPE
  { $$ = {type:'PIPE', loc: toLoc(yyloc)} }
  | indents ANYTHING
  | indents KEYWORD
  | KEYWORD
  { $$ = {type:'KEYWORD', val: $KEYWORD, loc: toLoc(yyloc), children: []} }
  | ANYTHING
  { $$ = {type:'NOT_INDENT', val: $ANYTHING, loc: toLoc(yyloc)} }
  | DEDENT
  { $$ = {type:'DEDENT'} }
  ;

indents
  : indents INDENT
  | INDENT
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
        start: {
          line: yyloc.first_line,
          column: yyloc.first_column + 1
        },
        end: {
          line: yyloc.last_line,
          column: yyloc.last_column + 1
        }
     }
}

/** 
 * Runtime variables. Don't comment them out. Again.
 */
var stack = [0];
const jsonIndentLevel = process.env.DEBUG ? 0 : 0;

  // console.log(process.env)
function log(...objs) {
  // if (process.env.DEBUG) {
    console.log(...objs)
  // }
}
function debug(...objs) {
  if (process.env.DEBUG) {
    console.debug(...objs)
  }
}


/* * Test vars below * */

var assert = require("assert");
const util = require('util');

// import assert from 'assert'
// import util from 'util'

// parser.main = function (args) {
//   if (!args[1]) {
//       console.log('Usage:', path.basename(args[0]) + ' FILE');
//       process.exit(1);
//   }
//     var source = fs.readFileSync(path.normalize(args[1]), 'utf8');
//     var dst = exports.parser.parse(source);
//     console.log('parser output:\n\n', {
//         type: typeof dst,
//         value: dst
//     });
//     try {
//         console.log("\n\nor as JSON:\n", JSON.stringify(dst, null, 2));
//     } catch (e) { /* ignore crashes; output MAY not be serializable! We are a generic bit of code, after all... */ }
//     var rv = 0;
//     if (typeof dst === 'number' || typeof dst === 'boolean') {
//         rv = dst;
//     }
//     return dst;
// }

parser.main = function (args) {
  function test(input, expected) {
    stack = [0];
    log('\n\nTesting...^' + input)
    var actual = parser.parse(input)
    log(' ==> ', JSON.stringify(actual, null, jsonIndentLevel))
    assert.deepEqual(actual, expected)
  }

  test(`
html
  head
  body
    .class
      input
    div
      |
        `, [
    {
      type: 'INDENT',
      val: 2,
      loc: { start: { line: 2, column: 1 }, end: { line: 2, column: 3 } }
    },
    {
      type: 'KEYWORD',
      val: 'html',
      loc: { start: { line: 2, column: 3 }, end: { line: 2, column: 7 } }
    },
    {
      type: 'INDENT',
      val: 4,
      loc: { start: { line: 3, column: 1 }, end: { line: 3, column: 5 } }
    },
    {
      type: 'NOT_INDENT',
      val: 'head',
      loc: { start: { line: 3, column: 5 }, end: { line: 3, column: 9 } }
    },
    {
      type: 'KEYWORD',
      val: 'body',
      loc: { start: { line: 4, column: 5 }, end: { line: 4, column: 9 } }
    }
  ]);
}
//   test('append variables', [
//   {
//     loc: {
//       end: {
//         column: 17,
//         line: 1
//       },
//       start: {
//         column: 1,
//         line: 1
//       }
//     },
//     type: 'NOT_INDENT',
//     val: 'append variables'
//   }
// ]);


//   test('  - var title = "Moving off Wordpress and on to Netlify"', [
//   {
//     loc: {
//       end: {
//         column: 3,
//         line: 1
//       },
//       start: {
//         column: 1,
//         line: 1
//       }
//     },
//     type: 'INDENT',
//     val: 2
//   },
//   {
//     loc: {
//       end: {
//         column: 57,
//         line: 1
//       },
//       start: {
//         column: 3,
//         line: 1
//       }
//     },
//     type: 'NOT_INDENT',
//     val: '- var title = "Moving off Wordpress and on to Netlify"'
//   }
// ]);


//   test("  script(src='https://code.jquery.com/jquery-3.6.0.min.js' integrity='sha256-/xUj+3OJU5yExlq6GSYGSHk7tPXikynS7ogEvDej/m4=' crossorigin='anonymous')", [
//   {
//     loc: {
//       end: {
//         column: 3,
//         line: 1
//       },
//       start: {
//         column: 1,
//         line: 1
//       }
//     },
//     type: 'INDENT',
//     val: 2
//   },
//   {
//     loc: {
//       end: {
//         column: 148,
//         line: 1
//       },
//       start: {
//         column: 3,
//         line: 1
//       }
//     },
//     type: 'NOT_INDENT',
//     val: "script(src='https://code.jquery.com/jquery-3.6.0.min.js' integrity='sha256-/xUj+3OJU5yExlq6GSYGSHk7tPXikynS7ogEvDej/m4=' crossorigin='anonymous')"
//   }
// ]);

// test("\t", [
//   {
//     loc: {
//       end: {
//         column: 2,
//         line: 1
//       },
//       start: {
//         column: 1,
//         line: 1
//       }
//     },
//     type: 'INDENT',
//     val: 1
//   }
// ]);

// test('	', [
//   {
//     loc: {
//       end: {
//         column: 2,
//         line: 1
//       },
//       start: {
//         column: 1,
//         line: 1
//       }
//     },
//     type: 'INDENT',
//     val: 1
//   }
// ]);


// test('|', [
//   {
//     loc: {
//       end: {
//         column: 2,
//         line: 1
//       },
//       start: {
//         column: 1,
//         line: 1
//       }
//     },
//     type: 'PIPE'
//   }
// ]);

// test(` tag some text`, [
//   {
//     loc: {
//       end: {
//         column: 15,
//         line: 1
//       },
//       start: {
//         column: 1,
//         line: 1
//       }
//     },
//     type: 'NOT_INDENT',
//     val: ' tag some text'
//   }
// ]);

// test(` tag some text
// `, [
//   {
//     loc: {
//       end: {
//         column: 15,
//         line: 1
//       },
//       start: {
//         column: 1,
//         line: 1
//       }
//     },
//     type: 'NOT_INDENT',
//     val: ' tag some text'
//   }
// ]);

// test(`tag some text
//   continuation of text`, [{"type":"NOT_INDENT","val":"tag some text","loc":{"end":{"column":14,"line":1},"start":{"column":1,"line":1}}},{"type":"INDENT","val":2,"loc":{"end":{"column":3,"line":2},"start":{"column":1,"line":2}}},{"type":"NOT_INDENT","val":"continuation of text","loc":{"end":{"column":23,"line":2},"start":{"column":3,"line":2}}}]);

// test(`tag some text
// | continuation of text`, [
//     {
//       type: 'NOT_INDENT',
//       val: 'tag some text',
//       loc: { end: { column: 14, line: 1 }, start: { column: 1, line: 1 } }
//     },
//     {
//       type: 'PIPE',
//       loc: { end: { column: 2, line: 2 }, start: { column: 1, line: 2 } }
//     },
//     {
//       type: 'NOT_INDENT',
//       val: ' continuation of text',
//       loc: { end: { column: 23, line: 2 }, start: { column: 2, line: 2 } }
//     }
//   ]);

// test(`tag some text
//   | continuation of text`,[{"type":"NOT_INDENT","val":"tag some text","loc":{"end":{"column":14,"line":1},"start":{"column":1,"line":1}}},{"type":"INDENT","val":2,"loc":{"end":{"column":3,"line":2},"start":{"column":1,"line":2}}},{"type":"PIPE","loc":{"end":{"column":4,"line":2},"start":{"column":3,"line":2}}},{"type":"NOT_INDENT","val":" continuation of text","loc":{"end":{"column":25,"line":2},"start":{"column":4,"line":2}}}]);

// test(`keyword some text
//   | continuation of text`, [{"type":"KEYWORD","val":"keyword","loc":{"end":{"column":8,"line":1},"start":{"column":1,"line":1}}},{"type":"NOT_INDENT","val":" some text","loc":{"end":{"column":18,"line":1},"start":{"column":8,"line":1}}},{"type":"INDENT","val":2,"loc":{"end":{"column":3,"line":2},"start":{"column":1,"line":2}}},{"type":"PIPE","loc":{"end":{"column":4,"line":2},"start":{"column":3,"line":2}}},{"type":"NOT_INDENT","val":" continuation of text","loc":{"end":{"column":25,"line":2},"start":{"column":4,"line":2}}}]);

// test(`
// html
//   head
//   body
//     div
// `, [{"type":"NOT_INDENT","val":"html","loc":{"start":{"line":2,"column":1},"end":{"line":2,"column":5}}},{"type":"INDENT","val":2,"loc":{"start":{"line":3,"column":1},"end":{"line":3,"column":3}}},{"type":"NOT_INDENT","val":"head","loc":{"start":{"line":3,"column":3},"end":{"line":3,"column":7}}},{"type":"NOT_INDENT","val":"body","loc":{"start":{"line":4,"column":3},"end":{"line":4,"column":7}}},{"type":"INDENT","val":4,"loc":{"start":{"line":5,"column":1},"end":{"line":5,"column":5}}},{"type":"NOT_INDENT","val":"div","loc":{"start":{"line":5,"column":5},"end":{"line":5,"column":8}}}])



// test(`
// body
//   div
//     div2
//   div3
// `, [{"type":"NOT_INDENT","val":"body","loc":{"start":{"line":2,"column":1},"end":{"line":2,"column":5}}},{"type":"INDENT","val":2,"loc":{"start":{"line":3,"column":1},"end":{"line":3,"column":3}}},{"type":"NOT_INDENT","val":"div","loc":{"start":{"line":3,"column":3},"end":{"line":3,"column":6}}},{"type":"INDENT","val":4,"loc":{"start":{"line":4,"column":1},"end":{"line":4,"column":5}}},{"type":"NOT_INDENT","val":"div2","loc":{"start":{"line":4,"column":5},"end":{"line":4,"column":9}}},{"type":"DEDENT","loc":{"start":{"line":5,"column":1},"end":{"line":5,"column":3}}},{"type":"NOT_INDENT","val":"div3","loc":{"start":{"line":5,"column":3},"end":{"line":5,"column":7}}}])

// }