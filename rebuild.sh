#! zsh
node src/replace.js common 

npx jison -o dist/index.cjs --main build/index.jison

DEBUG='stream-reader-helper' node dist/index.cjs