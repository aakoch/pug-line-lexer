import fs from 'fs'
import { argv } from 'process';
import path from 'path'
import { fileURLToPath } from 'url';
import debugFunc from 'debug'
const debug = debugFunc.debug('pug-line-lexer.replaceStream')
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
import { exists, parseArguments } from '@aakoch/utils'
import stream from 'stream'

const opts = await parseArguments(process)
debug('opts=', opts)

class ReplaceTransformer extends stream.Transform {
  constructor(options) {
    super({ decodeStrings: true, encoding: 'utf-8' })
  }
  _flush(callback) {
    callback()
  }
  _transform(str, enc, callback) {
    str = str.toString()
    debug('typeof str=' + typeof str)
    str = str.replaceAll('../dist', '.')
    this.push(str)
    callback()
  }
}

opts.in.createStream()
  .pipe(new ReplaceTransformer())
  .pipe(opts.out.createStream())