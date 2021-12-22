#! zsh

if [[ $* == *--force* ]]; then
  FORCE=true
else 
  FORCE=false
fi

if [ $FORCE ] || [ ! -f dist/main.cjs ] || [ src/main.jison -nt dist/main.cjs ]; then
  node src/replace.js main.jison common 

  npx jison -o dist/main.cjs --export-ast dist/ast.json --main build/main.jison
elif [ $FORCE ] || [ ! -f dist/main.cjs ] || [ src/common.js -nt dist/main.cjs ]; then
  node src/replace.js main.jison common 

  npx jison -o dist/main.cjs --export-ast dist/ast.json --main build/main.jison
fi

if [ $? -eq 0 ]; then
  DEBUG='*' node dist/main.cjs
fi