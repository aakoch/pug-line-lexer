#! zsh
node src/replace.js common 

npx jison -o dist/index_new.cjs --main build/index.jison

DEBUG='pug-line-lexer' node dist/index_new.cjs