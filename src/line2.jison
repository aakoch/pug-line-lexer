/* 
 * This parses ONLY lines. Any newline is rejected. It looks for indentations and everything else. This was merged with just_lines.jison to create line_combo.jison.
 */

/* lexical grammar */
%lex

dot     [^\n]+
space			[ \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]

%%

[|]             return 'PIPE';
[\n]          ;
^({space}{space}|\t)   return 'INDENT';
(keyword|menu)   return 'KEYWORD';
{dot}      return 'ANYTHING';
<<EOF>>      return 'ENDOFFILE';

/lex

%% 

/* language grammar */

start
  : ENDOFFILE
  { $$ = [] }
  | lines ENDOFFILE
  { $$ = $lines }
  ;

lines


  // TODO: figure out the differences between these 2
  // : line line
  // { $$ = [$line1, $line2] }
  : lines line
  { $lines.push($line); $$ = $lines }



  | line
  { $$ = [$line] }
  ;

line
  : INDENT
  { $$ = {type:'INDENT', val: $INDENT.length, loc: toLoc(yyloc)} }
  | PIPE
  { 
  // console.log('token', yy.token);
  // console.log('describeSymbol', yy.parser.describeSymbol());
  $$ = {type:'PIPE', loc: toLoc(yyloc)} }
  | KEYWORD
  { 
  // console.log('token', yy.token);
  // console.log('describeSymbol', yy.parser.describeSymbol());
  $$ = {type:'KEYWORD', val: $KEYWORD, loc: toLoc(yyloc)} }
  | ANYTHING
  {
    console.log('ANYTHING', $ANYTHING); 
    // console.log('getSymbolName', yy.parser.getSymbolName());
    // console.log('quoteName', yy.parser.quoteName());
    $$ = {type:'NOT_INDENT', val: $ANYTHING, loc: toLoc(yyloc)}
  }
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


var assert = require("assert");
const util = require('util');

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


test('|', [
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
    type: 'PIPE'
  }
]);

test(` tag some text`, [
  {
    loc: {
      end: {
        column: 15,
        line: 1
      },
      start: {
        column: 1,
        line: 1
      }
    },
    type: 'NOT_INDENT',
    val: ' tag some text'
  }
]);

test(` tag some text
`, [
  {
    loc: {
      end: {
        column: 15,
        line: 1
      },
      start: {
        column: 1,
        line: 1
      }
    },
    type: 'NOT_INDENT',
    val: ' tag some text'
  }
]);

test(`tag some text
  continuation of text`, [{"type":"NOT_INDENT","val":"tag some text","loc":{"end":{"column":14,"line":1},"start":{"column":1,"line":1}}},{"type":"INDENT","val":2,"loc":{"end":{"column":3,"line":2},"start":{"column":1,"line":2}}},{"type":"NOT_INDENT","val":"continuation of text","loc":{"end":{"column":23,"line":2},"start":{"column":3,"line":2}}}]);

test(`tag some text
| continuation of text`, [
    {
      type: 'NOT_INDENT',
      val: 'tag some text',
      loc: { end: { column: 14, line: 1 }, start: { column: 1, line: 1 } }
    },
    {
      type: 'PIPE',
      loc: { end: { column: 2, line: 2 }, start: { column: 1, line: 2 } }
    },
    {
      type: 'NOT_INDENT',
      val: ' continuation of text',
      loc: { end: { column: 23, line: 2 }, start: { column: 2, line: 2 } }
    }
  ]);

test(`tag some text
  | continuation of text`,[{"type":"NOT_INDENT","val":"tag some text","loc":{"end":{"column":14,"line":1},"start":{"column":1,"line":1}}},{"type":"INDENT","val":2,"loc":{"end":{"column":3,"line":2},"start":{"column":1,"line":2}}},{"type":"PIPE","loc":{"end":{"column":4,"line":2},"start":{"column":3,"line":2}}},{"type":"NOT_INDENT","val":" continuation of text","loc":{"end":{"column":25,"line":2},"start":{"column":4,"line":2}}}]);

test(`keyword some text
  | continuation of text`, [{"type":"KEYWORD","val":"keyword","loc":{"end":{"column":8,"line":1},"start":{"column":1,"line":1}}},{"type":"NOT_INDENT","val":" some text","loc":{"end":{"column":18,"line":1},"start":{"column":8,"line":1}}},{"type":"INDENT","val":2,"loc":{"end":{"column":3,"line":2},"start":{"column":1,"line":2}}},{"type":"PIPE","loc":{"end":{"column":4,"line":2},"start":{"column":3,"line":2}}},{"type":"NOT_INDENT","val":" continuation of text","loc":{"end":{"column":25,"line":2},"start":{"column":4,"line":2}}}]);


}