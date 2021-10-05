import fs from 'fs'
import path from 'path'
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
    
    if (obj.hasOwnProperty('name')) {
      arr.push(obj.name)
      if (/^[a-zA-Z0-9&]/.test(obj.attrs.toString())) {
        arr.push(' ');
      }
      arr.push(obj.attrs)
    }
    
    if (obj.hasOwnProperty('THEREST')) {
      arr.push(obj.THEREST)
    }
    
    if (obj.hasOwnProperty('WORD')) {
      arr.push(obj.WORD)
    }
    
    if (obj.hasOwnProperty('text')) {
      if (textStartIndent == Number.MAX_SAFE_INTEGER) {
        textStartIndent = indent;
      }
      arr.push('| ')
      arr.push(''.padStart(indent - textStartIndent, '  '))
      arr.push(obj.text)
    }

    arr.push('\n')
    
    // let text = obj.something || (obj.tag + (obj.attrs || (obj.val ? ' ' + obj.val : '') || '')) || obj.text
    // fs.appendFileSync("rewrite.pug", arr.join('') + text + '\n')

    // console.log('obj.children=', obj.children);
    if (obj.children != undefined) {
      obj.children.forEach(l => {
        arr.push(...printLine(l, indent + 1, textStartIndent));
      })
    }
  } catch (e) {
    console.error(e);
  }
  return arr;
}


// try {
//   console.log("\n\nor as JSON:\n", JSON.parse(source, null, 2));
// } catch (e) {  }