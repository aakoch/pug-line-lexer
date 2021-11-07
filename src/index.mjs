import parser from './main.mjs'
import inlineParser from './inline.mjs'

console.log('es parser', parser.Parser)

export default {
  parser: parser.parser,
  Parser: parser.Parser,
  parse: parser.parse,
  inlineParser
}