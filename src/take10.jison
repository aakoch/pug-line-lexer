/* TODO: Fix parsing of head.pug - line 48 is commented and indentation is wrong and the start of the if statement on 46 doesn't work 

TODO: TEXT lines aren't indented. Actually, not sure if I can even do ^^^.
*/

%lex

id			[_?a-zA-Z]+[_a-zA-Z0-9-]*\b
spc			[\t \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]
newline [\r\n]
not_newline [^\r\n]
classname_decl \.{id}+\b
id_decl #{id}+\b
line_ending_with_dot			.+(\.|\/\/)
tag_declaration_terminator [ \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000()]

%x ATTRIBUTES
%s TAG
%x TEXT
%x BODY_STATE

%%

<INITIAL>{id} this.pushState('TAG'); return 'TAG_NAME'
<INITIAL>{newline}  ;
<INITIAL>^({spc}{spc}|\t)+
%{
  const _debug = debug('lex')('INITIAL')
  _debug('space at beginning of line')();
  const indentation = yytext.length
  _debug('indentation=' + indentation)();

  if(indentation > stack[0]) {
    stack.unshift(indentation)
    return 'INDENT'
  }

  let tokens = []
  
  while (indentation < stack[0]) {
    log("adding dedent on line", yylloc, stack)
    tokens.unshift("DEDENT");
    stack.shift();
  }

  if (tokens.length) {
    return tokens;
  }
%}

<INITIAL>\s*<<EOF>>		%{
  // remaining DEDENTs implied by EOF, regardless of tabs/spaces
  return cleanEof.apply(this)
%}	

//   var indentation = yyleng - yytext.search(/\s/) - 1;
//     log(indentation, stack)

//   if (util.isArray(stack[0]) ?  indentation > stack[0][1] : indentation > stack[0]) {
//     stack.unshift(util.isArray(stack[0]) ? ['text', indentation] : indentation);
//   log("returning INDENT on line " + yylloc.last_line, yylloc);
//     return 'INDENT';
//   }

<TAG>{id_decl} return 'ID_DECL'
<TAG>{classname_decl} return 'CLASSNAME_DECL'
<TAG>{spc} this.pushState('BODY_STATE')
<TAG>'(' this.pushState('ATTRIBUTES')
<TAG>{id}+  return 'TAG_NAME'
<TAG>{newline} ;
  resetState.apply(this)
  return "BODY"
<TAG>{not_newline}*<<EOF>> 
  return cleanEof.apply(this)

<BODY_STATE>{not_newline}+ 
  debug('lex')('BODY_STATE')('not_newline')()
  return "BODY"
<BODY_STATE>{newline} %{
  debug('lex')('BODY_STATE')('newline')('conditionStack=' + this.conditionStack)()
  resetState.apply(this)
%}
   
<ATTRIBUTES>[^)]+ return 'ATTRIBUTES'
<ATTRIBUTES>')'
%{
  // while (this.topState() != 'INITIAL') {
    this.popState()
  // }
%}
// <TAG>[^\n]+ 
//    return 'THEREST'
// <TAG>{newline}
//    console.log('<TAG> newline - ending <TAG>')
//    this.popState();
//    return 'NEWLINE'

// // <TAG>{newline}
// //   console.log('<' + this.topState() + '> {newline}: ' + yytext)
// //   console.log('stateStackSize()=' + this.stateStackSize())
// //   console.log('yy.lexer.conditionStack', yy.lexer.conditionStack)
// //   // this.popState(); 
// //   // this.pushState('TAG_BODY')
// //   return 'NEWLINE';

// // <TAG>{tag_declaration_terminator}
// //   console.log('<' + this.topState() + '> {tag_declaration_terminator}: ' + yytext)
// //   console.log('stateStackSize()=' + this.stateStackSize())
// //   this.popState(); 
// //   // this.pushState('TAG_BODY')
// //   return 'TAG_DECLARATION_TERMINATOR';
// // // <TAG>[^\n{spc}]+  
// // //   console.log(this.topState() + ' [^\\n]+: ' + yytext); 
// // //   this.pushState('TAG_BODY')
// // //   return 'THEREST';
// // // <TAG>[\n{spc}] 
// // //   console.log(this.topState() + ' \\n'); 
// // //   this.popState(); 

