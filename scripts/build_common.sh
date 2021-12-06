#! /bin/zsh

# build_common
node src/replace.js main.jison common
npx jison -o build/main.cjs --main build/main.jison
node src/replaceStream.js build/main.cjs dist/main.cjs

node src/replace.js attrs.jison common
npx jison -o build/attrs.cjs --main build/attrs.jison
node src/replaceStream.js build/attrs.cjs dist/attrs.cjs

# inline common
node src/replace.js inline.jison common
npx jison -o build/inline.cjs -n inlineParser --main build/inline.jison
node src/replaceStream.js build/inline.cjs dist/inline.cjs
