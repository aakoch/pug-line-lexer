import replace from 'replace-in-file'
import fs from 'fs'
import { argv } from 'process';
import path from 'path'
import { fileURLToPath } from 'url';
import debugFunc from 'debug'
const debug = debugFunc.debug('pug-line-lexer.replace')
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const buildDirectoryPath = path.resolve(path.normalize(path.join(__dirname, '../build')))
debug('Creating build directory ' + buildDirectoryPath)
fs.mkdirSync(buildDirectoryPath, {recursive:true})
const inFileName = process.argv[2];
debug('Input file=' + inFileName)
const moduleOpt = argv[3];
debug('Module=' + moduleOpt)

let toFilename
try {
  const fromFilename = path.resolve(__dirname, inFileName);
  toFilename = path.resolve(buildDirectoryPath, inFileName);
  debug('Copying ' + fromFilename + ' to ' + toFilename)

  await fs.promises.copyFile(fromFilename, toFilename);
} catch (e) {
  console.error('The file could not be copied', e);
}

let moduleFilename
if (moduleOpt == 'es') {
  debug('Replacing imports with ES-specific ones')
  moduleFilename = path.resolve(__dirname, "es.js")
}
else if (moduleOpt == 'common') {
  debug('Replacing imports with CommonJS-specific ones')
  moduleFilename = path.resolve(__dirname, "common.js")
}
else if (moduleOpt == '') {
  console.error('Missing module type es|common')
  process.exit(1)
}
else {
  console.error('Unknown module type. Must be es|common')
  process.exit(1)
}

const fileContents = fs.readFileSync(moduleFilename)

const options = {
  files: toFilename,
  from: /__module_imports__/g,
  to: fileContents,
};

debug('Replacing contents in ' + toFilename)
replace(options).then((e) => {
  debug('Complete')
})