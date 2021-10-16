import fs from 'fs'
import path, { parse } from 'path'
import stream from 'stream'
import util from 'util'
// import deepFilter from 'deep-filter';
// import objectify from 'through2-objectify'
import concat from 'concat-stream'
import indentTransformer from '../indent-transformer/index.js';
import nestingTransformer from '../pug-parsing-transformer/index.js';
import WrapLine from '@jaredpalmer/wrapline'

import parser from './build/stream_reader_helper.cjs'
// import parser from './build/flex_stream_reader_helper.cjs'
import debugFunc from 'debug'
import commandLineUsage from 'command-line-usage'

const optionDefinitions = [
  {
    name: 'out', alias: 'o', type: String, defaultValue: '-',
    description: 'Output file or \'-\' for stdout (default)'
  },
  {
    name: 'help', alias: 'h', type: Boolean, 
    description: 'Print this usage guide.'
  }
]

import commandLineArgs from 'command-line-args'
const options = commandLineArgs(optionDefinitions)
let nestingTransformer = {}

if (options.help || (typeof options.in === 'undefined' && !process.stdin)) {
  const sections = [
    {
      header: 'Pug Parser',
      content: 'Parses a Pug file and outputs an AST'
    },
    {
      header: 'Usage',
      content: 'node stream_reader.js [-h] [inFile] [-o outFile]'
    },
    {
      header: 'Options',
      optionList: optionDefinitions
    }
  ]
  const usage = commandLineUsage(sections)
  console.log(usage)

}
else {
  String.prototype.quote = function () {
    return this.replaceAll('\\', '\\\\').replaceAll('"', '\\\"')
  }

  if (typeof String.fill !== 'function') {
    String.fill = function (length, char) {
      return ''.padStart(length, char || ' ')
    }
  }

  stream.finished(process.stdin, (err) => {
    if (err) {
      console.error('Stream failed', err);
    } else {
      indentTransformer.ended = true
      nestingTransformer.ended = true
    }
  });

  nestingTransformer = new stream.Transform({
    decodeStrings: false,
    encoding: 'utf-8',
    flush(callback) {
      while (this.stack.length > 0) {
        this.push(this.stack.pop().symbol)
      }
      callback()
    },
    transform(str, enc, callback) {
      try {
        const lines = str.split('\n')
        lines.filter(line => line.length).forEach(line => {
          this.push(doStuff.call(this, line))
        })
        callback();
      }
      catch (e) {
        e.lineNo = (this != undefined ? this.lineNo : 'unknown')
        console.error('\nUnparsable string: ' + str)
        console.trace()
        callback(e)
      }
    }
  })
  nestingTransformer.first = true;
  nestingTransformer.currentIndent = 0;
  nestingTransformer.state = []
  nestingTransformer.stack = {
    internalArr: [],
    debug: debugFunc('stack'),
    push: function (txt) {
      // this.debug('pushing: ', txt)
      this.length++
      // this.debug('length: ', this.length)
      this.internalArr.push(txt)
    },
    pop: function () {
      let txt = this.internalArr.pop()
      // this.debug('popping: ', txt)
      this.length--
      // this.debug('length: ', this.length)
      return txt
    },
    length: 0
  }
  nestingTransformer.lineNo = 0
  nestingTransformer.stack.push({ symbol: ']' })
  nestingTransformer.buffer = []

  function doStuff(inputString) {
    debug('nestingTransformer', 'inputString=', inputString)
    let ret = []
    let dedentCount = 0

    const regex = /(?<INDENT>INDENT)?(?<DEDENT>DEDENT)?(?<NODENT>NODENT)?(?<LINENO>\d+) (?<text>.*)/
    const matches = inputString.match(regex)
    debug('nestingTransformer', 'matches=', matches)

    if (matches && matches.groups) {
      // debug('nestingTransformer', 'matches.groups=', matches.groups)
      this.lineNo = parseInt(matches.groups.LINENO, 10)
      // debug('nestingTransformer', 'lineNo=' + this.lineNo)

      if (matches.groups.INDENT) {
        ret.push(', "children":[')
        this.stack.push({ obj: 'children', symbol: ']' })

        // debug('nestingTransformer', 'matches.groups.INDENT=', matches.groups.INDENT)
        this.currentIndent++

        if (this.state[this.state.length - 1] == 'TEXT_START') {
          this.state.pop()
          this.state.push('TEXT')
        }
        else if (this.state[this.state.length - 1] == 'TEXT') {
          this.state.push('TEXT')
        }
        else if (this.state[this.state.length - 1] == 'UNBUF_CODE_START') {
          this.state.pop()
          this.state.push('UNBUF_CODE')
        }
        else if (this.state[this.state.length - 1] == 'UNBUF_CODE') {
          this.state.push('UNBUF_CODE')
        }
      }
      else if (matches.groups.DEDENT) {
        ret.push(this.stack.pop().symbol + this.stack.pop().symbol)
        if (matches.groups.text.length) {
          ret.push(this.stack.pop().symbol + ', ')
        }

        this.currentIndent--
        this.state.pop()
      }
      else {
        // need to handle the very first element
        if (this.stack.length == 1) {
          ret.push('[')
        }
        else {
          ret.push(this.stack.pop().symbol + ', ')
        }

        if (this.state[this.state.length - 1] == 'TEXT_START') {
          this.state.pop()
        }
      }

      const text = matches.groups.text
      if (text.trim().length > 0) {
        debug('nestingTransformer', 'before state=', this.state)
        const newObj = analyzeLine((this.state.length > 0 ? '<' + this.state[this.state.length - 1] + '>' : '') + text)

        // debug('nestingTransformer', 'newObj=', newObj)
        let nestedChildren = ''
        if (newObj.hasOwnProperty('state')) {
          if (newObj.state == 'NESTED') {
            if (newObj.children[0].hasOwnProperty('state')) {
              this.state.push(newObj.children[0].state)
            }
            const childrenStr = JSON.stringify(newObj.children[0])
            debug('nestingTransformer', 'childrenStr=' + childrenStr)
            delete newObj.children
            nestedChildren = ', "children":[' + childrenStr + ']'
          }
          else {
            this.state.push(newObj.state)
          }
        }
        debug('nestingTransformer', 'after state=', this.state)
        delete newObj.state
        const thingStr = JSON.stringify(newObj)
        ret.push(String.fill(this.currentIndent * 2) + '{' + thingStr.substring(1, thingStr.length - 1) + ',"lineNumber": ' + this.lineNo + nestedChildren)

        this.stack.push({ obj: (newObj.type == 'tag' || newObj.type == 'unknown' ? newObj.name : newObj.type), symbol: '}' })
      }
    }
    else {
      debug('nestingTransformer', 'NO matches=', inputString)
      // ret.push(inputString)
    }
    let retString = ret.join(' \n')
    if (typeof retString != 'string') {
      error('nestingTransformer', typeof retString)
    }
    debug('nestingTransformer', 'retString=' + retString)
    return retString
  }

  function analyzeLine(el) {
    debug('stream-reader', 'sending to parser: ' + el)
    const returnedObj = parser.parse(el)
    debug('stream-reader', 'returned from parser: ', returnedObj)
    return returnedObj
  }


  if (true) {
    const fileWriter = fs.createWriteStream('temp.json')
    const toFile = false

    process.stdin
      .pipe(WrapLine('|'))
      .pipe(WrapLine(function (pre, line) {
        // add 'line numbers' to each line
        pre = pre || 0
        return pre + 1
      }))
      .pipe(indentTransformer())
      .pipe(nestingTransformer)
      .pipe(toFile ? fileWriter : process.stdout);
  }

  let debugContent = [];

  const loggers = new Map()
  function debug(pkg, ...msgs) {
    if (!loggers.has(pkg)) {
      loggers.pkg = debugFunc(pkg)
    }

    loggers.pkg(...msgs)

  }

  function error(pkg, ...msgs) {
    console.error(pkg, ...msgs)
  }

  stream.finished(process.stdin, (err) => {
    setTimeout(function () {
      console.log()
      console.log(...debugContent)//.map(a => util.inspect(a)))
    }, 1)
  });

}
export default nestingTransformer