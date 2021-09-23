/* TODO: Fix parsing of head.pug - line 48 is commented and indentation is wrong and the start of the if statement on 46 doesn't work */

%lex

id			[_?a-zA-Z]+[_a-zA-Z0-9-]*\b
spc			[\t \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]
// all     [^\n\t \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]+
// toEndOfLine .*$
// dot     [^\n]+$
newline [\r\n]+

%s EXPR

%%

<<EOF>>				%{
  // remaining DEDENTs implied by EOF, regardless of tabs/spaces
  var tokens = [];
  console.log('<INITIAL>\s*<<EOF>>: setting isText to false');
  isText = false;
  while (0 < stack[0]) {
    this.popState();
    tokens.unshift("DEDENT");
    stack.shift();
  }
    
    tokens.unshift('ENDOFFILE')
    return tokens;
  // return "ENDOFFILE";
%}	
// (include|block|mixin|html|head|body|meta|title|link|script|h1|doctype|script) %{
//   if (isText)
//     return;
//   else
//     return 'KEYWORD'
//   %}
// \b(html|head|body|meta|title|link|script|h1|doctype|script)\b %{
//   if (isText)
//     return;
//   else
//     return 'TAG'
//   %}
// '{'   return 'LCURL'; // left curly bracket
// '}'   return 'RCURL'; // right curly bracket
// ']'   return 'LSQR'; // left square bracket
// '['   return 'RSQR'; // right square bracket /* ] */
// '('     %{
//   console.log('LPAREN with isText=' + isText)
//   if (isText)
//     return;
//   else
//      return 'LPAREN';
//   %}
// ')'    %{
//   if (isText)
//     return;
//   else
//      return 'RPAREN';
//   %}
// \"[^\"]*\"|\'[^\']*\'		yytext = yytext.substr(1,yyleng-2); 
//   if (isText)
//     return;
//   else
//    return 'STRING';
// '.' %{
//   if (isText)
//     return
//   else
//     return 'DOT'
//   %}
'='   return 'EQ';
// '#'   return 'HASH';
','  
  if (isText)
    return;
  else return 'COMMA';
// {id} %{
//   if (isText)
//     return;
//   else
//     return 'ID'
//   %}
// {dot}      return 'TO_END_OF_LINE';
<INITIAL>\s*<<EOF>>		%{
  // remaining DEDENTs implied by EOF, regardless of tabs/spaces
  var tokens = [];
  console.log('<INITIAL>\s*<<EOF>>: setting isText to false');
  isText = false;
  while (0 < stack[0]) {
    this.popState();
    tokens.unshift("DEDENT");
    stack.shift();
  }
    
  if (tokens.length) return tokens;
%}
^{spc}*$		/* eat blank lines */
^({spc}{spc}|\t)+		%{
  console.log("enter", yylloc);
  var indentation = yyleng - yytext.search(/\s/) - 1;
    console.log(indentation, stack)

  if (util.isArray(stack[0]) ?  indentation > stack[0][1] : indentation > stack[0]) {
    stack.unshift(util.isArray(stack[0]) ? ['text', indentation] : indentation);
  console.log("returning INDENT on line " + yylloc.last_line, yylloc);
    return 'INDENT';
  }

  var tokens = [];

    console.log("look if stack[0] is array", stack)
  while (util.isArray(stack[0]) ?  indentation < stack[0][1] : indentation < stack[0]) {
    console.log("adding dedent on line", yylloc, stack)
    this.popState();
    tokens.unshift("DEDENT");
    stack.shift();
  }
  if (tokens.length) {
    if (tokens.length != 1) {
      console.log('<INITIAL>[\n\r]({spc}{spc}|\t)+	: setting isText to false');
      isText = false;
    }
    return tokens;
  }
  else 
  console.log('no indentation change on line ' + yylloc.last_line, stack[0])
%}
[^\n]+  %{
  console.log(yytext)
  if (isText)
    return 'TEXT'
  else
    return 'THEREST'
  %}
{newline}      return 'NEWLINE'
// {spc}+				/* ignore all other whitespace */
/lex


%ebnf


%options token-stack

%%

start
	: lines ENDOFFILE
	{ console.log("AST: %j", $lines); }
	;

lines
  : lines line
  { console.log('lines: lines line'); $lines.push($line); $$ = $lines; console.log($lines) }
  | line
  { $$ = [$line] }
  // | line ENDOFFILE
  // | block
  ;


line
	// : line stmt
	// { console.log('line: line stmt'); $line.push($stmt); $$ = $line; }
	: stmt 
  { console.log('line: stmt=', $stmt); $$ = $stmt; }
	| stmt NEWLINE
  { console.log('line: stmt NEWLINE stmt=', $stmt); $$ = $stmt; }
	;

// stmt_list
// 	: stmt
// 	{ console.log('(stmt_list) stmt'); $$ = [$stmt] }
// 	// | stmt_list stmt
// 	// { console.log('stmt_list stmt', '$stmt_list=' + $stmt_list, '$stmt=' + $stmt); $stmt_list.push($stmt); $$ = $stmt_list; }
// 	;

