import chai from 'chai'
const expect = chai.expect
import {
  parse
} from '../build/tags.cjs'
import fs from 'fs/promises'

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
        .catch(e => {
          console.error(e)
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
        .catch(e => {
          console.error(e)
        })
    })
  })
})