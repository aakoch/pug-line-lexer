# pug-line-lexer

Parses one line at a time. To be used by pug-lexing-transformer.

## Incremental build / WIP

```shell
./rebuild.sh
```

## Test

```shell
npm run test
```

## Build for deployment

```shell
npm run build
```

## Roundtrip from Pug -> AST -> Pug (can't do include yet)
npx jison -o build/indent.cjs --main src/indent.jison && node build/indent.cjs 404.pug -o temp.out
node writer.js temp.out
sdiff -s rewrite.pug 404.pug


## TODO
Clean up dependencies

Try minimist or mri or yargs-parser instead of command-line-args