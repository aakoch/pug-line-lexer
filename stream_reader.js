import fs from 'fs'
import path, { parse } from 'path'
import stream from 'stream'
import util from 'util'
import deepFilter from 'deep-filter';

import objectify from 'through2-objectify'
import concat from 'concat-stream'

import parser from './build/stream_reader_helper.cjs'


String.prototype.quote = function () {
  return this.replaceAll('\\', '\\\\').replaceAll('"', '\\\"')
}


/* **********************************************************************************
 * **************************  Simple examples ************************************ */
// const uppercaseTransformStream = new stream.Transform();
// uppercaseTransformStream._transform = (chunk, encoding, callback) => {
//   uppercaseTransformStream.push(chunk.toString().toUpperCase());
//   callback();
// }

// const uppercaseTransformStream = new stream.Transform({
//   transform(chunk, enc, callback) {
//     this.push(chunk.toString().toUpperCase());
//     callback();
//   }
// })

// process.stdin.pipe(uppercaseTransformStream).pipe(process.stdout);
/* ******************************************************************************** */


const lineTransformer = new stream.Transform({
  transform(chunk, enc, callback) {
    const matches = chunk.toString().matchAll(/.*(\n|$)/g);
    for (const match of matches) {
      this.push(match[0].toString());
    }
    callback();
  }
})

const extraCommaTransformer = new stream.Transform({
  transform(chunk, enc, callback) {
    this.cache = this.cache || ''
    const str = this.cache + chunk.toString()
    if (str.match(/,\s*$/)) {
      this.cache = str
    } else {
      this.push(str.replaceAll(/,\s*\]/g, ']'))
      this.cache = ''
    }
    callback();
  }
})

const blankLineRemoverTransformer = new stream.Transform({
  transform(chunk, enc, callback) {
    const match = chunk.toString().match(/^\s*$/);
    if (match) {
      debug('blankLineRemoverTransformer', 'removing blank line')
    }
    else {
      this.push(chunk);
    }
    callback();
  }
})

// const commaAfterBraceWithNothingAfterRemoverTransformer = new stream.Transform({
//   transform(chunk, enc, callback) {
//     debug('commaAfterBraceWithNothingAfterRemoverTransformer', 'chunk2=' + chunk.toString())
//     const match = chunk.toString().match(/\], \]/);
//     if (match) { 
//       debug('commaAfterBraceWithNothingAfterRemoverTransformer', 'removing comma')
//       this.push('] ]');
//     }
//     else {
//       this.push(chunk);
//     }
//     callback();
//   }
// })

const currentObj = {}

const indentTransformer = new stream.Transform({
  flush(callback) {
    if (this.ended) {
      // const ret = []
      while (1 < this.stack[0]) {
        this.stack.shift()
        // leaving this as a separate push for each makes the next transformer treat each as a separate call
        this.push('DEDENT ')
        // ret.push('DEDENT');
      }
      // this.push(ret.join(' '))
    }
    callback()
  },
  transform(chunk, enc, callback) {
    const match = chunk.toString().match(/^(  |\t)*/)

    if (match) {
      let num = match.toString().length
      if (num > this.stack[0]) {
        this.stack.unshift(match.toString().length)
        this.push('INDENT ' + chunk.toString().trim() + '\n')
      }
      else if (num < this.stack[0]) {
        while (num < this.stack[0]) {
          this.stack.shift()
          this.push('DEDENT \n')
        }
        this.push(chunk.toString().trim() + '\n')
      }
      else {
        this.push(chunk.toString().trim() + '\n')
      }
    }
    if (this.ended) {
      while (1 < this.stack[0]) {
        this.stack.shift()
        this.push('DEDENT ');
      }
    }
    callback();
  }
})
indentTransformer.stack = [1]


stream.finished(process.stdin, (err) => {
  if (err) {
    console.error('Stream failed', err);
  } else {
    indentTransformer.ended = true
    nestingTransformer.ended = true
    simpleNestingTransformer.ended = true
    removeExtraEmptyElementTransformer.ended = true
    removeExtraEmptyElementTransformer2.ended = true
    // console.log('Stream is done reading.');
  }
});


