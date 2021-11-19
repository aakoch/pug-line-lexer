#! bash
node src/replace.js inline.jison common

npx jison -o dist/inline.cjs --main build/inline.jison

if [ $? -eq 0 ]; then
  DEBUG='*' node dist/inline.cjs
fi