// // <TAG>[^\n{spc}]+  
// //   console.log('<' + this.topState() + '> [^\\n]+: ' + yytext); 
// //   console.log('stateStackSize()=' + this.stateStackSize())
// //   this.popState(); 
// //   return 'THEREST';
// // // <TAG_BODY>{spc}
// // //   console.log('<TAG_BODY> \\n'); 
// // //   this.popState(); 
// // //   return 'SPACE';
// // <TAG>'\n'
// //   console.log('Ending TAG_BODY becaues of NEWLINE. stateStackSize()=' + this.stateStackSize()); 
// //   this.popState(); 

// <ATTRIBUTES>[^\n]+ return 'THEREST';
// <ATTRIBUTES>{newline} %{
//     this.popState()
//   %};
// <ATTRIBUTES><<EOF>>				%{
//   // remaining DEDENTs implied by EOF, regardless of tabs/spaces
//   var tokens = [];
//   log('<INITIAL>\s*<<EOF>>: setting isText to false');
//   isText = false;
//   while (0 < stack[0]) {
//     this.popState();
//     tokens.unshift("DEDENT");
//     stack.shift();
//   }
    
//     tokens.unshift('ENDOFFILE')
//     return tokens;
//   // return "ENDOFFILE";
// %}	
// <ATTRIBUTES>')'    %{
//     this.popState()
//     return 'THEREST';
//   %}


// <TEXT>({spc}{spc}|\t)  ;
// <TEXT>{newline} ;
// // <TEXT>{rest}  if (yylloc.first_column < indent) this.popState('TEXT'); return 'TEXT';
// <TEXT>.+ %{
//   console.log('stateStackSize()=' + this.stateStackSize())
//   console.log('indent=' + indent + ', first_column=' + yylloc.first_column + ', yytext=' + yytext); 
//   if(yylloc.first_column <= indent) {
//     if (yytext.endsWith('.')) {
//       return 'LINE_ENDING_WITH_DOT'
//     }
//     else {
//       // log('yytext=' + yytext)
//       this.popState('TEXT'); 
//       return 'THEREST'
//     }
//     // lexer.reject()
//     // lexer.setInput(yytext)
//     // lexer.clear()
//   }
//   else {
//     return 'TEXT'
//   }
// %}
// <TEXT><<EOF>>				%{
//   // remaining DEDENTs implied by EOF, regardless of tabs/spaces
//   var tokens = [];
//   log('<INITIAL>\s*<<EOF>>: setting isText to false');
//   isText = false;
//   while (0 < stack[0]) {
//     this.popState();
//     tokens.unshift("DEDENT");
//     stack.shift();
//   }
    
//     tokens.unshift('ENDOFFILE')
//     return tokens;
//   // return "ENDOFFILE";
// %}	

// <<EOF>>				%{
//   // remaining DEDENTs implied by EOF, regardless of tabs/spaces
//   var tokens = [];
//   log('<INITIAL>\s*<<EOF>>: setting isText to false');
//   isText = false;
//   while (0 < stack[0]) {
//     this.popState();
//     tokens.unshift("DEDENT");
//     stack.shift();
//   }
    