const tagTransformer = new stream.Transform({
  transform(chunk, enc, callback) {
    const ret = []

    debug('tagtransformer', 'chunk=' + chunk.toString())

    const regex = /(?<INDENT>INDENT )?(?<DEDENT>DEDENT)?(?<name>[a-zA-Z0-9]+)?\b(?<attrs>.*)?/
    // const groups = [...chunk.toString().matchAll(regex)]
    const matches = chunk.toString().match(regex)

    if (matches) {
      debug('tagtransformer', 'matches=', matches.groups)
      if (matches.groups.INDENT) {
        ret.push(', "children": [{ ')
      }
      // TODO: handle mulitple DEDENTs
      else if (matches.groups.DEDENT) {
        ret.push('}] ')
      }
      else {
        ret.push('}, {')
      }

      const tagName = matches.groups.name
      if (tagName && tagName.trim().length > 0) {
        ret.push('"name": "' + tagName + '"')
      }

      const attrs = matches.groups.attrs
      if (attrs && attrs.trim().length > 0) {
        ret.push('"attrs": "' + attrs.quote() + '"')
      }

      // let tagName = groups[0][1]
      // let attrs = groups[0][2]
      // debug('tagtransformer', '\n' + 'tagName=' + tagName)
      // debug('tagtransformer', 'attrs=' + attrs)

    }
    else {
      debug('tagtransformer', 'NO matches=', chunk.toString())
      ret.push(chunk)
    }
    this.push(ret.join(', \n'))
    callback();
  }
})





const nestingTransformer = new stream.Transform({
  flush(callback) {
    debug('nestingTransformer', 'this.ended=' + this.ended)
    if (this.ended) {
      this.push(this.stack.pop())
      this.push(this.stack.pop())
      this.push(']');
    }
    callback()
  },
  transform(chunk, enc, callback) {
    try {
      this.lineNo++
      debug('current indent=' + this.currentIndent)
      const ret = []
      
      debug('nestingTransformer', '\n1 chunk=' + chunk.toString())

      const regex = /(?<INDENT>INDENT )?(?<DEDENT>DEDENT )?(?<text>.*)/
      const matches = chunk.toString().match(regex)

      if (matches) {
        debug('nestingTransformer', '2 matches=', matches.groups)
        if (matches.groups.INDENT) {
          this.previousWasDedent = false
          this.currentIndent++
          if (this.state[this.state.length - 1] == 'TEXT_START' || this.state[this.state.length - 1] == 'TEXT') {
            this.state.push('TEXT')
          }
        }
        else if (matches.groups.DEDENT) {
          ret.push(this.stack.pop())
          ret.push(this.stack.pop())

          this.currentIndent--
          this.state.pop()
        }
        else {
          // if (this.state[this.state.length - 1] == 'TEXT_START' || this.state[this.state.length - 1] == 'TEXT') {
          //   this.state.pop()
          // }
          this.previousWasDedent = false
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
          const thing = analyzeLine((this.state.length > 0 ? '<'+this.state[this.state.length - 1]+'>' : '') + text);
          debug('nestingTransformer', 'thing=', thing)
          if (thing.hasOwnProperty('state')) {
            this.state.push(thing.state)
          }
          debug('nestingTransformer', 'after state=', this.state)
          delete thing.state
          const thingStr = JSON.stringify(thing)
          ret.push(''.padStart(this.currentIndent * 2, ' ') + '{' + thingStr.substring(1, thingStr.length - 1) + ',"children":[')
          this.stack.push('}')
          this.stack.push(']')
        }

      }
      else {
        debug('nestingTransformer', 'NO matches=', chunk.toString())
        ret.push(chunk)
      }
      let test = ret.join(' \n');
      debug('nestingTransformer', typeof test);
      if (typeof test != 'string') {
        error('nestingTransformer', typeof test)
      }
      this.push(test)
      callback();
    }
    catch(e) {
      e.lineNo = this.lineNo
      callback(e)
    }
  }
})
nestingTransformer.first = true;
nestingTransformer.currentIndent = 0;
nestingTransformer.state=[]
nestingTransformer.stack=[]
nestingTransformer.lineNo=0

function analyzeLine(el) {
  // if (el.match(/(<[A-Z_]+>)?\/\/.*/))
  //   return '{}'
  return parser.parse(el)
}