block
	: INDENT lines DEDENT
	{ console.log('INDENT lines DEDENT', $$); $$ = $lines; }
  // | DEDENT
	// { console.log('DEDENT'); $$ = {type:'DEDENT'} }
	;

stmt
  : TAG
  { console.log('TAG', $$); $$ = { type: 'TAG', val: $TAG, loc: toLoc(yyloc) } }
//   | TAG THEREST
//   { console.log('TAG THEREST', $$); $$ = { type: 'TAG', val: $TAG, body: $THEREST, loc: toLoc(yyloc) } }
//   | KEYWORD 
//   { console.log('stmt: KEYWORD=', $$); $$ = { type: 'KEYWORD', val: $KEYWORD, loc: toLoc(yyloc) } }
//   // | THEREST
//   // { $$ = { type: 'THEREST', val: $THEREST, loc: toLoc(yyloc) } }
//   | tag body
//   { console.log('tag body', $$); }
//   | punct
//   { console.log('punct', $$); }
  | block
  { console.log('block', $$); }
//   | element body
//   { console.log('element body', $$); }
//   | element
//   { console.log('element', $$); }
//   | ID
//   { console.log('ID', $$); $$ = { type: 'UNKNOWN ID', val: $ID, loc: toLoc(yyloc) } }
//   | TEXT 
//   { console.log('TEXT', $$); $$ = { type: 'text', val: $TEXT, loc: toLoc(yyloc) } }
  | THEREST
  { console.log('stmt: THEREST', $$); }
  ;

// element
//   : TAG
//   { console.log('TAG', $$); $$ = { type: 'TAG', val: $TAG, loc: toLoc(yyloc) } }
//   | tag_identifier
//   {console.log('tag_identifier', $$);  $$ = { type: 'TAG', tag_identifier: $tag_identifier, loc: toLoc(yyloc) } }
//   | TAG DOT
//   { console.log('TAG ' + $TAG  + ' DOT: setting isText to true');
//     isText = true; 
//     $$ = { type: 'TAG-DOT', val: $TAG, precedes: 'text', loc: toLoc(yyloc) } }
//   | TAG tag_identifier
//   { console.log('TAG tag_identifier', $$); $$ = { type: 'TAG', val: $TAG, tag_identifier: $tag_identifier, loc: toLoc(yyloc) } }
//   | TAG attributes
//   { console.log('TAG attributes', $TAG, $attributes); $$ = { type: 'TAG', val: $TAG, attributes: $attributes, loc: toLoc(yyloc) } }
//   | tag_identifier attributes
//   { console.log('tag_identifier attributes', $$); $$ = { tag_identifier: $tag_identifier, attributes: $attributes, loc: toLoc(yyloc) } }
//   | TAG DOT attributes
//   { console.log('TAG ' + $TAG  + ' DOT attributes: setting isText to true'); isText = true; $$ = { type: 'TAG-DOT', val: $TAG, precedes: 'text', attributes: $attributes, loc: toLoc(yyloc) } }
//   | TAG tag_identifier attributes
//   { console.log('TAG tag_identifier attributes', $$); $$ = { type: 'TAG', val: $TAG, tag_identifier: $tag_identifier, attributes: $attributes, loc: toLoc(yyloc) } }
//   | TAG attributes DOT
//   { console.log('TAG attributes DOT', $TAG, $attributes);
//     isText = true; 
//      $$ = { type: 'TAG', val: $TAG, attributes: $attributes, loc: toLoc(yyloc) } }
// 	;

// tag_identifier
//   : DOT ID
//   { console.log('DOT ID'); $$ = { type: 'tag_identifier', class: $ID, loc: toLoc(yyloc) } }
//   | DOT ID HASH ID
//   { console.log('DOT ID HASH ID'); $$ = { type: 'tag_identifier', class: $ID1, id: $ID2, loc: toLoc(yyloc) } }
//   | DOT ID HASH TAG
//   { console.log('DOT ID HASH TAG'); $$ = { type: 'tag_identifier', class: $ID, id: $TAG, loc: toLoc(yyloc) } }
//   ;

// attributes
//   : LPAREN anything RPAREN
//   { console.log('LPAREN anything RPAREN');
//   $$ = [$anything] }
//   ;

anything
  : anything THEREST
  { console.log('anything THEREST', $$); $anything.push($THEREST); $$ = $anything }
//   | anything KEYWORD
//   { console.log('anything KEYWORD', $$); let v2 = [$anything].push($KEYWORD); $$ = v2  }
//   | anything block
//   { console.log('anything block', $$); let v3 = [$anything].push($block); $$ = v3  }
//   | KEYWORD
//   { console.log('KEYWORD', $$); }
  | block
  { console.log('block', $$); }
  | THEREST
  { console.log('THEREST', $$); }
