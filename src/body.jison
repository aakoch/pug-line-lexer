/* TODO: Fix parsing of head.pug - line 48 is commented and indentation is wrong and the start of the if statement on 46 doesn't work 

TODO: TEXT lines aren't indented. Actually, not sure if I can even do ^^^.
*/

%lex

start_dot_text \.\s*\n\s*\|
tag_name			[a-zA-Z]+
id			[_?a-zA-Z]+[_a-zA-Z0-9-]*\b
spc			[\t \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]
newline [\r\n]
not_newline [^\r\n]
end_of_line_dot ((\.[\n\r])|(\.\s+[\n\r]))
classname_decl \.{id}+\b
id_decl #{id}+\b
line_ending_with_dot			.+(\.|\/\/)
tag_declaration_terminator [ \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000()]

%x ATTRIBUTES
%s TAG
%x TEXT
%x BODY_STATE
%x EXPECT_INDENT
%x PIPE_TEXT
%x DOT_TEXT_START

%%

<INITIAL>{tag_name} %{
  debug('lex')('INITIAL')('tag_name=' + yytext)();
  this.pushState('TAG'); 
  return 'TAG_NAME'
%}
<TAG>{start_dot_text} %{
  debug('lex')('start_dot_text=' + yytext)()
  return ['DOT', 'NEWLINE', 'INDENT', 'PIPE']
%}
<TAG>{spc} %{
  debug('lex')('TAG')('SPACE')()
  return 'SPACE'
%}
<TAG>\.\s*{newline} %{
  debug('lex')('TAG')('\\.\\s*{newline}')()
  this.pushState('DOT_TEXT_START'); 
  return ['NEWLINE']
%}
<TAG>'|' %{
  debug('lex')('TAG')('PIPE')()
  return 'PIPE'
%}
<TAG>({not_newline}|\|)+ %{
  debug('lex')('TAG')('not_newline=' + yytext)()
//   if (yytext.startsWith(' ')) {
//     debug('lex')('TAG')('starts with space')()
//     if (yy.lexer.input() == '\n') {
//       debug('lex')('TAG')("returning ['SPACE', 'TEXT', 'NEWLINE']")()
//       this.popState();
//       return ['SPACE', 'TEXT', 'NEWLINE']
//     }
//     else {
//       return ['SPACE', 'TEXT']
//     }
//   }
//   else {
//     debug('lex')('TAG')('does not start with space')()
    return 'TEXT'
//   }
%}
<TAG>{newline} %{
  debug('lex')('TAG')('newline')();
  this.popState();  return 'NEWLINE'
%}

'|'   this.pushState('TAG'); return 'PIPE'

<DOT_TEXT_START>^({spc}{spc}|\t)+
%{
  const _debug2 = debug('lex')('INITIAL')
  _debug2('space at beginning of line')();
  const indentation3 = yytext.length
  _debug2('indentation=' + indentation3)();

  if(indentation3 > stack[0]) {
    stack.unshift(indentation3)
    return 'INDENT'
  }

  let tokens3 = []

  while (indentation3 < stack[0]) {
    log("adding dedent on line", yylloc, stack)
    tokens3.unshift("DEDENT");
    stack.shift();
  }
  
  this.popState()
  this.popState()

  if (tokens3.length) {
    return tokens3;
  }
%}

<DOT_TEXT_START>{not_newline}+ return 'TEXT'
<DOT_TEXT_START>{newline} ;

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

/lex

%ebnf

%options token-stack

%%

start
	: lines ENDOFFILE
	{ debug('PARSE')('start')("AST: %j", $lines)(); }
	;

lines
  : lines line
  { 
    debug('PARSE')('lines')('lines line')('lines=', $lines)()
    debug('PARSE')('lines')('lines line')('line=', $line)()

    while (util.isArray($line) && $line.length == 1) {
      $line = $line[0]
    }

    // if (util.isArray($lines) && $lines.length == 1) {
    //   $lines[0].push($line); 
    // }
    // else {
      $lines.push($line); 
    // }

    $$ = $lines; 
    debug('PARSE')('lines')($lines.join(', '))()
  }
  | line
  { $$ = $line }
  ;

