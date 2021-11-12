#! zsh

node src/replace.js attrs.jison common 

npx jison -o dist/attrs.cjs --export-ast dist/attrs_ast.json --main -n parseAttrs build/attrs.jison

DEBUG='pug-line-lexer' node dist/attrs.cjs



node src/replace.js main.jison common 

npx jison -o dist/main.cjs --export-ast dist/ast.json --main build/main.jison

DEBUG='pug-line-lexer' node dist/main.cjs