//   // | ID
//   // { console.log('ID', $$); }
//   // | EQ
//   // { console.log('EQ', $$); }
//   // | DOT
//   // { console.log('DOT', $$); }
  ;

// // really
// //   : THEREST
// //   { console.log('THEREST', $$); }
//   // | ID
//   // { console.log('ID', $$); }
//   // | EQ
//   // { console.log('EQ', $$); }
//   // | STRING
//   // { console.log('STRING', $$); }
//   // | DOT
//   // { console.log('DOT', $$); }
//   // ;

// attr_list
//   : attr_list attribute
//   { console.log('attr_list attribute', $$); [$attr_list].push($attribute); $$ = $attr_list }
//   | attr_list attr_spacer attribute
//   { console.log('attr_list attr_spacer attribute', $$); [$attr_list].push($attribute); $$ = $attr_list }
//   | attribute
//   { console.log('attribute', $$); }
//   ;

// attr_spacer
//   : COMMA
//   { console.log('COMMA', $$); }
//   | ' '
// 	{ console.log('SPACE'); $$ = {type:'SPACE'} }
//   ;

// attribute
//   : ID EQ STRING
//   { console.log('attribute ID EQ STRING', $ID, $STRING);
//    $$ = { type: 'attribute', key: $ID, val: $STRING, loc: toLoc(yyloc) } }
//   | ID attr_spacer
//   { console.log('ID attr_spacer', $$); $$ = { type: 'attribute', key: $ID, loc: toLoc(yyloc) } }
//   ;

// // keyword
// //   : keyword THEREST
// //   { $$ = [{ type: 'keyword', val: $keyword, loc: toLoc(yyloc) }, { type: 'THEREST', val: $THEREST, loc: toLoc(yyloc) }] }
// //   | THEREST
// //   { $$ = { type: 'THEREST', val: $THEREST, loc: toLoc(yyloc) } }
// //   | KEYWORD
// //   { $$ = { type: 'KEYWORD', val: $THEREST, loc: toLoc(yyloc) } }
// //   ;

// // tag
// //   : TAG
// //   { $$ = { type: 'TAG', val: $TAG, loc: toLoc(yyloc) } }
// //   ;

// body
//   : THEREST
//   { console.log('THEREST', $$); $$ = { type: 'BODY', val: $THEREST, loc: toLoc(yyloc) } }
//   ;

// punct
//   : LCURL
//   { console.log('LCURL', $$); $$ = { type: 'LEFT_CURLY_BRACKET', loc: toLoc(yyloc) } }
//   | RCURL
//   { console.log('RCURL', $$); $$ = { type: 'RIGHT_CURLY_BRACKET', loc: toLoc(yyloc) } }
//   | LSQR
//   { console.log('LSQR', $$); $$ = { type: 'LEFT_SQUARE_BRACKET', loc: toLoc(yyloc) } }
//   | RSQR
//   { console.log('RSQR', $$); $$ = { type: 'RIGHT_SQUARE_BRACKET', loc: toLoc(yyloc) } }
//   ;

%% 

var stack = [0];

function toLoc(yyloc) {
  if (location)
  return {
        start: {
          line: yyloc.first_line,
          column: yyloc.first_column
        },
        end: {
          line: yyloc.last_line,
          column: yyloc.last_column
        },
        filename: filename,
     }
  else 
    return ''
}

var isText = false;
var filename;
var stripDown = false;
var location = true;

var util = require('util')

function ti(tagId) {
  if (tagId == undefined) 
    return '';

  let arr = []
  if (tagId.class != undefined) {
    arr.push('.')
    arr.push(tagId.class)
  }
  if (tagId.id != undefined) {
    arr.push('#')
    arr.push(tagId.id)
  }
  return arr.join('')
}

function strip(arr) {
  return arr
    .filter(el => {
      return util.isArray(el) || el.val
    })
    .map(el => {
      if (util.isArray(el)) {
        return strip(el);
      }
      return ([el.val, el.param, el.body, ti(el.tag_identifier), (el.attributes || []).map(el => el.key + '=' + el.val)])
        .filter(attr => attr != undefined)
        .map(attr => attr.toString().trim())
        .join(' ')
    })
}

parser.main = function (args) {
    if (!args[1]) {
        console.log('Usage:', path.basename(args[0]) + ' FILE');
        process.exit(1);
    }
    filename = args[1]
    var source = fs.readFileSync(path.normalize(args[1]), 'utf8');
    var dst = exports.parser.parse(source);

    if (stripDown) 
      dst = strip(dst)

    console.log('parser output:\n\n', {
        type: typeof dst,
        value: dst
    });
    try {
        console.log("\n\nor as JSON:\n", JSON.stringify(dst, null, 2));
    } catch (e) { /* ignore crashes; output MAY not be serializable! We are a generic bit of code, after all... */ }
    var rv = 0;
    if (typeof dst === 'number' || typeof dst === 'boolean') {
        rv = dst;
    }
    return dst;
};