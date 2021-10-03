%lex
id			[_?a-zA-Z]+[_a-zA-Z0-9-]+\b
newline [\r\n]
not_newline [^\r\n]
not_newline_nor_rparen [^\r\n)]
not_space [^ \t]

LETTER [a-zA-Z]


%x ATTRIBUTES

%%

{id} return 'ID'

{spc}+
%{
  const indentation3 = yytext.length
  debug('lex.__all__.spc_spc', 'yytext.length=' + indentation3 + (indentation3 < stack[0] ? ' <' : ' >=') + ' stack[0]=' + stack[0]);

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

  if (tokens3.length) {
    return tokens3;
  }
%}

<INITIAL>\s*<<EOF>>		%{
  debug('lex.')
  // remaining DEDENTs implied by EOF, regardless of tabs/spaces
  return cleanEof.apply(this)
%}	


<ATTRIBUTES>{not_newline_nor_rparen}+ 
%{
  debug('lex.ATTRIBUTES.not_newline', yytext)
  return 'ANYTHING'
%}
<ATTRIBUTES>{newline}+ 
%{
  debug('lex.ATTRIBUTES.newline')
  this.popState();
%}

{newline} return 'NEWLINE';
[^\n\r() ]+  return 'ANYTHING';

'('     %{
  console.log('Pushing state ATTRIBUTES')
    this.pushState('ATTRIBUTES')
    return 'LPAREN';
  %}

<ATTRIBUTES>')'    %{
    this.popState()
    return 'RPAREN';
  %}

/lex

%ebnf
%options case-insensitive

%% 

start
  : tag+ EOF
  ;

tag
  : tagname (classname)? (attributes)? body
  ;

body
  : 
  ;

classname
  : 
  ;

attributes
  : LPAREN ANYTHING RPAREN NEWLINE?
  ;

tagname
  : ID
  ;

%%

var stack = [0];
var stripDown = false;


function cleanEof() {
  // resetState.apply(this);
  console.log("cleanEof")

  var tokens = [];
  while (0 < stack[0]) {
    tokens.unshift("DEDENT");
    stack.shift();
  }
    
  // tokens.unshift('ENDOFFILE')
  console.log('returning ', tokens)
  if (tokens.length) {
    return tokens;
  }
}

function resetState() {
  while (this.topState() != 'INITIAL') {
    this.popState()
  }
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