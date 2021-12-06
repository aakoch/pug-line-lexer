#! /bin/zsh

# build_es
node src/replace.js main.jison es
npx jison -o build/main.mjs -m es --main build/main.jison
node src/replaceStream.js build/main.mjs dist/main.mjs
node src/replace2.js main.mjs


node src/replace.js attrs.jison es
npx jison -o build/attrs.mjs -m es --main -n attrParser build/attrs.jison
node src/replaceStream.js build/attrs.mjs dist/attrs.mjs
node src/replace2.js attrs.mjs

# inline es
node src/replace.js inline.jison es
npx jison -o build/inline.mjs -m es --main build/inline.jison
node src/replaceStream.js build/inline.mjs dist/inline.mjs
node src/replace2.js inline.mjs
