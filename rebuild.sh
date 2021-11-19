#! zsh

./rebuildAttrs.sh

if [ $? -eq 0 ]; then
./rebuildInline.sh
fi


if [ $? -eq 0 ]; then
./rebuildMain.sh
fi