//     tokens.unshift('ENDOFFILE')
//     return tokens;
//   // return "ENDOFFILE";
// %}	
// // (include|block|mixin|html|head|body|meta|title|link|script|h1|doctype|script) %{
// //   if (isText)
// //     return;
// //   else
// //     return 'KEYWORD'
// //   %}
// (html|head|body|meta|title|link|script|h1|doctype|script) %{
// //   if (isText)
// //     return;
// //   else
//     console.log('stateStackSize()=' + this.stateStackSize())
//     this.pushState('TAG')
//     return 'TAG_START'
//   %}
// // '{'   return 'LCURL'; // left curly bracket
// // '}'   return 'RCURL'; // right curly bracket
// // ']'   return 'LSQR'; // left square bracket
// // '['   return 'RSQR'; // right square bracket /* ] */
// '('     %{
//   console.log('Pushing state ATTRIBUTES')
//     this.pushState('ATTRIBUTES')
//     return 'LPAREN';
//   %}
// ')'    %{
//     this.popState()
//     return 'RPAREN';
//   %}
// // \"[^\"]*\"|\'[^\']*\'		yytext = yytext.substr(1,yyleng-2); 
// //   if (isText)
// //     return;
// //   else
// //    return 'STRING';
// // '.' %{
// //   if (isText)
// //     return
// //   else
// //     return 'DOT'
// //   %}
// '='   return 'EQ';
// // '#'   return 'HASH';
// // ','  
// //   if (isText)
// //     return;
// //   else return 'COMMA';
// ^#{id}   
//     this.pushState('TAG')
//     return 'ELEMENT_ID';
// \|.*   return 'PIPE_TEXT';
// // {id} %{
// //   if (isText)
// //     return;
// //   else
// //     return 'ID'
// //   %}
// // {dot}      return 'TO_END_OF_LINE';
// <INITIAL>\s*<<EOF>>		%{
//   console.log('stateStackSize()=' + this.stateStackSize())
//   // remaining DEDENTs implied by EOF, regardless of tabs/spaces
//   var tokens = [];
//   log('<INITIAL>\s*<<EOF>>: setting isText to false');
//   isText = false;
//   while (0 < stack[0]) {
//     this.popState();
//     tokens.unshift("DEDENT");
//     stack.shift();
//   }
    
//   if (tokens.length) return tokens;
// %}
// ^{spc}*$		/* eat blank lines */
// ^({spc}{spc}|\t)+		%{
//   log("enter", yylloc);
//   var indentation = yyleng - yytext.search(/\s/) - 1;
//     log(indentation, stack)

//   if (util.isArray(stack[0]) ?  indentation > stack[0][1] : indentation > stack[0]) {
//     stack.unshift(util.isArray(stack[0]) ? ['text', indentation] : indentation);
//   log("returning INDENT on line " + yylloc.last_line, yylloc);
//     return 'INDENT';
//   }

//   var tokens = [];

//     log("look if stack[0] is array", stack)
//   while (util.isArray(stack[0]) ?  indentation < stack[0][1] : indentation < stack[0]) {
//     log("adding dedent on line", yylloc, stack)
//     this.popState();
//     tokens.unshift("DEDENT");
//     stack.shift();
//   }
//   if (tokens.length) {
//     if (tokens.length != 1) {
//       log('<INITIAL>[\n\r]({spc}{spc}|\t)+	: setting isText to false');
//       isText = false;
//     }
//     return tokens;
//   }
//   else 
//   log('no indentation change on line ' + yylloc.last_line, stack[0])
// %}

// <TAG>{line_ending_with_dot}  %{ console.log('line_ending_with_dot. yytext=' + yytext) %}
// 					// var indentation = yytext.search(/\w/);
//           console.log('yylloc=', yylloc)
//           console.log('first_column=' + yylloc.first_column + ', yyleng=' + yyleng + ', yytext.search(/\\s/)=' + yytext.search(/\s/)); 
//           indent=yylloc.first_column; 
//           this.pushState('TEXT'); 
//           return 'LINE_ENDING_WITH_DOT';


// [^\n]+  %{
//   log(yytext)
//   if (isText)
//     return 'BLOCK_TEXT'
//   else
//     return 'THEREST'
//   %}
// {newline}      return 'NEWLINE'
// // {spc}+				/* ignore all other whitespace */

/lex

%ebnf

%options token-stack

%%

start
	: lines ENDOFFILE
	{ log("AST: %j", $lines); }
	;

lines
  : lines line
  { log('lines: lines line'); $lines.push($line); $$ = $lines; log($lines) }
  | line
  { $$ = [$line] }
  // | line ENDOFFILE
  ;


line
	// : line stmt
	// { log('line: line stmt'); $line.push($stmt); $$ = $line; }
	: tag 
  { log('line: tag=', $tag); }
	| stmt NEWLINE
  { log('line: stmt NEWLINE stmt=', $stmt); $$ = $stmt; }
  | block
	;

