#! /bin/zsh

if [ ! -f build/attrs.js ] || [ src/attrs.jison -nt build/attrs.js ]; then
  stat src/attrs.jison
  stat build/attrs.js
  node src/replace.js attrs.jison es
  npx jison -m es -o build/attrs.js build/attrs.jison
fi


# head -n $( grep -n "export default {" build/attrs.temp.js | cut -d ":" -f 1 | xargs -n 1 expr -1 +) build/attrs.temp.js > build/attrs.temp2.js
# cat src/es.js build/attrs.temp.js > build/attrs.js

if [ ! -f build/inline.js ] || [ src/inline.jison -nt build/inline.js ]; then
  node src/replace.js inline.jison es
  npx jison -m es -o build/inline.js build/inline.jison
fi
# head -n $( grep -n "export default {" build/inline.temp.js | cut -d ":" -f 1 | xargs -n 1 expr -1 +) build/inline.temp.js > build/inline.temp2.js
# cat src/es.js build/inline.temp.js > build/inline.js


if [ ! -f build/main.js ] || [ src/main.jison -nt build/main.js ]; then
  node src/replace.js main.jison es
  npx jison -m es -o build/main.js build/main.jison
fi
# head -n $( grep -n "export default {" build/main.temp.js | cut -d ":" -f 1 | xargs -n 1 expr -1 +) build/main.temp.js > build/main.temp2.js
# cat src/es.js build/main.temp.js > build/main.js

# rm build/*.temp.js
# rm build/*.temp2.js
