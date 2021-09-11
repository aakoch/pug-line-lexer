/* foo-dog parser */

/* lexical grammar */
%lex


id			[a-zA-Z_][a-zA-Z0-9_]*
spc			[\t \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]

%s EXPR

%%

{id}                  return 'ID';
{spc}                  return 'SPACE';
"\n"               return 'NEWLINE';
[0-9]+("."[0-9]+)?\b  return 'NUMBER';
"*"                   return '*';
"/"                   return '/';
"-"                   return '-';
"+"                   return 'PLUS';
"^"                   return '^';
"!"                   return '!';
"%"                   return '%';
"("                   return '(';
")"                   return ')';
"mixin"								return "MIXIN_DEF"
"include"							return "INCLUDE"
// "PI"                  return 'PI';
// "E"                   return 'E';
.                     return 'DOT';
<<EOF>>               return 'ENDOFFILE';
<INITIAL>\s*<<EOF>>		%{
	// remaining DEDENTs implied by EOF, regardless of tabs/spaces
	var tokens = [];

	while (0 < _iemitstack[0]) {
		this.popState();
		tokens.unshift("DEDENT");
		_iemitstack.shift();
	}
		
	if (tokens.length) return tokens;
%}
// // [\n\r]+{spc}*/![^\n\r]		/* eat blank lines */
<INITIAL>[\n\r]{spc}*		%{
	var indentation = yyleng - yytext.search(/\s/) - 1;
	// console.log('yyleng=%d', yyleng)
	// console.log('yytext=%s', yytext)
	// console.log('indentation=%d', indentation)
	// console.log('_iemitstack=%s', _iemitstack)
	// console.log('_iemitstack[0]=%s', _iemitstack[0])
	if (indentation > _iemitstack[0]) {
		_iemitstack.unshift(indentation);
		console.log('IDENT - line 55')
		return 'INDENT';
	}

	var tokens = [];

	while (indentation < _iemitstack[0]) {
		this.popState();
		tokens.unshift("DEDENT");
		console.log('DEDENT')
		_iemitstack.shift();
	}
	if (tokens.length) return tokens;
%}
// {spc}+				/* ignore all other whitespace */

/lex

/* operator associations and precedence */

// %left '+' '-'
// %left '*' '/'
// %left '^'
// %right '!'
// %right '%'
// %left UMINUS

%start prog

%% /* language grammar */

// prog
// 	// empty string
// 	: ENDOFFILE
// 	{ console.log("AST: %j", []); }
// 	// non-empty string
// 	| linelist ENDOFFILE
// 	{ console.log("AST: %j", $linelist); }
// 	;

prog
	// empty string
	: ENDOFFILE
	{ console.log("empty file"); }
	| id_list ENDOFFILE
	// { console.log("id_list ENDOFFILE id_list=%s", $id_list); }
	;

// linelist
// 	// : SPACE
// 	// { $$ = ['SPACE']; console.log("SPACE=%s", $SPACE); }
// 	: id_list
// 	{ $$ = [$id_list]; console.log("id_list=%s", $id_list); }
// 	// | id_list SPACE
// 	// { $$ = ['id_list SPACE', $id_list]; console.log("id_list=%s SPACE", $id_list); }
// 	// | id_list NEWLINE
// 	// { $$ = ['id_list NEWLINE', $id_list]; console.log("id_list=%s NEWLINE", $id_list); }
// 	// | line NEWLINE
// 	// { $line.push($NEWLINE); $$ = $NEWLINE; console.log("NEWLINE line=%s", $line); }
// 	;

id_list
	// : id_list INDENT block
	// { $id_list.push([$INDENT, $block]); $$ = [$id_list]; console.log('line 117 INDENT block=%s', $block); console.log(_iemitstack) }
	: id_list block
	{ $id_list.push([$block]); $$ = $id_list;  console.log("id_list=%s block=%s", JSON.stringify($id_list), $block); }
	// | id_list INDENT block
	// { $id_list.push([$block]); $$ = $id_list;  console.log("INDENT id_list=%s block=%s", JSON.stringify($id_list), $block); }
	// : id_list ID
	// { $id_list.push(['ID', $ID]); $$ = $id_list;  console.log("id_list=%s ID=%s", JSON.stringify($id_list), $ID); }
	
	
	// | ID
	// { $$ = [[$ID]]; console.log("ID=%s", $ID); }
	
	| block
	{ $$ = [$block]; console.log("block=%s", $block); }


	// | id_list INDENT ID
	// // { $$ = $id_list;  console.log("id_list=%s INDENT", JSON.stringify($id_list)); }
	// { $id_list.push(['ID', $ID]); $$ = $id_list;  console.log("id_list=%s ID=%s", JSON.stringify($id_list), $ID); }
	;

block
	: block EOF
	{ $$ = [$block]; console.log('block EOF'); console.log(_iemitstack) }
	| INDENT block
	{ [$block].push($block); $$ = [$block]; console.log('INDENT block line 143'); console.log(_iemitstack) }
	| ID
	{ console.log('ID=%s', $ID); console.log(_iemitstack)  }
	;