// // stmt_list
// // 	: stmt
// // 	{ log('(stmt_list) stmt'); $$ = [$stmt] }
// // 	// | stmt_list stmt
// // 	// { log('stmt_list stmt', '$stmt_list=' + $stmt_list, '$stmt=' + $stmt); $stmt_list.push($stmt); $$ = $stmt_list; }
// // 	;

block
	: INDENT lines DEDENT
	{ log('INDENT lines DEDENT', $$); $$ = $lines; }
//   // | DEDENT
// 	// { log('DEDENT'); $$ = {type:'DEDENT'} }
	;

// stmt
//   : tag
//   { 
//     log('stmt: tag', $tag);
//   }
//   | tag the_rest
//   { 
//     log('stmt: tag the_rest', $tag, $the_rest);
//     $tag.rest = ($tag.rest || '') + $the_rest.val
//   }
// //   | TAG THEREST
// //   { log('TAG THEREST', $$); $$ = { type: 'TAG', val: $TAG, body: $THEREST, loc: toLoc(yyloc) } }
// //   | KEYWORD 
// //   { log('stmt: KEYWORD=', $$); $$ = { type: 'KEYWORD', val: $KEYWORD, loc: toLoc(yyloc) } }
// //   // | THEREST
// //   // { $$ = { type: 'THEREST', val: $THEREST, loc: toLoc(yyloc) } }
// //   | tag body
// //   { log('tag body', $$); }
// //   | punct
// //   { log('punct', $$); }
//   | block
//   // { log('block', $$); $$ = { type: 'block', val: $block } }
// //   | element body
// //   { log('element body', $$); }
// //   | element
// //   { log('element', $$); }
// //   | ID
// //   { log('ID', $$); $$ = { type: 'UNKNOWN ID', val: $ID, loc: toLoc(yyloc) } }
// //   | TEXT 
// //   { log('TEXT', $$); $$ = { type: 'text', val: $TEXT, loc: toLoc(yyloc) } }
//   | the_rest
//   | tag LINE_ENDING_WITH_DOT texts
//   { 
//     log('stmt: LINE_ENDING_WITH_DOT=', $LINE_ENDING_WITH_DOT); 
//     $$ = [{ type:'LINE_ENDING_WITH_DOT', val: $LINE_ENDING_WITH_DOT}, $texts ]
//   }
//   ;

// texts
//   : texts TEXT
//   { log('texts: texts TEXT', $$); $texts.push({ type: 'TEXT', val: $TEXT }); $$ = $texts  }
//   | TEXT
//   { log('texts: TEXT', $$); $$ = [{ type: 'TEXT', val: $TEXT }] }
//   ;

tag
  : TAG_NAME BODY
  { 
    log('tag: TAG_NAME BODY', $BODY); 
    $$ = { type: 'TAG', val: $TAG_NAME, rest: $BODY, loc: toLoc(yyloc) } 
  }
  | TAG_NAME ID_DECL BODY
  { 
    log('tag: TAG_NAME ID_DECL BODY', $BODY); 
    $$ = { type: 'TAG', val: $TAG_NAME, id: $ID_DECL, rest: $BODY, loc: toLoc(yyloc) } 
  }
  | TAG_NAME CLASSNAME_DECL BODY
  { 
    log('tag: TAG_NAME CLASSNAME_DECL BODY', $BODY); 
    $$ = { type: 'TAG', val: $TAG_NAME, class: $CLASSNAME_DECL, rest: $BODY, loc: toLoc(yyloc) } 
  }
  | TAG_NAME ATTRIBUTES BODY
  { 
    log('tag: TAG_NAME BODY', $BODY); 
    $$ = { type: 'TAG', val: $TAG_NAME, rest: $BODY, loc: toLoc(yyloc) } 
  }
  | TAG_NAME ID_DECL ATTRIBUTES BODY
  { 
    log('tag: TAG_NAME ID_DECL BODY', $BODY); 
    $$ = { type: 'TAG', val: $TAG_NAME, id: $ID_DECL, rest: $BODY, loc: toLoc(yyloc) } 
  }
  | TAG_NAME CLASSNAME_DECL ATTRIBUTES BODY
  { 
    log('tag: TAG_NAME CLASSNAME_DECL BODY', $BODY); 
    $$ = { type: 'TAG', val: $TAG_NAME, class: $CLASSNAME_DECL, rest: $BODY, loc: toLoc(yyloc) } 
  }
