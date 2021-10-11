import fs from 'fs'
import path, { parse } from 'path'
import stream from 'stream'
import util from 'util'
// import deepFilter from 'deep-filter';
// import objectify from 'through2-objectify'
import concat from 'concat-stream'
import lineTransformer from '../line-transformer/index.js'
import indentTransformer from '../indent-transformer/index.js';

import parser from './build/stream_reader_helper.cjs'
import debugFunc from 'debug'

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
    lineTransformer.ended = true
    indentTransformer.ended = true
    nestingTransformer.ended = true
  }
});

const nestingTransformer = new stream.Transform({
  flush(callback) {
    debug('nestingTransformer', 'this.ended=' + this.ended)
    if (this.ended) {
      while (this.stack.length > 0) {
        this.push(this.stack.pop())
      }
      this.push(']');
    }
    callback()
  },
  transform(chunk, enc, callback) {
    try {
      const ret = []

      debug('nestingTransformer', 'current indent=' + this.currentIndent)
      debug('nestingTransformer', 'chunk=' + chunk.toString())

      const regex = /(?<INDENT>INDENT)?(?<DEDENT>DEDENT)?(?<NODENT>NODENT)?(?<LINENO>\d+) (?<text>.*)/
      const matches = chunk.toString().match(regex)

      if (matches) {
        debug('nestingTransformer', 'matches=', matches.groups)
        this.lineNo = parseInt(matches.groups.LINENO, 10)
        debug('nestingTransformer', 'lineNo=' + this.lineNo)

        if (matches.groups.INDENT) {
          debug('nestingTransformer', 'matches.groups.INDENT=', matches.groups.INDENT)
          this.currentIndent++
          if (this.state[this.state.length - 1] == 'TEXT_START') {
            this.state.pop()
            this.state.push('TEXT')
          }
          else if (this.state[this.state.length - 1] == 'TEXT') {
            this.state.push('TEXT')
          }
        }
        else if (matches.groups.DEDENT) {
          ret.push(this.stack.pop())
          ret.push(this.stack.pop())
          ret.push(this.stack.pop())
          ret.push(this.stack.pop())

          this.currentIndent--
          this.state.pop()
        }
        else {
          // if (this.state[this.state.length - 1] == 'TEXT_START' || this.state[this.state.length - 1] == 'TEXT') {
          //   this.state.pop()
          // }
          if (this.first) {
            this.first = false;
            ret.push('[')
          }
          else {
            ret.push(this.stack.pop())
            ret.push(this.stack.pop())
            ret.push(',')
          }
        }

        const text = matches.groups.text
        if (text.trim().length > 0) {
          debug('nestingTransformer', 'before state=', this.state)
          const newObj = analyzeLine((this.state.length > 0 ? '<' + this.state[this.state.length - 1] + '>' : '') + text);
          debug('nestingTransformer', 'newObj=', newObj)
          let nestedChildren = ''
          if (newObj.hasOwnProperty('state')) {
            if (newObj.state == 'NESTED') {
              this.state.push(newObj.children[0].state)
              const childrenStr = JSON.stringify(newObj.children[0])
              debug('nestingTransformer', 'childrenStr=' + childrenStr)
              delete newObj.children
              nestedChildren = childrenStr.substring(0, childrenStr.length - 1) + ', "children":['
              this.stack.push('}')
              this.stack.push(']')
            }
            else {
              this.state.push(newObj.state)
            }
          }
          debug('nestingTransformer', 'after state=', this.state)
          delete newObj.state
          const thingStr = JSON.stringify(newObj)
          debug('nestingTransformer', 'ret[ret.length-1]=' + ret[ret.length-1])
          if (ret[ret.length-1] == '}')
            ret.push(',')
          ret.push(String.fill(this.currentIndent * 2) + '{' + thingStr.substring(1, thingStr.length - 1) + ',"lineNumber": ' + this.lineNo + ', "children":[' + nestedChildren)
          this.stack.push('}')
          this.stack.push(']')
        }

      }
      else {
        debug('nestingTransformer', 'NO matches=', chunk.toString())
        ret.push(chunk)
      }
      let retString = ret.join(' \n');
      if (typeof retString != 'string') {
        error('nestingTransformer', typeof retString)
      }
      debug('nestingTransformer', 'retString=' + retString);
      this.push(retString)
      debug('nestingTransformer', 'END\n\n');
      callback();
    }
    catch (e) {
      e.lineNo = this.lineNo
      callback(e)
    }
  }
})
nestingTransformer.first = true;
nestingTransformer.currentIndent = 0;
nestingTransformer.state = []
nestingTransformer.stack = []
nestingTransformer.lineNo = 0

function analyzeLine(el) {
  // if (el.match(/(<[A-Z_]+>)?\/\/.*/))
  //   return '{}'
  return parser.parse(el)
}

const fileWriter = fs.createWriteStream('temp.json')
const toFile = true

process.stdin
  .pipe(lineTransformer)
  .pipe(indentTransformer)
  .pipe(nestingTransformer)
  .pipe(toFile ? fileWriter : process.stdout);

let debugContent = [];

const loggers = new Map()
function debug(pkg, ...msgs) {
  if (!loggers.has(pkg)) {
    loggers.pkg = debugFunc(pkg)
  }

  loggers.pkg(...msgs)

  // if (
  //   //pkg == 'directiveTransformer'
  //   // pkg == 'convert'
  //   // false
  //   pkg == 'indentTransformer',
  //   pkg == 'nestingTransformer'
  // ) {// && pkg != 'nestingTransformer') {
  //   console.log(...msgs)
  //   debugContent.push(...msgs)
  // }
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
