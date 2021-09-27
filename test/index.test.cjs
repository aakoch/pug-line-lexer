const chai = require('chai');
var util = require('util')
const expect = chai.expect;
const dyp = require('dyp');

// const parser = require('/Users/aakoch/projects/new-foo/workspaces/parser-generation/build/body_nodes.cjs')
const parser = require('/Users/aakoch/projects/new-foo/workspaces/parser-generation/build/elements.cjs')

describe('test', function () {
  it('should match a known working example', function () {
    const input = `html
  head
  body
    div Adam is me
    div.
      Ben is no longer living
      He was my older brother.
    div
      | Chris is my brother who is a <em>doctor</em>.
      | He is younger than me.
    div
      div
    `
    var actual = parser.parse(input)
    // console.log(util.inspect(actual, false, 10))
    // delete actual.children[1].children[1].children[0].children
    // console.log(actual.children[1].children[1].children[0])
    dyp(actual,
      [
        {
          "type": "tag",
          "val": "html"
        },
        [
          {
            "type": "tag",
            "val": "head"
          },
          {
            "type": "tag",
            "val": "body"
          },
          [
            {
              "type": "tag",
              "val": "div",
              "children": [
                {
                  "type": "text",
                  "name": "Adam is me",
                }
              ]
            },
            {
              "type": "tag",
              "val": "div",
              "children": [
                {
                  "type": "text",
                  "name": "Ben is no longer living",
                },
                {
                  "type": "text",
                  "name": "He was my older brother.",
                }
              ]
            },
            {
              "type": "node",
              "name": "div",
              "children": [
                {
                  "type": "text",
                  "name": "Chris is my brother who is a <em>doctor</em>.",
                },
                {
                  "type": "text",
                  "name": "He is younger than me.",
                }
              ]
            },
            {
              "type": "tag",
              "val": "div"
            },
            [
              {
                "type": "tag",
                "val": "div"
              }
            ]
          ]
        ]
      ])
  })
})