//   | TAG_START NEWLINE
//   { 
//     log('TAG_START NEWLINE', $TAG_START); 
//     $$ = { type: 'TAG', val: $TAG_START,  loc: toLoc(yyloc) } 
//   }
//   // | TAG_START PIPE_TEXT
//   // { 
//   //   log('TAG_START NEWLINE', $TAG_START); 
//   //   $$ = { type: 'TAG', val: $TAG_START,  loc: toLoc(yyloc) } 
//   // }
//   | ELEMENT_ID THEREST
//   { log('ELEMENT_ID', $$); $$ = { type: 'TAG', id: $ELEMENT_ID, rest: $THEREST, loc: toLoc(yyloc) } }
//   | ELEMENT_ID NEWLINE
//   { log('ELEMENT_ID', $$); $$ = { type: 'TAG', id: $ELEMENT_ID, loc: toLoc(yyloc) } }
  ;

// the_rest
//   : THEREST
//   { log('the_rest: THEREST', $$); $$ = { type: 'THEREST', val: $THEREST }  }
//   | LPAREN
//   | PIPE_TEXT
//   { log('the_rest: PIPE_TEXT', $$); $$ = { type: 'PIPE_TEXT', val: $PIPE_TEXT }  }
//   ;

// TEXT
//   : TEXT THEREST
//   { $TEXT.push($THEREST); $$ = $TEXT; }
//   ;

// element
//   : TAG
//   { log('TAG', $$); $$ = { type: 'TAG', val: $TAG, loc: toLoc(yyloc) } }
//   | tag_identifier
//   {log('tag_identifier', $$);  $$ = { type: 'TAG', tag_identifier: $tag_identifier, loc: toLoc(yyloc) } }
//   | TAG DOT
//   { log('TAG ' + $TAG  + ' DOT: setting isText to true');
//     isText = true; 
//     $$ = { type: 'TAG-DOT', val: $TAG, precedes: 'text', loc: toLoc(yyloc) } }
//   | TAG tag_identifier
//   { log('TAG tag_identifier', $$); $$ = { type: 'TAG', val: $TAG, tag_identifier: $tag_identifier, loc: toLoc(yyloc) } }
//   | TAG attributes
//   { log('TAG attributes', $TAG, $attributes); $$ = { type: 'TAG', val: $TAG, attributes: $attributes, loc: toLoc(yyloc) } }
//   | tag_identifier attributes
//   { log('tag_identifier attributes', $$); $$ = { tag_identifier: $tag_identifier, attributes: $attributes, loc: toLoc(yyloc) } }
//   | TAG DOT attributes
//   { log('TAG ' + $TAG  + ' DOT attributes: setting isText to true'); isText = true; $$ = { type: 'TAG-DOT', val: $TAG, precedes: 'text', attributes: $attributes, loc: toLoc(yyloc) } }
//   | TAG tag_identifier attributes
//   { log('TAG tag_identifier attributes', $$); $$ = { type: 'TAG', val: $TAG, tag_identifier: $tag_identifier, attributes: $attributes, loc: toLoc(yyloc) } }
//   | TAG attributes DOT
//   { log('TAG attributes DOT', $TAG, $attributes);
//     isText = true; 
//      $$ = { type: 'TAG', val: $TAG, attributes: $attributes, loc: toLoc(yyloc) } }
// 	;

