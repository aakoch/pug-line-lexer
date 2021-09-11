import Parser from './semwhitespace.mjs';
import { readFileSync } from 'fs';

console.log(Parser.parse(readFileSync('./semwhitespace_ex.src')))