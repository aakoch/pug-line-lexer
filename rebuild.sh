#! zsh
node src/replace.js main.jison common 

npx jison -o dist/main.cjs --export-ast dist/ast.json --main build/main.jison

DEBUG='pug-line-lexer' node dist/main.cjs
