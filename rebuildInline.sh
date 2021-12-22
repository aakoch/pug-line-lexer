#! bash

if  [ ! -f dist/inline.cjs ] || [ src/inline.jison -nt dist/inline.cjs ]; then
  node src/replace.js inline.jison common

  npx jison -o dist/inline.cjs --main build/inline.jison
fi

if [ $? -eq 0 ]; then
  DEBUG='*' node dist/inline.cjs
fi