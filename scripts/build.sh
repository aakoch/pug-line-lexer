#! /bin/zsh

scripts/build_es.sh
scripts/build_common.sh

cp src/index.cjs dist/index.cjs
cp src/index.mjs dist/index.mjs

