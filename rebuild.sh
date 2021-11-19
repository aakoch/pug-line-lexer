#! zsh

if [ src/attrs.jison -nt dist/attrs.cjs ]; then
  ./rebuildAttrs.sh
fi

if [ $? -eq 0 ]; then
  if [ src/inline.jison -nt dist/inline.cjs ]; then
    ./rebuildInline.sh
  fi
fi


if [ $? -eq 0 ]; then
  ./rebuildMain.sh
fi