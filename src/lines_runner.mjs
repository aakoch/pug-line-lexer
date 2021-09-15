import Parser from '../build/lines.mjs';
import { readFileSync } from 'fs';
console.log(Parser.parse(readFileSync(process.argv[2], 'utf8')))