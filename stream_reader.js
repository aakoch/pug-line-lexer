import fs from 'fs'
import path from 'path'
import stream from 'stream'
import util from 'util'

String.prototype.quote = function() {
  return this.replaceAll('"', '\\\"')
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
    const matches = chunk.toString().matchAll(/.*\n/g);
    for (const match of matches) {
      this.push(match[0].toString());
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
      while (this.stack[0] > 1) {
        this.stack.shift()
        // leaving this as a separate push for each makes the next transformer treat each as a separate call
        this.push('DEDENT')
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
        this.push('INDENT '  + chunk.toString().trim() + '\n')
      }
      else if (num < this.stack[0]) {
        while (num < this.stack[0]) {
          this.stack.shift()
          this.push('DEDENT ' + chunk.toString().trim() + '\n')
        }
      }
      else {
        this.push(chunk.toString().trim() + '\n')
      }
    }
    if (this.ended) {
      while (1 < this.stack[0]) {
        this.stack.shift()
        this.push('DEDENT ' );
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
    // console.log('Stream is done reading.');
  }
});


const tagTransformer = new stream.Transform({
  transform(chunk, enc, callback) {
    const ret = []

    debug('tagtransformer', 'chunk=' + chunk.toString())

    let regex = /(?<INDENT>INDENT )?(?<DEDENT>DEDENT)?(?<name>[a-zA-Z0-9]+)?\b(?<attrs>.*)?/
    // const groups = [...chunk.toString().matchAll(regex)]
    const matches = chunk.toString().match(regex)

    if (matches) {
      debug('tagtransformer', 'matches=', matches.groups)
      if (matches.groups.INDENT) {
        ret.push( ', "children": [{ ' )
      }
      // TODO: handle mulitple DEDENTs
      else if (matches.groups.DEDENT) {
        ret.push( '}] ' )
      }
      else {
        ret.push('}, {')
      }

      const tagName = matches.groups.name
      if (tagName && tagName.trim().length > 0) {
        ret.push( '"name": "' + tagName + '"')
      }

      const attrs = matches.groups.attrs
      if (attrs && attrs.trim().length > 0) {
        ret.push( '"attrs": "' + attrs.quote() + '"' )
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
    if (this.ended) {
      this.push('}]');
    }
    callback()
  },
  transform(chunk, enc, callback) {
    const ret = []

    debug('nestingTransformer', 'chunk=' + chunk.toString())

    let regex = /(?<INDENT>INDENT )?(?<DEDENT>DEDENT)?(?<text>.*)/
    // const groups = [...chunk.toString().matchAll(regex)]
    const matches = chunk.toString().match(regex)

    if (matches) {
      debug('nestingTransformer', 'matches=', matches.groups)
      if (matches.groups.INDENT) {
        ret.push( ', "children": [{ ' )
      }
      // TODO: handle mulitple DEDENTs
      else if (matches.groups.DEDENT) {
        ret.push( '}]}, { ' )
      }
      else {
        if (this.first) {
          this.first = false;
          ret.push('[{')
        }
        else {
          ret.push('}, {')
        }
      }

      const text = matches.groups.text
      if (text && text.trim().length > 0) {
        ret.push( '"text": "' + text.quote() + '"')
      }

    }
    else {
      debug('nestingTransformer', 'NO matches=', chunk.toString())
      ret.push(chunk)
    }
    let test = ret.join(' \n')
    console.log(typeof test)
    this.push(test)
    callback();
  }
})
nestingTransformer.first = true;



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

    let regex = /(?<INDENT>INDENT )?(?<DEDENT>DEDENT)?(?<text>.*)/
    // const groups = [...chunk.toString().matchAll(regex)]
    const matches = chunk.toString().match(regex)

    if (matches) {
      debug('simpleNestingTransformer', 'matches=', matches.groups)
      if (matches.groups.INDENT) {
        ret.push( ', [' )
      }
      // TODO: handle mulitple DEDENTs
      else if (matches.groups.DEDENT) {
        if (matches.groups.DEDENT.length > 6) {
          for (let i = 0; i < matches.groups.DEDENT.length / 6; i++) {
            ret.push( '], ' )
          }
        }
        else {
          ret.push( '], ' )
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
      if (text && text.trim().length > 0) {
        ret.push('"' + text.quote() + '"')
      }

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

const closerTransformer = new stream.Transform({
  flush(callback) {
    this.push(this.tokens)
    callback()
  },
  transform(chunk, enc, callback) {
    if (!this.hasOwnProperty('tokens')) {
      this.tokens = []
    }
    chunk.forEach((c) => {
    // for (var c of chunk.toString()) {
      if (c == '[') {
        this.tokens.push(']')
      }
      else if (c == '{') {
        this.tokens.push('}')
      }
      else if (c == '}' || c == ']') {
        this.tokens.pop();
      }
    })
    callback();
  }
})



process.stdin
.pipe(lineTransformer)
.pipe(blankLineRemoverTransformer)
  
  .pipe(indentTransformer)
  // .pipe(nestingTransformer)
  .pipe(simpleNestingTransformer)
  // .pipe(closerTransformer)
  .pipe(process.stdout);

let debugContent = [];

function debug(pkg, ...msgs) {
  if (pkg != 'tagtransformer' 
    // && pkg != 'simpleNestingTransformer'
    && pkg != 'blankLineRemoverTransformer'
      
      ) {// && pkg != 'nestingTransformer') {
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