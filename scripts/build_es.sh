#! /bin/zsh

# build_es
node src/replace.js main.jison es
npx jison -o dist/main.mjs -m es --main build/main.jison
node src/replace2.js main.mjs


node src/replace.js attrs.jison es
npx jison -o dist/attrs.mjs -m es --main -n attrParser build/attrs.jison
node src/replace2.js attrs.mjs

# inline es
node src/replace.js inline.jison es
npx jison -o dist/inline.mjs -m es --main build/inline.jison
node src/replace2.js inline.mjs
