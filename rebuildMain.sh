#! zsh

if [ src/main.jison -nt dist/main.cjs ]; then
  node src/replace.js main.jison common 

  npx jison -o dist/main.cjs --export-ast dist/ast.json --main build/main.jison
fi

if [ $? -eq 0 ]; then
  DEBUG='pug-line-lexer' node dist/main.cjs
fi