// tag_identifier
//   : DOT ID
//   { log('DOT ID'); $$ = { type: 'tag_identifier', class: $ID, loc: toLoc(yyloc) } }
//   | DOT ID HASH ID
//   { log('DOT ID HASH ID'); $$ = { type: 'tag_identifier', class: $ID1, id: $ID2, loc: toLoc(yyloc) } }
//   | DOT ID HASH TAG
//   { log('DOT ID HASH TAG'); $$ = { type: 'tag_identifier', class: $ID, id: $TAG, loc: toLoc(yyloc) } }
//   ;

// attributes
//   : LPAREN anything RPAREN
//   { log('LPAREN anything RPAREN');
//   $$ = [$anything] }
//   ;

// anything
//   : anything THEREST
//   { log('anything THEREST', $$); $anything.push($THEREST); $$ = $anything }
// //   | anything KEYWORD
// //   { log('anything KEYWORD', $$); let v2 = [$anything].push($KEYWORD); $$ = v2  }
// //   | anything block
// //   { log('anything block', $$); let v3 = [$anything].push($block); $$ = v3  }
// //   | KEYWORD
// //   { log('KEYWORD', $$); }
//   | block
//   { log('block', $$); $$ = { type: 'BLOCK', val: $block } }
//   | THEREST
//   { log('THEREST', $$); $$ = { type: 'THEREST', val: $THEREST }  }
// //   // | ID
// //   // { log('ID', $$); }
// //   // | EQ
// //   // { log('EQ', $$); }
// //   // | DOT
// //   // { log('DOT', $$); }
//   ;

// // really
// //   : THEREST
// //   { log('THEREST', $$); }
//   // | ID
//   // { log('ID', $$); }
//   // | EQ
//   // { log('EQ', $$); }
//   // | STRING
//   // { log('STRING', $$); }
//   // | DOT
//   // { log('DOT', $$); }
//   // ;

// attr_list
//   : attr_list attribute
//   { log('attr_list attribute', $$); [$attr_list].push($attribute); $$ = $attr_list }
//   | attr_list attr_spacer attribute
//   { log('attr_list attr_spacer attribute', $$); [$attr_list].push($attribute); $$ = $attr_list }
//   | attribute
//   { log('attribute', $$); }
//   ;

// attr_spacer
//   : COMMA
//   { log('COMMA', $$); }
//   | ' '
// 	{ log('SPACE'); $$ = {type:'SPACE'} }
//   ;

// attribute
//   : ID EQ STRING
//   { log('attribute ID EQ STRING', $ID, $STRING);
//    $$ = { type: 'attribute', key: $ID, val: $STRING, loc: toLoc(yyloc) } }
//   | ID attr_spacer
//   { log('ID attr_spacer', $$); $$ = { type: 'attribute', key: $ID, loc: toLoc(yyloc) } }
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
//   { log('THEREST', $$); $$ = { type: 'BODY', val: $THEREST, loc: toLoc(yyloc) } }
//   ;

// punct
//   : LCURL
//   { log('LCURL', $$); $$ = { type: 'LEFT_CURLY_BRACKET', loc: toLoc(yyloc) } }
//   | RCURL
//   { log('RCURL', $$); $$ = { type: 'RIGHT_CURLY_BRACKET', loc: toLoc(yyloc) } }
//   | LSQR
//   { log('LSQR', $$); $$ = { type: 'LEFT_SQUARE_BRACKET', loc: toLoc(yyloc) } }
//   | RSQR
//   { log('RSQR', $$); $$ = { type: 'RIGHT_SQUARE_BRACKET', loc: toLoc(yyloc) } }
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

function log() {
  console.log(...arguments);
}

var isText = false;
var filename;
var stripDown = false;
var location = false;

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

function cleanEof() {
  while (this.topState() != 'INITIAL') {
    this.popState()
  }

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

function debug(str) {
  let stack = this.stack || [];
  function loggingEnabled() {
    // while(stack.hasElements()) {
    //   if (isEnabled(stack[0])) {
    //     stack.shift();
    //   }
    //   else {
    //     return false;
    //   }
    // }
    return true;
  }

  if (str == undefined) {
    if (loggingEnabled()) {
      console.log(stack.join(': '))
      stack.pop()
    }
  }
  else {
    stack.push(str);
    return debug.bind({stack: stack});
  }
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