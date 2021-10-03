const chai = require('chai');
var util = require('util')
const expect = chai.expect;
const dyp = require('dyp');

// const parser = require('/Users/aakoch/projects/new-foo/workspaces/parser-generation/build/body_nodes.cjs')
const parser = require('/Users/aakoch/projects/new-foo/workspaces/parser-generation/build/elements.cjs')

describe('attr test', function () {
  it('should match a known working example', function () {
    const input = `script
  | window._wpemojiSettings = baserocument,window._wpemojiSettings;`
    var actual = parser.parse(input)
    console.log("********* actual ***********")
    console.log(util.inspect(actual, false, 10))
    // delete actual.children[1].children[1].children[0].children
    // console.log(actual.children[1].children[1].children[0])
    dyp(actual,
      [
        {
          "type": "tag",
          "val": "script",
          "loc": {
            "start": {
              "line": 1
            },
            "end": {
              "line": 1,
              "column": 6
            }
          },
          "children": [
            {
              "type": "text",
              "name": "window._wpemojiSettings = baserocument,window._wpemojiSettings;",
              "loc": {
                "start": {
                  "line": 2
                },
                "end": {
                  "line": 2
                }
              }
            }
          ]
        }
      ]
      )
  })
})