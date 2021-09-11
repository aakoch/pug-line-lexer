import fs from "fs"
import { exec } from "child_process"

fs.readdirSync('src').filter(filename => {
  return filename.endsWith('.jison')
}).forEach(filename => {
  try {
    var grammar = fs.readFileSync('src/' + filename)
    exec(`npx jison -o build/${filename.substring(0, filename.indexOf('.'))}.cjs --main src/${filename}`, (error, stdout, stderr) => {
      if (error) {
        console.log(`error: ${error.message}`);
        return;
      }
      if (stderr) {
        console.log(`stderr: ${stderr}`);
        return;
      }
      console.log(`stdout: ${stdout}`);
    });
  } catch (err) {
    console.error(filename, err);
  }
})