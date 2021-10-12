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
    while (this.stack.length > 0) {
      this.push(this.stack.pop().symbol)
    }
    callback()
  },
  transform(chunk, enc, callback) {
    try {
      const str = chunk.toString()
      const lines = str.split('\n')
      lines.filter(line => line.length).forEach(line => {
        this.push(doStuff.call(this, line))
      })
      callback();
    }
    catch (e) {
      e.lineNo = (this != undefined ? this.lineNo : 'unknown')
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
    this.debug('pushing: ', txt)
    this.debug('length: ', ++this.length)
    this.internalArr.push(txt)
  },
  pop: function () {
    let txt = this.internalArr.pop()
    this.debug('popping: ', txt)
    this.debug('length: ', --this.length)
    return txt
  },
  length: 0
}
nestingTransformer.lineNo = 0
nestingTransformer.stack.push({ symbol: ']' })

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
    }
    else if (matches.groups.DEDENT) {
      ret.push(this.stack.pop().symbol + this.stack.pop().symbol)
      if (matches.groups.text.length) {
        ret.push(this.stack.pop().symbol + ', ')
      }

      // dedentCount++
      // debug('nestingTransformer', 'dedentCount=', dedentCount)
      // debug('nestingTransformer', 'this.stack=', this.stack)
      // let topStack = this.stack.pop()
      // debug('nestingTransformer', 'topStack=', topStack)
      // // if (dedentCount == 1) {
      // ret.push(topStack.symbol)
      // debug('nestingTransformer', 'topStack=', topStack)
      // if (topStack.obj == 'comment') {
      // ret.push(this.stack.pop().symbol)
      // }
      // // }
      // debug('nestingTransformer', 'this.stack=', this.stack)

      this.currentIndent--
      this.state.pop()
    }
    else {
      // // if (this.state[this.state.length - 1] == 'TEXT_START' || this.state[this.state.length - 1] == 'TEXT') {
      // //   this.state.pop()
      // // }
      // if (this.first) {
      //   this.first = false
      //   ret.push('[')
      // }
      // else {
      
      // need to handle the very first element
      if (this.stack.length == 1) {
        ret.push('[')
      }
      else {
        ret.push(this.stack.pop().symbol + ', ')
      }

      //   ret.push(',')

        if (this.state[this.state.length - 1] == 'TEXT_START') {
          this.state.pop()
        }
      // }
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
          // this.stack.push({ event: 'created ' + newObj.type, symbol: '}' })
          
          // this.stack.push({ obj: (newObj.type == 'tag' || newObj.type == 'unknown' ? newObj.name : newObj.type), symbol: '}' })
          // this.stack.push({ event: 'started children', symbol: ']}' })
        }
        else {
          this.state.push(newObj.state)
        }
      }
      debug('nestingTransformer', 'after state=', this.state)
      delete newObj.state
      const thingStr = JSON.stringify(newObj)
      // debug('nestingTransformer', 'ret[ret.length-1]=' + ret[ret.length - 1])
      // if (ret[ret.length - 1] == '}')
      //   ret.push(',')
      // ret.push(String.fill(this.currentIndent * 2) + '{' + thingStr.substring(1, thingStr.length - 1) + ',"lineNumber": ' + this.lineNo + ', "children":[' + nestedChildren)
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
  // if (el.match(/(<[A-Z_]+>)?\/\/.*/))
  //   return '{}'
  debug('stream-reader', 'sending to parser: ' + el)
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
