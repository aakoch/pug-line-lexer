const parser = require('./main.cjs')
const inlineParser = require('./inline.cjs')

console.log('common parser', parser)

exports.parser = parser.parser
exports.Parser = parser.Parser
exports.parse = parser.parse
exports.main = parser.main

exports.inlineParser = inlineParser