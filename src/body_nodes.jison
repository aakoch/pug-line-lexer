/* 
 Works great with nodes.pug. I haven't tried anything else.
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
%s TEXT
%s BODY_STATE
%x EXPECT_INDENT
%x PIPE_TEXT
%x DOT_TEXT_START
%x RAW_TEXT_ELEMENT

%%


// Raw text elements
('script'|'style') %{
  this.pushState('RAW_TEXT_ELEMENT')
  return 'RAW_TEXT_ELEMENT_NAME'
%}

<RAW_TEXT_ELEMENT>(?![\(\n ]{not_newline})+ %{
  debug('lex.RAW_TEXT_ELEMENT', 'yytext=', yytext);
  if (yytext.length > 0)
    return 'TEXT'
  else 
    this.popState()
%}

<RAW_TEXT_ELEMENT>{newline} %{
  return 'NEWLINE'
%}

<RAW_TEXT_ELEMENT>{attributes}  return 'ATTRIBUTES'

<RAW_TEXT_ELEMENT>^({spc}{spc}|\t)+
%{
  console.log('lex.RAW_TEXT_ELEMENT.indent');
  const indentation4 = yytext.length

  if(indentation4 > stack[0]) {
    stack.unshift(indentation4)
    this.pushState('RAW_TEXT')
    return 'INDENT'
  }

  let tokens4 = []

  while (indentation4 < stack[0]) {
    tokens4.unshift("DEDENT");
    stack.shift();
  }
  
  this.popState()
  this.popState()
  dotIs = false; 

  if (tokens4.length) {
    return tokens4;
  }
%}

<RAW_TEXT>\s+
%{
  console.log('lex.RAW_TEXT \\s+');
  const indentation5 = yytext.length

  debug('lex.RAW_TEXT', 'indentation5=' + indentation5, 'stack[0]=' + stack[0], 'yytext=' + yytext)

  if(indentation5 > stack[0]) {
    stack.unshift(indentation5)
    this.pushState('RAW_TEXT')
    return 'INDENT'
  }

  let tokens5 = []

  while (indentation5 < stack[0]) {
    tokens5.unshift("DEDENT");
    stack.shift();
    this.popState()
  }

  if (tokens5.length) {
    return tokens5;
  }
%}

<RAW_TEXT>\S+
%{
  console.log('lex.RAW_TEXT \\S+');
  return 'TEXT'
%}



{attributes}  return 'ATTRIBUTES'

<BODY_STATE>{not_newline}+ %{
  debug('lex.BODY_STATE', 'not_newline=' + yytext);
  return 'TEXT'
%}

<BODY_STATE>{newline}+ %{
  debug('lex.BODY_STATE', 'newline');
  this.popState()
%}

'|' %{
  debug('lex', 'pipe');
  this.pushState('BODY_STATE')
%}

<INITIAL>{not_spc_nor_newline_nor_pipe_nor_parens}+ %{
  debug('lex.INITAL.not_spc_nor_newline_nor_pipe_nor_parens', 'yytext=' + yytext);
  // this.pushState('TAG'); 
  dotIs = yytext.endsWith('.');

  if (tagLines.includes(yytext)) {
    this.pushState('BODY_STATE')
    return 'TAG_NAME'
  }
  else 
    return 'NAME'
%}
// <TAG>{start_dot_text} %{
//   debug('lex')('start_dot_text=' + yytext)()
//   return ['DOT', 'NEWLINE', 'INDENT', 'PIPE']
// %}
{newline} %{
  this.popState()
%}

^({spc}{spc}|\t)+
%{
  const indentation3 = yytext.length

  if(indentation3 > stack[0]) {
    stack.unshift(indentation3)
    if (this.topState() != 'RAW_TEXT_ELEMENT')
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
  // remaining DEDENTs implied by EOF, regardless of tabs/spaces
  return cleanEof.apply(this)
%}	

{spc} %{
  return 'SPACE'
%}

<TEXT>{not_newline}+ return 'TEXT';
<TEXT>{newline} this.popState(); return 'NEWLINE'

/lex

%ebnf

%options token-stack

%%

start
	: nodes ENDOFFILE
	{ debug('parse.start.nodes', "AST: %j", $nodes); }
	;

node
  // : name
  // { $$ = { type: 'node', name: $name, hint: 1, children: [] } }
  : NAME
  {
    debug('parse.name.NAME', $NAME)
  { $$ = { type: 'text', name: $NAME, hint: 1 } }
  }
  | name children
  {
    if ($name.startsWith('|')) {
      debug('parser.node.name_children', 'merging pipe', $name);
      debug('parser.node.name_children', 'removing node', $children);
      $$ = { type: 'text', name: $children.name, hint: 5, children: $children.children } 
    }
    else if ($name.trim().endsWith('.')) {
      $$ = { type: 'node', name: $name.slice(0, -1), hint: 7, children: $children.map(child => {
        child.type = 'text'
        return child
      }) } 
    }
    else {
      if (util.isArray($children)) {
        $$ = { type: 'node', name: $name, hint: 4, children: $children } 
      }
      else {
        // if ($children.type == 'text') 
        // $$ = { type: 'node', name: $name, hint: 21, children: [$children] } 
        // else
        debug('parser.node.name_children', '1merging pipe', $name);
        debug('parser.node.name_children', '1removing node', $children);
        $$ = { type: 'text', name: $name + ' ' + $children.name, hint: 20, children: $children.children }
      }
    }
  } 
  | TAG_NAME
  {
    debug('parse.node.TAG_NAME', $TAG_NAME)
    $$ =  { type: 'tag', val: $TAG_NAME }
  }
  | RAW_TEXT_ELEMENT_NAME NEWLINE INDENT TEXT DEDENT
  {
    debug('parse.node.RAW_TEXT_ELEMENT_NAME', $RAW_TEXT_ELEMENT_NAME)
    $$ =  { type: 'tag', val: $RAW_TEXT_ELEMENT_NAME, children: $TEXT }
  } 
  | RAW_TEXT_ELEMENT_NAME ATTRIBUTES NEWLINE INDENT texts DEDENT
  {
    debug('parse.node.RAW_TEXT_ELEMENT_NAME_ATTRIBUTES', $RAW_TEXT_ELEMENT_NAME)
    $$ =  { type: 'tag', val: $RAW_TEXT_ELEMENT_NAME, attrs: $ATTRIBUTES, children: $texts }
  }
  | TAG_NAME ATTRIBUTES
  {
    debug('parse.node.TAG_NAME', $TAG_NAME)
    $$ =  { type: 'tag', val: $TAG_NAME, attrs: $ATTRIBUTES }
  }
  | TAG_NAME children
  {
    if (util.isArray($children)) {
      $$ = { type: 'tag', val: $TAG_NAME, hint: 14, children: $children } 
    }
    else {
      $$ = { type: 'tag', val: $TAG_NAME, hint: 12, children: [$children] } 
    }
  } 
  | TAG_NAME ATTRIBUTES children
  {
    if (util.isArray($children)) {
      $$ = { type: 'tag', val: $TAG_NAME, hint: 14, children: $children, attrs: $ATTRIBUTES } 
    }
    else {
      $$ = { type: 'tag', val: $TAG_NAME, hint: 12, children: [$children], attrs: $ATTRIBUTES } 
    }
  } 
  | TEXT
  {
    $$ = { type: 'text', name: $TEXT, hint: 2 }
  } 
	;

texts
  : texts TEXT
  | TEXT
  ;

children
  : INDENT nodes DEDENT
  { $$ = $nodes }
  | SPACE node
  { $$ = $node }
  | TEXT
  { $$ = { type: 'text', val: $TEXT } }
  // { $$ = [{ type: 'text', val: $TEXT, children: [] }] }
  // | DOT children
  // { $$ = [{ type: 'text', val: $children, children: [] }] }
  ;

nodes
  : nodes node
  {
    debug('parse.nodes.nodes_node', 'nodes=', $nodes, 'node=',  $node)
    if (util.isArray($nodes)) {
      $nodes.push($node);
      $$ = $nodes;
    }
    else { 
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

name
  : NAME
  {
    debug('parse.name.NAME', $NAME)
    // $$ =  { name: $NAME, children: [] }
  }
  ;


%% 

const fs = require('fs')
const tagLines = fs.readFileSync('all_tags.txt', 'utf-8').split('\n')
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
      // if (l.toUpperCase() == stack[i].toUpperCase()) 
      //   console.log(`l=${l}, stack[${i}]=${stack[i]}, l.toUpperCase() == stack[i].toUpperCase()=${l.toUpperCase() == stack[i].  toUpperCase()}`)
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
    console.log(arguments[0])
    console.group()
    Array.from(arguments).slice(1).forEach(arg => {
      console.log(util.inspect(arg, false, 10))
    })
    console.groupEnd()
  }
}

function handleWhitespace(yytext) {
  const indentation4 = yytext.length

  if(indentation4 > stack[0]) {
    stack.unshift(indentation4)
    if (this.topState() != 'RAW_TEXT_ELEMENT')
      return 'INDENT'
  }

  let tokens4 = []

  while (indentation4 < stack[0]) {
    tokens4.unshift("DEDENT");
    stack.shift();
  }
  
  this.popState()
  this.popState()
  dotIs = false; 

  if (tokens4.length) {
    return tokens4;
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