// linelist
// 	// : linelist line
// 	// { $linelist.push($line); $$ = $linelist; console.log("linelist=%s line=%s", JSON.stringify($linelist), $line); }
// 	: line
// 	{ $$ = [$line]; console.log("line=%s", $line); }
// 	;

// line
// 	: tag 
// 	{ $$ = { type: 'tag', value: $tag }; console.log("tag=%s", $tag); }
// 	| INDENT tag
// 	{ $$ = { type: 'tag', value: $tag }; console.log("INDENT tag=%s", $tag); }
// 	// proglist
// 	// { $proglist.push($stmt); $$ = $proglist; }
// 	// | ID
// 	// { $$ = [$ID]; }
//   // | stmt_block
// 	// { $proglist.push($ID); $$ = $proglist; }
// 	;

// tag
// 	: ID
// 	{ $$ = { type: 'tag', value: $ID }; console.log("tag=%s", $ID); }
// 	| NEWLINE INDENT tag
// 	{ $$ = { type: 'tag', value: $tag }; console.log("INDENT tag=%s", $tag); }
// 	;

// INDENT
// 	: INDENT
// 	{ console.log('INDENT found') }
// 	;

// tag_list
// 	: tag
// 	{ $$ = ["tag_list", $tag]; console.log("tag=%s", $tag); }
// 	| tag_list tag
// 	{ $tag_list.push($tag); $$ = $tag_list; console.log("tag_list tag=%s", $tag); }
// 	;

// tag_block
// 	: INDENT tag_list DEDENT
// 	{ $$ = $tag_list; console.log("INDENT tag_list DEDENT=%s", $tag_list); }
// 	;

// NEWLINE
// 	: tag
// 	{ $tag_list.push($tag); console.log("Newline"); }
// 	;


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
// 	: tag
// 	;

// stmt_list
// 	: stmt_block
// 	{ $$ = ["stmt_list", $stmt_block]; }
// 	| stmt_list ID
// 	{ $stmt_list.push($ID); $$ = $stmt_list; }
// 	;

// stmt_block
// 	: INDENT stmt_list DEDENT
// 	{ $$ = $stmt_list; }
// 	;

// tag
// 	: ID
// // 	{ $$ = ["id", $1]; }
// // 	| ID CLASSLIST
// // 	{ $$ = ["id", $1, "classes", $2]; }
// // 	| ID LPAREN expr RPAREN
// // 	{ $$ = ["id", $1, "attrs", $3]; }
// 	;

// atom
// 	: ID
// 	{ $$ = ["id", $1]; }
// 	// | NATLITERAL
// 	// { $$ = ["natlit", $1]; }
// 	// | LPAREN expr RPAREN
// 	// { $$ = ["expr", $2]; }
// 	;

// expr
// 	: atom
// 	// | expr PLUS atom
// 	// { $expr.push(["plus", $atom]); $$ = $expr; }
// 	// | expr MINUS atom
// 	// { $expr.push(["minus", $atom]); $$ = $expr; }
// 	;


// ----------------------------------------------------------------------------------------

%%

// feature of the GH fork: specify your own main.
//
// compile with
// 
//      jison -o test.js --main that/will/be/me.jison
//
// then run
//
//      node ./test.js
//
// to see the output.

var _iemitstack = [0]

var assert = require("assert");

parser.main = function () {
    var rv = parser.parse('');
    console.log("test empty: '' ==> ", rv, parser.yy);
    assert.equal(rv, []);

    var rv = parser.parse('html');
    console.log("test #1: 'html' ==> ", rv, parser.yy);
    assert.equal(JSON.toString(rv), JSON.toString([ { type: 'tag', value: 'html' } ]));

		let str = 'html\n  head'
    rv = parser.parse(str);
    console.log(str + " ==> ", JSON.stringify(rv));


		str = 'html\n  head\n  body'
    rv = parser.parse(str);
    console.log(str + " ==> ", JSON.stringify(rv));


		str = 'html\n  head\n  body\n    div'
    rv = parser.parse(str);
    console.log(JSON.stringify(str) + " ==> " + JSON.stringify(rv));


    // assert.equal(rv, ['html', ['head']]);

    // if you get past the assert(), you're good.
    // console.log("tested OK");
};


// import chai from 'chai';
// var expect = chai.expect;
// import { tokenize } from '../index.js';
// import { Token } from '../token.js';
// import { describe } from 'mocha'

// import pkg from "assert";
// const { assert } = pkg

// parser.main = function () {
//     var rv = parser.parse('html');
//     console.log("html ==> ", rv);
//     assert.equal(rv, ['id','html']);

//     // if you get past the assert(), you're good.
//     console.log("tested OK");
// };

// describe('lexer', function () {
//   describe('tokenize()', function () {
//     it('should return an empty object when an empty string is given', () => {
//       expect(tokenize("")).to.be.empty;
//     });

//     it('should return a tag token for known tags', () => {
//       expect(tokenize("html")).to.be.an('object').that.has.property('type', 'tag')
//     });

//     it('should return a tag with the same name', () => {
//       expect(tokenize("html")).to.be.an('object').that.has.property('value', 'html')
//     });
//   });
// });