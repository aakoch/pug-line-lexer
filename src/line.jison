/* simple parser */

/* lexical grammar */
%lex

dot     [^\n]+
space			[ \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]

%%

[\n]          return 'NEWLINE';
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
  : line line
  { $$ = [$line1, $line2] }
  | line
  { $$ = [$line] }
  ;

line
  : INDENT
  { $$ = {type:'INDENT', value:$INDENT.length, loc: toLoc(yyloc)} }
  | ANYTHING
  { $$ = {type:'NOT_INDENT', value:$ANYTHING, loc: toLoc(yyloc)} }
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
    var actual = parser.parse(input)
    console.log('\n\nTesting...' + input + ' ==> ', JSON.stringify(actual))
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
    value: 'extends ../../../../templates/blogpost'
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
    value: 'append variables'
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
    value: 2
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
    value: '- var title = "Moving off Wordpress and on to Netlify"'
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
    value: 2
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
    value: "script(src='https://code.jquery.com/jquery-3.6.0.min.js' integrity='sha256-/xUj+3OJU5yExlq6GSYGSHk7tPXikynS7ogEvDej/m4=' crossorigin='anonymous')"
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
    value: 1
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
    value: 1
  }
]);


assert.throws(() => {
  parser.parse('\n')
},
{
  name: 'JisonParserError'
});

}