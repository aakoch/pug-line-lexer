#! zsh
npx jison -o build/inline.cjs --main src/inline.jison

DEBUG='pug-line-lexer:inline' node build/inline.cjs
