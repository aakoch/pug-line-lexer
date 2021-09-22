import Parser from '../build/redo.mjs';
import { readFileSync } from 'fs';
console.log(Parser.parse(readFileSync(process.argv[2], 'utf8')))