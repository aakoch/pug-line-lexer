import replace from 'replace-in-file'
import path from 'path'
import { fileURLToPath } from 'url';
import debugFunc from 'debug'
const debug = debugFunc.debug('pug-line-lexer:replace')
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const distDirectoryPath = path.resolve(path.normalize(path.join(__dirname, '../dist')))

let filenameToChange = path.resolve(distDirectoryPath, 'index.mjs');

const options = {
  files: filenameToChange,
  from: "var fs = require('fs');\nvar path = require('path');",
  to: "import fs from 'fs'\nimport path from 'path';",
};

replace(options).then(() => debug('Complete'))