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

json.forEach(line => {
  printLine(line, 0);
})

function printLine(line, indent) {
  if (Array.isArray(line)) {
    line.forEach(l => {
      printLine(l, indent + 1);
    })
  }
  else {
    let arr = [];
    for (let i = 0; i < indent; i++) {
      arr.push('  ');
    }
    fs.appendFileSync("rewrite.pug", arr.join('') + line + '\n')
  }
}


// try {
//   console.log("\n\nor as JSON:\n", JSON.parse(source, null, 2));
// } catch (e) {  }