line
	: 
  | tag 
  { 
    debug('PARSE')('line')('tag=', $tag)(); 
    if (typeof $tag.body == 'array') {
      $$ = [$tag, $tag.body];
      $tag.body = undefined
    }
    else
      $$ = $tag
  }
	// | stmt NEWLINE
  // { log('line: stmt NEWLINE stmt=', $stmt); $$ = $stmt; }
  // | block
  // { debug('PARSE')('line')('block')() }
	;

tag
  : // TAG_NAME 
  // { $$ = { type: 'TAG', val: $TAG_NAME } }
  | TAG_NAME body
  { 
    debug('PARSE')('tag')('tag: TAG_NAME body', 'TAG_NAME=' + $TAG_NAME, $body)(); 
    
    // log('yyvstack[yysp - 0]', yyvstack[yysp - 0])
    // log('yyvstack[yysp - 1]', yyvstack[yysp - 1])
    // log('yyvstack[yysp - 2]', yyvstack[yysp - 2])
    // yyvstack.unshift({ type: 'TAG', val: $TAG_NAME, body: $body, loc: toLoc(yyloc) } )
    // $$ = $body

    if ($body.type == 'TEXT') {
     $$ = [
        { type: 'TAG', val: $TAG_NAME, body: $body.val, hint: 1, loc: toLoc(yyloc) }
     ]
    }
    else if ($body.type == 'NEWLINE') {
     $$ = [
        { type: 'TAG', val: $TAG_NAME, hint: 2, loc: toLoc(yyloc) }
      ]
    }
    else {
     $$ = [
        { type: 'TAG', val: $TAG_NAME, hint: 3, loc: toLoc(yyloc) }, 
        $body
      ]
    }
  }
  ;

block
	: INDENT lines DEDENT
	{ debug('PARSE')('block')('INDENT lines DEDENT', $lines)(); $$ = $lines; }
	| INDENT TEXT DEDENT
	{ debug('PARSE')('block')('INDENT TEXT DEDENT', $TEXT)(); $$ = { type: 'TEXT', val: $TEXT }; }
	| INDENT PIPE SPACE TEXT NEWLINE DEDENT
	{ debug('PARSE')('block')('INDENT PIPE TEXT DEDENT', $TEXT)(); $$ = { type: 'TEXT', val: $TEXT }; }
	;

body
  : // the body can be blank
  | block
  // { $$ = { body: $block } }
  | NEWLINE
  { $$ = { type: 'NEWLINE' }; }
  | SPACE TEXT NEWLINE
  { $$ = { type: 'TEXT', val: $TEXT }; }
  // | DOT NEWLINE block
  // { $$ = { type: 'TEXT', val: $block }; }
  | NEWLINE block
  { $$ = $block; }
  // | DOT NEWLINE INDENT TEXT DETENT
  // | NEWLINE INDENT PIPE TEXT DETENT
  ;

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

function debug(arg0, ...args) {
  let stack = this.stack || [];
  function loggingEnabled() {
    let i = 0;
    while(i < stack.length) {
      if (!isEnabled(stack)) {
        return false;
      }
      i++
    }
    return true;
  }

  if (arg0 == undefined) {
    if (loggingEnabled()) {
      // console.log('logging enabled ***********')
      // console.log(stack.map(l => {
      //   if (util.isArray(l)) {
      //     return util.inspect(i)
      //   }
      //   else {
      //     return l.toString()
      //   }
      // }).join(': '))
      // stack.pop()
      console.log(stack.slice(0, 2).join(': ') + ': ' + util.inspect(stack.slice(2), {depth:5}))
    }
    else {
      // console.log('logging not enabled. stack=' + stack.join(', '))
    }
  }
  else {
    if (!!args && args.length)
      stack.push(arg0, util.inspect(args, {depth:5}));
    else
      stack.push(arg0);
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
    } catch (e) { /* ignore crashes; 
    output MAY not be serializable! We are a generic bit of code, after all... */ }
    var rv = 0;
    if (typeof dst === 'number' || typeof dst === 'boolean') {
        rv = dst;
    }
    return dst;
};