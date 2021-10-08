const chai = require('chai');
var util = require('util')
const expect = chai.expect;
const dyp = require('dyp');

// const parser = require('/Users/aakoch/projects/new-foo/workspaces/parser-generation/build/body_nodes.cjs')
const parser = require('/Users/aakoch/projects/new-foo/workspaces/parser-generation/stream_reader.js')

describe('test', function () {
  it('text blocks should be dedented (or in other words, roundtrip should look like below)', function () {
    const input = `//
  [if lt IE 9]>
  <script src="https://wordpress.adamkoch.com/wp-content/themes/twentyeleven/js/html5.js?ver=3.7.0" type="text/javascript"></script>
  <![endif]
    `
    var actual = parser.parse(input)
    // console.log(util.inspect(actual, false, 10))
    // delete actual.children[1].children[1].children[0].children
    // console.log(actual.children[1].children[1].children[0])
    dyp(actual,
      [
        '| [if lt IE 9]>',
        '| <script src="https://wordpress.adamkoch.com/wp-content/themes/twentyeleven/js/html5.js?ver=3.7.0" type="text/','javascript"></script>',
        '| <![endif]',
      ])
        
  })
})

// dedented comments aren't handled correctly
/*
  style(type='text/css' id='twentyeleven-header-css').
    #site-title a,
    #site-description {
    color: #2b74a5;
  }
// Jetpack Open Graph Tags
*/