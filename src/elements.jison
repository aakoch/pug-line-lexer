/* 
 I was trying to dial in the handling of plain text. 
 
 Last div is not in the correct depth

 TODO: npx jison -o build/elements.cjs --main src/elements.jison  && node build/elements.cjs /Users/aakoch/projects/adamkoch.com/nodes.pug

*/

%lex

start_dot_text \.\s*\n\s*\|
tag_name			[a-zA-Z]+
id			[_?a-zA-Z]+[_a-zA-Z0-9-]*\b
spc			[\t \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]
not_spc_nor_newline			[^\n\r\t \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]
not_spc_nor_newline_nor_pipe 		[^|\n\r\t \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]
not_spc_nor_newline_nor_pipe_nor_parens 		[^()|\n\r\t \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]
newline [\r\n]
attributes \([^\r\n]+\)
not_newline [^\r\n]
end_of_line_dot ((\.[\n\r])|(\.\s+[\n\r]))
classname_decl \.{id}+\b
id_decl #{id}+\b
line_ending_with_dot			.+(\.|\/\/)
tag_declaration_terminator [ \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000()]


%x ATTRIBUTES
%s TAG
%s TEXT_STATE
%s BODY_STATE
%x EXPECT_INDENT
%x PIPE_TEXT
%x DOT_TEXT_START

%%


{attributes}  return 'ATTRIBUTES'
<TEXT_STATE>^({spc}*)([^\n\r]+) %{
  debug('lex.TEXT_STATE', 'beginning of line=' + yytext);
  debug('lex.TEXT_STATE', 'matches[1].length=' + this.matches[1].length);
  
  const indentation5 = this.matches[1].length;
  debug('lex.TEXT_STATE', 'stack[0]=' + stack[0]);

  yytext = yytext.trim()
  if(indentation5 < stack[0]) {
    this.popState();
    stack.shift()
    debug('lex.TEXT_STATE', 'popping state and returning "NAME"')
    return 'NAME'
  }
  else {
    debug('lex.TEXT_STATE', 'keeping state and returning "TEXT"')
    return 'TEXT'
  }
%}
<TEXT_STATE>{newline} %{
  debug('lex.TEXT_STATE', 'newline');
%}

<TEXT_STATE>({spc}{spc}|\t)+
%{
  debug('lex.TEXT_STATE', 'indent of length ' + yytext.length);
  debug('lex.TEXT_STATE', 'stack ' + stack);
  const indentation4 = yytext.length

  if(indentation4 > stack[0]) {
    stack.unshift(indentation4)
    return 'INDENT'
  }

  let tokens4 = []

  while (indentation4 < stack[0]) {
    tokens4.unshift("DEDENT");
    stack.shift();
  }
  
  if (tokens4.length) {
    return tokens4;
  }
%}

<TEXT_STATE>\s*<<EOF>>		%{
  debug('lex.TEXT_STATE to EOF')
  // remaining DEDENTs implied by EOF, regardless of tabs/spaces
  return cleanEof.apply(this)
%}	

<BODY_STATE>(?!{spc}+|\t)[^.\n\r]+(?<!\.\n) %{
  debug('lex.BODY_STATE', 'TEXT=' + yytext);
  return 'TEXT'
%}

<BODY_STATE>\.\s*{newline}+ %{
  debug('lex.BODY_STATE', 'dot-newline');
  this.popState()
  this.pushState('TEXT_STATE')
  stack.unshift(stack[0] + 2);
  // return 'NEWLINE'
%}

// \s* for times when there is an extra space at the end of the line
<BODY_STATE>\s*{newline}+ %{
  debug('lex.BODY_STATE', 'newline');
  this.popState()
  // return 'NEWLINE'
%}

<BODY_STATE>'.' %{
  debug('lex.BODY_STATE.DOT');
  return 'DOT'
%}

<BODY_STATE>\s*<<EOF>>		%{
  debug('lex.BODY_STATE to EOF')
  // remaining DEDENTs implied by EOF, regardless of tabs/spaces
  return cleanEof.apply(this)
%}	

'|' %{
  debug('lex.pipe');
  stack.unshift(stack[0] + 2);
  this.pushState('TEXT_STATE')
%}

<INITIAL>^{tag_name}+ %{
  debug('lex.INITAL', 'tag_name=' + yytext);

  if (tagLines.includes(yytext)) {
    this.pushState('BODY_STATE')
    return 'TAG_NAME'
  }
  else 
    return 'NAME'
%}

<INITIAL>(?!{spc}{spc}|\t).+ %{
  debug('lex.INITAL', '(?!{spc}{spc}|\\t).+=' + yytext);
  dotIs = yytext.endsWith('.');

  if (tagLines.includes(yytext)) {
    this.pushState('BODY_STATE')
    return 'TAG_NAME'
  }
  else 
    return 'NAME'
%}

{newline} %{
  debug('lex.__all__.newline')
  this.popState()
%}

^({spc}{spc}|\t)+
%{
  debug('lex.__all__.spc_spc', 'indent of length ' + yytext.length);
  const indentation3 = yytext.length

  if(indentation3 > stack[0]) {
    stack.unshift(indentation3)
    return 'INDENT'
  }

  let tokens3 = []

  while (indentation3 < stack[0]) {
    tokens3.unshift("DEDENT");
    stack.shift();
  }
  
  this.popState()
  this.popState()
  dotIs = false; 

  if (tokens3.length) {
    return tokens3;
  }
%}


