/* Pug attributes */

/* lexical grammar */
%lex

// ID          [A-Z-]+"?"?
// NUM         ([1-9][0-9]+|[0-9])
space  [ \u00a0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200a\u200b\u2028\u2029\u3000]
quote  ['"]


%x AFTER_OP
%x QUOTE_STARTED_WITH_SINGLE
%x QUOTE_STARTED_WITH_DOUBLE
%x OBJ_STARTED
%x ASSIGNMENT_STATE

%%

'='
%{
  this.pushState('AFTER_OP')
                                          return 'OP'
%}
<AFTER_OP>{space}
%{
  this.popState()
  this.pushState('ASSIGNMENT_STATE')
                                          return 'ASSIGNMENT'
%}
<AFTER_OP>'{'
%{
  this.popState()
  this.pushState('OBJ_STARTED')
                                          return 'LCURLY'
%}
<AFTER_OP,OBJ_STARTED>'}'
%{
  this.popState()
                                          return 'RCURLY'
%}
<INITIAL,AFTER_OP>{space}
%{
    this.popState()
                                          return 'SPACE'
%}
<INITIAL,AFTER_OP>','                                        return 'COMMA'
<INITIAL,AFTER_OP>'['
%{
  this.popState()
                                            return 'OPEN_BRACKET'
%}
<INITIAL,AFTER_OP>']'
%{
  this.popState()
                                            return 'CLOSE_BRACKET'
%}
<INITIAL,AFTER_OP>('"'|"'")
%{
  this.popState()
  debug('quote started with "' + yytext + '"')
  if (yytext == '\'') {
    this.pushState('QUOTE_STARTED_WITH_SINGLE')
  }
  else {
    this.pushState('QUOTE_STARTED_WITH_DOUBLE')
  }
                                           return 'QUOTE'
%}
<INITIAL>[^=+, ]+                             return 'ID'
<AFTER_OP>[^\[\]]+                         return 'VARIABLE'
<QUOTE_STARTED_WITH_SINGLE>[^']+                      return 'VAL'
<QUOTE_STARTED_WITH_SINGLE>"'"
%{
    this.popState()
                                           return 'QUOTE'
%}
<QUOTE_STARTED_WITH_DOUBLE>[^"]+                      return 'VAL'
<QUOTE_STARTED_WITH_DOUBLE>'"'
%{
    this.popState()
                                           return 'QUOTE'
%}
// <OBJ_STARTED>([^}\s])+\s*(?<=':')                         return 'KEY'
// <OBJ_STARTED>(?=':')\s*([^}\s])+                         return 'VAL'
// <OBJ_STARTED>{space}+                                   return
<OBJ_STARTED>','                                                                        return 'COMMA'
<OBJ_STARTED>{quote}?([^\:\'\"]+){quote}?{space}*':'{space}*{quote}([^\'\"]+){quote}?     return 'KEY_VAL'
<OBJ_STARTED>{quote}?([^\:\'\"]+){quote}?{space}*':'{space}*(\d+)               return 'KEY_DIG'
<OBJ_STARTED>{quote}?([^\:\'\"]+){quote}?{space}*':'{space}*('true'|'false')     return 'KEY_BOOL'

<ASSIGNMENT_STATE>'('
%{
  debug(`<ASSIGNMENT_STATE>'('`)
  debug('yytext=' + yytext)
  parens.push('(')
                                                      return 'VAL'
  ')))' // syntax highlighting hack
%}
<ASSIGNMENT_STATE>[^()]+
%{        
  debug(`<ASSIGNMENT_STATE>[^)]+`)
  debug('yytext=' + yytext)
                                                       return 'VAL'
%}
<ASSIGNMENT_STATE>')' 
%{
  debug(`<ASSIGNMENT_STATE>')'`)
  debug('yytext=' + yytext)
  debug('parens.length=' + parens.length)
  if (parens.length) {
    parens.pop()
                                                      return 'VAL'
  }
  else {
    this.popState()
                                                      return 'RPAREN'
  }
%}
'+'                                                   return 'ASSIGNMENT'

/lex

%ebnf
%options token-stack 

%% 

start
  : EOF
  | attrs EOF
  ;

attrs
  : attrs SPACE attr
  {
    $attrs.push($attr)
    $$ = $attrs
  }
  | attr
  {
    $$ = [$attr]
  }
  | attrs COMMA attr
  {
    $attrs.push($attr)
    $$ = $attrs
  }
  ;

attr
  : ID OP val
  {
    debug('attr: ID OP val: ID=', $ID, ', OP=', $OP, ', val=', $val)
    $$ = { key: $ID, val: $val }
  } 
  | ID spaces OP val
  {
    debug('attr: ID OP val: ID=', $ID, ', OP=', $OP, ', val=', $val)
    $$ = { key: $ID, val: $val }
  }
  | ID OP ASSIGNMENT VAL+ RPAREN?
  {
    debug('attr: ID OP ASSIGNMENT VAL+: ID=', $ID, ', OP=', $OP, ', ASSIGNMENT=', $ASSIGNMENT)
    $$ = { assignment: true, key: $ID, val: $4.join('') }
  }
  | ID spaces OP spaces val
  {
    debug('attr: ID spaces OP spaces val: ID=', $ID, ', OP=', $OP, ', val=', $val)
    $$ = { assignment: true, key: $ID, val: $4.join('') }
  }
  | ID OP VARIABLE
  {
    $$ = { key: $ID, assignment: true, val: $VARIABLE }
  }
  | ID OP val ASSIGNMENT SPACE* ID
  {
    debug('$0=', $0)
    debug('attr: ASSIGNMENT SPACE* ID: ASSIGNMENT=', $ASSIGNMENT, ', ID=', $3)
    // $-1['val'] = '"' + $-1.val + '" ' + $ASSIGNMENT + $3
    $$ = {}
  }
  ;

val
  : QUOTE VAL QUOTE
  {
    debug('val: VAL: VAL=', $VAL)
    $$ = $VAL
  }
  | OPEN_BRACKET list CLOSE_BRACKET
  {
    debug('val: OPEN_BRACKET list CLOSE_BRACKET')
    $$ = $list.join(' ')
  }
  | obj
  {
    debug('val: obj: obj=', $obj)
    // this could be improved...
    $$ = _.map(_.filter($obj, (obj) => _.values(obj)[0]), (obj2) => _.keys(obj2)[0]).join(' ')
    debug('val: obj: $$=', $$)
  }
  ;

obj
  : LCURLY key_value_pairs RCURLY
  {
    // {foo: true, bar: false, baz: true}
    debug('$key_value_pairs=', $key_value_pairs)
    $$ = $key_value_pairs
    // let obj = JSON.parse('{' + $key_value_pairs + '}')
    // debug('obj=', obj)
  }
  ;

key_value_pairs
  : key_value_pairs COMMA key_value_pair
  {
    if ($key_value_pair != null) {
      $key_value_pairs.push($key_value_pair)
    }
    $$ = $key_value_pairs
  }
  | key_value_pair
  {
    $$ = [$key_value_pair]
  }
  ;

key_value_pair
  : KEY SPACE* COLON SPACE* VAL
  | KEY_VAL
  | KEY_DIG
  | KEY_BOOL
  {
    let [key, value] = $KEY_BOOL.split(':')
    $$ = {}
    $$[key.trim()] = value.trim().toLowerCase() == 'true'
    // let [val, shouldUse] = $KEY_BOOL.split(':')
    // debug('val=', val.trim())
    // debug('shouldUse=', shouldUse.trim())
    // if (shouldUse.trim() == 'true') {
    //   $$ = val
    // }
    // else {
    //   $$ = null
    // }
  }
  ;

list
  : list list_item
  {
    $list.push([$list_item].flat()[0])
    $$ = $list
  }
  | list_item
  {
    $$ = [ $list_item ]
  }
  ;

list_item
  : QUOTE VAL QUOTE COMMA SPACE?
  {
    debug('list_item: QUOTE VAL QUOTE COMMA SPACE?: VAL=', $VAL)
    $$ = $VAL
  }
  | QUOTE VAL QUOTE
  {
    debug('list_item: QUOTE VAL QUOTE: VAL=', $VAL)
    $$ = $VAL
  }
  ;

spaces
  : 
  | spaces SPACE
  | SPACE
  ;

%% 
__module_imports__

const TEXT_TAGS_ALLOW_SUB_TAGS = true

const debug = debugFunc('pug-line-lexer:attrs')

let tagAlreadyFound = false
let obj
var lparenOpen = false
const keysToMergeText = ['therest']
const quoteStack = []
const parens = []

parser.main = function () {
  
  tagAlreadyFound = false
  lparenOpen = false

  function test(input, expected, strict = true ) {
    tagAlreadyFound = false
    lparenOpen = false
    debug(`\nTesting '${input}'...`)
    var actual = parser.parse(input)
    debug(input + ' ==> ', util.inspect(actual))
    
    let compareFunc
    if (strict)
      compareFunc = assert.deepEqual
    else 
      compareFunc = dyp

    compareFunc.call({}, actual, expected)
  }

test(`class=['foo', 'bar', 'baz']`, [{ key: 'class', val: 'foo bar baz' }])
test(`class='bar'`, [{ key: 'class', val: 'bar' }])
test(`class={foo: true, bar: false, baz: true}`, [{ key: 'class', val: 'foo baz' }])
test(`v-for="item in items" :key="item.id" :value="item.name"`, [{
  key: "v-for",
  val: "item in items"
}, {
  key: ":key",
  val: "item.id"
}, {
  key: ":value",
  val: "item.name"
}])

test(`class= (tags || []).map((tag) => tag.replaceAll(" ", "_")).join(" ")`, [{
  assignment: true,
  val: `(tags || []).map((tag) => tag.replaceAll(" ", "_")).join(" ")`,
  key: 'class'
}])

// url is a variable in a mixin
test(`href=url`, [
    { key: 'href', assignment: true, val: 'url' }
  ])

// I'm not supporting this right now
// test(`href='/user/' + id, class='button'`, [{
//   key: 'href',
//   assignment: true,
//   val: '"/user/" + id'
// },
// {key: 'class', val: 'button'}])

// test(`class = ['class1', 'class2']`, [{ key: 'class', val: 'class1 class2'}])

};

