/* simple parser */

/* lexical grammar */
%lex

dot     [^\n]+
space			[ \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]

%%

[\n\u000B]       ;
({space}{space}|\t)   return 'INDENT';
{dot}      return 'ANYTHING';
<<EOF>>      return 'ENDOFFILE';

/lex

%% 

/* language grammar */

start
  : ENDOFFILE
  { $$ = [] }
  | lines ENDOFFILE
  {  $$ = [$lines].flat()  }
  ;

lines
  : lines line
  { $lines.push($line); $$ = $lines }
  // | line line
  // { $$ = [$line1, $line2] }
  | line
  { $$ = [$line]  }
  ;

line
  : INDENT
  { $$ = {type:'INDENT', val:$INDENT.length, loc: toLoc(yyloc)} }
  | ANYTHING
  { $$ = {type:'NOT_INDENT', val:$ANYTHING, loc: toLoc(yyloc)} }
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
        end: {
          column: yyloc.last_column + 1,
          line: yyloc.last_line
        },
        start: {
          column: yyloc.first_column + 1,
          line: yyloc.first_line
        }
      
     }
}


var assert = require("assert");

parser.main = function () {

  function test(input, expected) {
    console.log('\n\nTesting...' + input)
    var actual = parser.parse(input)
    console.log(' ==> ', JSON.stringify(actual))
    assert.deepEqual(actual, expected)
  }

  test('extends ../../../../templates/blogpost', [
  {
    loc: {
      end: {
        column: 39,
        line: 1
      },
      start: {
        column: 1,
        line: 1
      }
    },
    type: 'NOT_INDENT',
    val: 'extends ../../../../templates/blogpost'
  }
]);

  test('append variables', [
  {
    loc: {
      end: {
        column: 17,
        line: 1
      },
      start: {
        column: 1,
        line: 1
      }
    },
    type: 'NOT_INDENT',
    val: 'append variables'
  }
]);


  test('  - var title = "Moving off Wordpress and on to Netlify"', [
  {
    loc: {
      end: {
        column: 3,
        line: 1
      },
      start: {
        column: 1,
        line: 1
      }
    },
    type: 'INDENT',
    val: 2
  },
  {
    loc: {
      end: {
        column: 57,
        line: 1
      },
      start: {
        column: 3,
        line: 1
      }
    },
    type: 'NOT_INDENT',
    val: '- var title = "Moving off Wordpress and on to Netlify"'
  }
]);


  test("  script(src='https://code.jquery.com/jquery-3.6.0.min.js' integrity='sha256-/xUj+3OJU5yExlq6GSYGSHk7tPXikynS7ogEvDej/m4=' crossorigin='anonymous')", [
  {
    loc: {
      end: {
        column: 3,
        line: 1
      },
      start: {
        column: 1,
        line: 1
      }
    },
    type: 'INDENT',
    val: 2
  },
  {
    loc: {
      end: {
        column: 148,
        line: 1
      },
      start: {
        column: 3,
        line: 1
      }
    },
    type: 'NOT_INDENT',
    val: "script(src='https://code.jquery.com/jquery-3.6.0.min.js' integrity='sha256-/xUj+3OJU5yExlq6GSYGSHk7tPXikynS7ogEvDej/m4=' crossorigin='anonymous')"
  }
]);

test("\t", [
  {
    loc: {
      end: {
        column: 2,
        line: 1
      },
      start: {
        column: 1,
        line: 1
      }
    },
    type: 'INDENT',
    val: 1
  }
]);

test('	', [
  {
    loc: {
      end: {
        column: 2,
        line: 1
      },
      start: {
        column: 1,
        line: 1
      }
    },
    type: 'INDENT',
    val: 1
  }
]);

test(`extends ../../../../templates/blogpost

append variables
  - var title = "Moving off Wordpress and on to Netlify"
  - var posted = '2021-09-08'`, [
    {
      type: 'NOT_INDENT',
      val: 'extends ../../../../templates/blogpost',
      loc: { end: { column: 39, line: 1 }, start: { column: 1, line: 1 } }
    },
    {
      type: 'NOT_INDENT',
      val: 'append variables',
      loc: { end: { column: 17, line: 3 }, start: { column: 1, line: 3 } }
    },
    {
      type: 'INDENT',
      val: 2,
      loc: { end: { column: 3, line: 4 }, start: { column: 1, line: 4 } }
    },
    {
      type: 'NOT_INDENT',
      val: '- var title = "Moving off Wordpress and on to Netlify"',
      loc: { end: { column: 57, line: 4 }, start: { column: 3, line: 4 } }
    },
    {
      type: 'INDENT',
      val: 2,
      loc: { end: { column: 3, line: 5 }, start: { column: 1, line: 5 } }
    },
    {
      type: 'NOT_INDENT',
      val: "- var posted = '2021-09-08'",
      loc: { end: { column: 30, line: 5 }, start: { column: 3, line: 5 } }
    }
  ]);

test(`html
  head
  body
    div1
    \tdiv2
`,  [
    {
      type: 'NOT_INDENT',
      val: 'html',
      loc: { end: { column: 5, line: 1 }, start: { column: 1, line: 1 } }
    },
    {
      type: 'INDENT',
      val: 2,
      loc: { end: { column: 3, line: 2 }, start: { column: 1, line: 2 } }
    },
    {
      type: 'NOT_INDENT',
      val: 'head',
      loc: { end: { column: 7, line: 2 }, start: { column: 3, line: 2 } }
    },
    {
      type: 'INDENT',
      val: 2,
      loc: { end: { column: 3, line: 3 }, start: { column: 1, line: 3 } }
    },
    {
      type: 'NOT_INDENT',
      val: 'body',
      loc: { end: { column: 7, line: 3 }, start: { column: 3, line: 3 } }
    },
    {
      type: 'INDENT',
      val: 2,
      loc: { end: { column: 3, line: 4 }, start: { column: 1, line: 4 } }
    },
    {
      type: 'INDENT',
      val: 2,
      loc: { end: { column: 5, line: 4 }, start: { column: 3, line: 4 } }
    },
    {
      type: 'NOT_INDENT',
      val: 'div1',
      loc: { end: { column: 9, line: 4 }, start: { column: 5, line: 4 } }
    },
    {
      type: 'INDENT',
      val: 2,
      loc: { end: { column: 3, line: 5 }, start: { column: 1, line: 5 } }
    },
    {
      type: 'INDENT',
      val: 2,
      loc: { end: { column: 5, line: 5 }, start: { column: 3, line: 5 } }
    },
    {
      type: 'INDENT',
      val: 1,
      loc: { end: { column: 6, line: 5 }, start: { column: 5, line: 5 } }
    },
    {
      type: 'NOT_INDENT',
      val: 'div2',
      loc: { end: { column: 10, line: 5 }, start: { column: 6, line: 5 } }
    }
  ])

}