<INITIAL>\s*<<EOF>>		%{
  debug('lex.')
  // remaining DEDENTs implied by EOF, regardless of tabs/spaces
  return cleanEof.apply(this)
%}	

{spc} %{
  debug('lex.__all__.spc')
  return 'SPACE'
%}

/lex

%ebnf

%options token-stack

%%

start
	: nodes ENDOFFILE
	{ debug('parse.start.nodes', "AST: %j", $nodes); }
	;

nodes
  : nodes node
  {
    debug('parse.nodes.nodes_node', 'nodes=' + util.inspect($nodes), 'node=' + util.inspect($node))
    if (util.isArray($nodes)) {
      debug('parse.nodes.nodes_node', 'nodes is an array, so we are pushing')
      $nodes.push($node);
      $$ = $nodes;
    }
    else { 
      debug('parse.nodes.nodes_node', 'nodes is an object, so we are using children')
      $nodes.children = [$node]
      $$ = $nodes;
    }
  }
  | node
  { 
    debug('parse.nodes.node', 'node=', $node)
    $$ = [$node] 
  }
  ;

node
  : 
  | NAME
  {
    debug('parse.node.NAME', $NAME)
    $$ = { type: 'text', name: $NAME.trim(), hint: 1, loc: toLoc(yyloc) }
  }
  | NAME INDENT nodes DEDENT
  {
    debug('parse.node.NAME_INDENT_nodes_DEDENT', $NAME, $nodes)
    let type = 'node'
    if ($NAME.startsWith('|')) {
      type = 'text'
    }
    else if ($NAME.trim().endsWith('.')) {
      type = 'text'
    }
    $$ = { type: type, name: $NAME, hint: 2, children: $nodes, loc: toLoc(yyloc) } 
  } 
  | TAG_NAME
  {
    debug('parse.node.TAG_NAME', $TAG_NAME)
    $$ =  { type: 'tag', val: $TAG_NAME, hint: 32, loc: toLoc(yyloc) }
  }
  | TAG_NAME ATTRIBUTES
  {
    debug('parse.node.TAG_NAME_ATTRIBUTES', $TAG_NAME, $ATTRIBUTES)
    $$ =  { type: 'tag', val: $TAG_NAME, attrs: $ATTRIBUTES, hint: 32, loc: toLoc(yyloc) }
  }
  | TAG_NAME TEXT
  {
    debug('parse.node.TAG_NAME_TEXT', $TAG_NAME, $TEXT)
    $$ =  { type: 'tag', val: $TAG_NAME, children: [{ type: 'text', name: $TEXT.trim(), hint: 21 }], loc: toLoc(yyloc) }
  } 
  // added for text that ended the line with a period
  | TAG_NAME TEXT DEDENT
  {
    debug('parse.node.TAG_NAME_TEXT_DEDENT', $TAG_NAME, $TEXT)
    $$ =  { type: 'tag', val: $TAG_NAME, children: [{ type: 'text', name: $TEXT.trim(), hint: 21 }] }
  } 
  | TAG_NAME SPACE TEXT
  {
    debug('parse.node.TAG_NAME_SPACE_TEXT', $TAG_NAME, $TEXT)
    $$ =  { type: 'tag', val: $TAG_NAME, children: [{ type: 'text', name: $TEXT.trim(), hint: 31 }], loc: toLoc(yyloc) }
  } 
  | node TEXT
  {
    debug('parse.node.TEXT', $node, $TEXT)
    $node.children = ($node.children || []).concat({ type: 'text', name: $TEXT.trim(), hint: 41, loc: toLoc(yyloc) });
    $$ = $node
  }
  // for cases where text is the last statement with no newlin
  | node TEXT DEDENT
  {
    debug('parse.node.TEXT', $node, $TEXT)
    $node.children = ($node.children || []).concat({ type: 'text', name: $TEXT.trim(), hint: 41 });
    $$ = $node
  }
  | INDENT nodes DEDENT
  { 
    debug('parse.node.INDENT_nodes_DEDENT', $nodes)
    $$ = $nodes 
  }
	;



%% 

const fs = require('fs')
const tagLines = fs.readFileSync('/Users/aakoch/projects/new-foo/workspaces/parser-generation/all_tags.txt', 'utf-8').split('\n')
const tags = tagLines.join('|')
// console.log(tags)
var stack = [0];
var dotIs = false;

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

let enabledLogStack = ['PARSE', 'lines']
function isEnabled(stack) {
  let i = 0
  return enabledLogStack.every(l => {
    if (util.isArray(l)) {
      return l.map(t => t.toUpperCase()).contains(stack[i++])
    }
    else {
      return l.toUpperCase() == stack[i++].toUpperCase()
    }
  })
}

const logLevels = {
  '': true,
  'lex': true,
  'parse': true,
  'parser': true
}

function isEnabled(pkg) {
  function findNearestLogLevel(pkg) {
    while(!logLevels.hasOwnProperty(pkg)) {
      pkg = pkg.substring(0, pkg.lastIndexOf('.') || 0)
    }
    return logLevels[pkg]
  }
  return findNearestLogLevel(pkg);
}

function debug() {
  if (isEnabled(arguments[0])) {
    console.log(arguments[0], ...Array.from(arguments).slice(1))
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
    } catch (e) { /* ignore crashes; 
    output MAY not be serializable! We are a generic bit of code, after all... */ }
    var rv = 0;
    if (typeof dst === 'number' || typeof dst === 'boolean') {
        rv = dst;
    }
    return dst;
};