const simpleNestingTransformer = new stream.Transform({
  flush(callback) {
    debug('simpleNestingTransformer', 'this.ended=' + this.ended)
    if (this.ended) {
      this.push(']');
    }
    callback()
  },
  transform(chunk, enc, callback) {
    const ret = []

    debug('simpleNestingTransformer', 'chunk=' + chunk.toString())

    const regex = /(?<INDENT>INDENT )?(?<DEDENT>DEDENT)?(?<text>.*)/
    // const groups = [...chunk.toString().matchAll(regex)]
    const matches = chunk.toString().match(regex)

    if (matches) {
      debug('simpleNestingTransformer', 'matches=', matches.groups)
      if (matches.groups.INDENT) {
        ret.push(', [')
      }
      // TODO: handle mulitple DEDENTs
      else if (matches.groups.DEDENT) {
        if (matches.groups.DEDENT.length > 6) {
          for (let i = 0; i < matches.groups.DEDENT.length / 6; i++) {
            ret.push('], ')
          }
        }
        else {
          ret.push('], ')
        }
      }
      else {
        if (this.first) {
          this.first = false;
          ret.push('[')
        }
        else {
          ret.push(',')
        }
      }

      const text = matches.groups.text
      // if (text && text.trim().length > 0) {
      ret.push('"' + text.quote() + '"')
      // }

    }
    else {
      debug('simpleNestingTransformer', 'NO matches=', chunk.toString())
      ret.push(chunk)
    }
    let test = ret.join(' \n');
    debug('simpleNestingTransformer', typeof test);
    if (typeof test != 'string') {
      error('simpleNestingTransformer', typeof test)
    }
    this.push(test)
    callback();
  }
})
simpleNestingTransformer.first = true;

// const closerTransformer = new stream.Transform({
//   flush(callback) {
//     this.push(this.tokens)
//     callback()
//   },
//   transform(chunk, enc, callback) {
//     if (!this.hasOwnProperty('tokens')) {
//       this.tokens = []
//     }
//     chunk.forEach((c) => {
//       // for (var c of chunk.toString()) {
//       if (c == '[') {
//         this.tokens.push(']')
//       }
//       else if (c == '{') {
//         this.tokens.push('}')
//       }
//       else if (c == '}' || c == ']') {
//         this.tokens.pop();
//       }
//     })
//     callback();
//   }
// })



const removeExtraEmptyElementTransformer = new stream.Transform({
  objectMode: true,
  flush(callback) {
    if (this.ended) {
      this.push(this.internalBuffer.join(''));
    }
    callback()
  },
  transform(chunk, enc, callback) {

    try {
      let obj
      try {
        const text = this.internalBuffer.join('\n') + chunk.toString()
        obj = JSON.parse(text);
        this.push(obj)
      }
      catch (e) {
        // console.error(e);
        this.internalBuffer.push(chunk)
      }
      // debug('removeExtraEmptyElementTransformer', '\nremoveExtraEmptyElementTransformer: typeof chunk=' + typeof chunk)

      // debug('removeExtraEmptyElementTransformer', '\nremoveExtraEmptyElementTransformer: chunk=' + chunk.toString() + '<<<\n\n')

      // debug('removeExtraEmptyElementTransformer', '\nremoveExtraEmptyElementTransformer: text=' + text + '<<<\n\n')

      // const regex = /,\s*"\s*"/g
      // if (regex.test(text)) {
      //   const that = text.replaceAll(regex, ']')
      //   debug('removeExtraEmptyElementTransformer', '\nremoveExtraEmptyElementTransformer: converting=>>>\n' + text + '<<<\nto\n>>>' + that)
      //   this.push(that)
      //   this.internalBuffer = []
      // }
      // else {
      //   this.internalBuffer.push(chunk)
      // }


      callback();
    } catch (e) {
      console.error('\n\removeExtraEmptyElementTransformer - chunk=', chunk.toString())
      callback(e);
    }
  }
})
removeExtraEmptyElementTransformer.flip = true;
removeExtraEmptyElementTransformer.internalBuffer = []


