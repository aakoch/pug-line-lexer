import fs from 'fs'
import path from 'path'
import debugFunc from 'debug'
const debug = debugFunc('child-writer')
// import util from 'util';

fs.truncateSync('rewrite.pug')

// console.log(process.argv)

if (!process.argv[2]) {
  console.log('Usage: node', path.basename(process.argv[1]) + ' FILE');
  process.exit(2);
}
let filename = process.argv[2]
var source = fs.readFileSync(path.normalize(process.argv[2]), 'utf8');

var json = JSON.parse(source)

json.forEach(obj => {
  const arr = printLine(obj, 0, Number.MAX_SAFE_INTEGER);
  fs.appendFileSync("rewrite.pug", arr.join(''))
})

function printLine(obj, indent, textStartIndent) {
  let arr = [];
  try { 

    for (let i = 0; i < Math.min(textStartIndent, indent); i++) {
      arr.push('  ');
    }

    if (obj.type == 'doctype') {
      arr.push('doctype ')
      arr.push(obj.val)
    }

    if (obj.hasOwnProperty('name')) {
      arr.push(obj.name)
    }

    if (obj.hasOwnProperty('classes')) {
      arr.push('.')
      arr.push(obj.classes.join('.'))
    }

    if (obj.hasOwnProperty('id')) {
      arr.push('#')
      arr.push(obj.id)
    }

    if (obj.hasOwnProperty('attrs')) {
      // if (/^[a-zA-Z0-9&]/.test(obj.attrs.toString())) {
      //   arr.push(' ');
      // }
      arr.push('(' + obj.attrs + ')')
    }

    if (obj.hasOwnProperty('therest')) {
      arr.push(' ')
      arr.push(obj.therest)
    }

    if (obj.hasOwnProperty('WORD')) {
      arr.push(obj.WORD)
    }

    if (obj.hasOwnProperty('params')) {
      arr.push(' ')
      arr.push(obj.params)
    }

    if (obj.hasOwnProperty('type') && obj.type == 'js') {
      arr.push('- ')
      arr.push(obj.val)
    }

    if (obj.hasOwnProperty('type') && obj.type == 'unbuffered_code') {
      arr.push('- ')
      arr.push(obj.val)
    }

    if (obj.hasOwnProperty('type') && obj.type == 'text') {
      if (textStartIndent == Number.MAX_SAFE_INTEGER) {
        textStartIndent = indent;
      }
      arr.push('| ')
      arr.push(''.padStart(indent - textStartIndent, '  '))
      arr.push(obj.val)
    }

    if (obj.hasOwnProperty('type') && obj.type == 'comment') {
      arr.push('//')
      arr.push('\n')
      if (obj.children != undefined) {
        debug('obj.children.length=' + obj.children.length)
        obj.children.forEach(l => {
          for (let i = 0; i < Math.min(textStartIndent, indent); i++) {
            arr.push('  ');
          }
          arr.push('//' + l.text);
        })
      }
      arr.push('\n')
    }
    else {
      arr.push('\n')
      
      if (obj.children != undefined) {
        debug('obj.children.length=' + obj.children.length)
        obj.children.forEach(l => {
          arr.push(...printLine(l, indent + 1, textStartIndent));
        })
      }
    }
  } catch (e) {
    console.error(e);
  }
  return arr;
}


// try {
//   console.log("\n\nor as JSON:\n", JSON.parse(source, null, 2));
// } catch (e) {  }