const chai = require('chai');
var util = require('util')
const expect = chai.expect;
const dyp = require('dyp');

const parser = require('/Users/aakoch/projects/new-foo/workspaces/parser-generation/build/body_nodes.cjs')

describe('test', function () {
  it('should match a known working example', function () {
    const input = `html
  head
  body
    div Adam is me
    div.
      Ben is no longer living
    div
      | Chris is my brother who is a doctor
    div
      div
    `
    var actual = parser.parse(input)
    // console.log(util.inspect(actual, false, 10))
    // delete actual.children[1].children[1].children[0].children
    // console.log(actual.children[1].children[1].children[0])
    dyp(actual,
      {
        "type": "tag",
        "val": "html",
        "children": [
          {
            "type": "tag",
            "val": "head"
          },
          {
            "type": "tag",
            "val": "body",
            "children": [
              {
                "type": "tag",
                "val": "div",
                "hint": 12,
                "children": [
                  {
                    "type": "text",
                    "val": " Adam is me"
                  }
                ]
              },
              {
                "type": "node",
                "name": "div",
                "children": [
                  {
                    "type": "text",
                    "name": "Ben is no longer living"
                  }
                ]
              },
              {
                "type": "tag",
                "val": "div",
                "children": [
                  {
                    "type": "text",
                    "name": " Chris is my brother who is a doctor"
                  }
                ]
              },
              {
                "type": "tag",
                "val": "div",
                "children": [
                  {
                    "type": "tag",
                    "val": "div"
                  }
                ]
              }
            ]
          }
        ]
      })
  })
})