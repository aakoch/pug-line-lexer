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
  printLine(obj, 0);
})

function printLine(obj, indent) {

  try {
  let arr = [];
  for (let i = 0; i < indent; i++) {
    arr.push('  ');
  }
  
  if (obj.hasOwnProperty('name')) {
    arr.push(obj.name)
    // arr.push(' ');
    arr.push(obj.attrs)
  }
  
  if (obj.hasOwnProperty('THEREST')) {
    arr.push(obj.THEREST)
  }
  
  if (obj.hasOwnProperty('WORD')) {
    arr.push(obj.WORD)
  }
  
  if (obj.hasOwnProperty('text')) {
    arr.push('| ')
    arr.push(obj.text)
  }

  fs.appendFileSync("rewrite.pug", arr.join('') + '\n')
  
  // let text = obj.something || (obj.tag + (obj.attrs || (obj.val ? ' ' + obj.val : '') || '')) || obj.text
  // fs.appendFileSync("rewrite.pug", arr.join('') + text + '\n')

  // console.log('obj.children=', obj.children);
  if (obj.children != undefined) {
    obj.children.forEach(l => {
      printLine(l, indent + 1);
    })
  }
  else {
  }
} catch (e) {
  console.error(e);
}
}


// try {
//   console.log("\n\nor as JSON:\n", JSON.parse(source, null, 2));
// } catch (e) {  }