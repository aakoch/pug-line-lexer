#! zsh
node src/replace.js inline.jison common

npx jison -o dist/inline.cjs --main build/inline.jison

DEBUG='pug-line-lexer:inline' node dist/inline.cjs