const removeExtraEmptyElementTransformer2 = new stream.Transform({
  objectMode: true,
  flush(callback) {
    if (this.ended) {
      this.push(this.internalBuffer.join(''));
    }
    callback()
  },
  transform(chunk, enc, callback) {

    try {
      debug('removeExtraEmptyElementTransformer', '\nremoveExtraEmptyElementTransformer2: chunk=' + chunk)
      debug('removeExtraEmptyElementTransformer', '\nremoveExtraEmptyElementTransformer2: typeof chunk=' + typeof chunk)

      if (util.isObject(chunk) && !Array.isArray(chunk)) {
        for (const key in chunk) {
          if (Object.hasOwnProperty.call(chunk, key)) {
            const element = chunk[key];
            debug('removeExtraEmptyElementTransformer', '\nelement: ' + key + '=' + element)
          }
        }
      }

      debug('removeExtraEmptyElementTransformer', '\nremoveExtraEmptyElementTransformer2: Json.stringify(chunk)=' + JSON.stringify(chunk))

      function printit(obj, indent) {
        let a = []
        if (Array.isArray(obj)) {
          obj.forEach(element => {
            a.push(printit(element, indent + 1))
          });
        }
        else {
          a.push(''.padStart(' ', indent * 2) + obj)
        }
        return a
      }
      const ret = printit(chunk, 0);

      this.push(ret)

      callback();
    } catch (e) {
      console.error('\n\nremoveExtraEmptyElementTransformer - chunk=', chunk.toString())
      callback(e);
    }
  }
})
removeExtraEmptyElementTransformer2.flip = true;
removeExtraEmptyElementTransformer2.internalBuffer = []

const directiveTransformer = new stream.Transform({
  flush(callback) {
    this.push(this.tokens)
    callback()
  },
  transform(chunk, enc, callback) {

    try {
      debug('directiveTransformer', 'directiveTransformer: chunk=' + chunk.toString())
      const regex = /\s*(?<DIRECTIVE>(block|include))(?<THEREST>.*)/

      const matches = chunk.toString().match(regex)
      debug('directiveTransformer', '\ndirectiveTransformer: matches=', matches)

      if (matches) {
        debug('directiveTransformer', '\ndirectiveTransformer: matches.groups=', matches.groups)
        if (matches.groups) {
          this.push('{ ' + (matches.groups.DIRECTIVE ? 'directive: "' + matches.groups.DIRECTIVE + '", ' : '') + 'params: "' + matches.groups.THEREST + '"}, ')
        }
      }
      else {
        this.push(chunk)
      }
      callback();
    } catch (e) {
      console.error('\n\ndirectiveTransformer - chunk=', chunk.toString())
      callback(e);
    }
  }
})

const fileWriter = fs.createWriteStream('temp.json')
const toFile = true

process.stdin
  .pipe(lineTransformer)

  // TODO: figure out performance gains by not requiring line numbers
  .pipe(blankLineRemoverTransformer)

  .pipe(indentTransformer)
  .pipe(nestingTransformer)
  .pipe(toFile ? fileWriter : process.stdout);

let debugContent = [];

function debug(pkg, ...msgs) {
  if (
    //pkg == 'directiveTransformer'
    // pkg != 'tagtransformer' 
    // && pkg != 'simpleNestingTransformer'
    // && pkg != 'blankLineRemoverTransformer'
    // pkg == 'removeExtraEmptyElementTransformer'
    // pkg == 'convert'
    // false
    pkg == 'nestingTransformer'
  ) {// && pkg != 'nestingTransformer') {
    console.log(...msgs)
    debugContent.push(...msgs)
  }
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

// // import util from 'util';

// fs.truncateSync('rewrite.pug')

// // console.log(process.argv)

// if (!process.argv[2]) {
//   console.log('Usage: node', path.basename(process.argv[1]) + ' FILE');
//   process.exit(2);
// }
// let filename = process.argv[2]
// var source = fs.readFileSync(path.normalize(process.argv[2]), 'utf8');

// var json = JSON.parse(source)

// json.forEach(line => {
//   printLine(line, 0);
// })

// function printLine(line, indent) {
//   if (Array.isArray(line)) {
//     line.forEach(l => {
//       printLine(l, indent + 1);
//     })
//   }
//   else {
//     let arr = [];
//     for (let i = 0; i < indent; i++) {
//       arr.push('  ');
//     }
//     fs.appendFileSync("rewrite.pug", arr.join('') + line + '\n')
//   }
// }


// // try {
// //   console.log("\n\nor as JSON:\n", JSON.parse(source, null, 2));
// // } catch (e) {  }