// import chai from 'chai'
// const expect = chai.expect
import Parser from '../build/redo.mjs'
const parse = Parser.parse
import fs from 'fs/promises'
import * as snapShots from 'file:///Users/aakoch/projects/pug/packages/pug-lexer/test/__snapshots__/index.cjs'

import { format as prettyFormat } from '/Users/aakoch/Library/Caches/typescript/4.4/node_modules/pretty-format/build/index.js';


  // fs.readFile('/Users/aakoch/projects/pug/packages/pug-lexer/test/cases/basic.pug', 'utf8')
  // .then(fileContents => {
  // const populate = new Function('exports', fileContents);
  // populate(data);
  // })

  // console.log(snapShots.default['attr-es2015.pug 1']);

  describe('snapshot', () => {
    it('should match', () => {
      return fs.readFile('/Users/aakoch/projects/pug/packages/pug-lexer/test/cases/basic.pug', 'utf8')
        .then(fileContents => {


          expect(prettyFormat(parse(fileContents.toString()))).toMatchSnapshot();

          //  .to.deep.equal(snapShots.default['basic.pug 1']);
        })
        .catch(e => {
          console.error(e)
        })
    })
  })

  // function loadSnapshots(filename) {
  //   return fs.readFile(filename)
  //   .then(val => {
  //     console.log(val);
  //   })
  // }


  describe('lexer', () => {
    describe('parse()', () => {
      it('should return an empty array when an empty string is given', () => {
        expect(parse("")).to.be.an('array').and.empty
      });

      it('should return an array', () => {
        const result = parse("html")
        expect(result).to.be.an('array').with.lengthOf('1')
      });

      it('should return a tag token for known tags', () => {
        fs.readFile('all_tags.txt')
          .then(lines => {
            lines.forEach(line => {
              const result = parse(line)
              expect(result[0]).an('object').that.has.property('type', 'tag')
            })
          })
      });

      it('should return a tag with the same name', () => {
        fs.readFile('all_tags.txt')
          .then(lines => {
            lines.forEach(line => {
              const result = parse(line)
              expect(result[0]).an('object').that.has.property('name', line)
            })
          })
      })
    })
  })