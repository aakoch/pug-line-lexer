#! zsh
node src/replace.js common 

npx jison -o dist/index.cjs --export-ast dist/ast.json --main build/index.jison

DEBUG='pug-line-lexer' node dist/index.cjs
