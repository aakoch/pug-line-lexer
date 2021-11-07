#! /bin/zsh

# build_common
node src/replace.js main.jison common
npx jison -o dist/main.cjs --main build/main.jison

# inline common
node src/replace.js inline.jison common
npx jison -o dist/inline.cjs -n inlineParser --main build/inline.jison
