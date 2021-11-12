#! zsh

node src/replace.js attrs.jison common 

npx jison -o dist/attrs.cjs --export-ast dist/attrs_ast.json --main -n parseAttrs build/attrs.jison

DEBUG='pug-line-lexer*' node dist/attrs.cjs