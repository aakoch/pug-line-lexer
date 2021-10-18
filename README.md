# pug-line-lexer

Parses one line at a time. To be used by pug-lexing-transformer.

## Build

```shell
npm run build
```

## Test

```shell
npm run test
```

## Roundtrip from Pug -> AST -> Pug (can't do include yet)
npx jison -o build/indent.cjs --main src/indent.jison && node build/indent.cjs 404.pug -o temp.out
node child_writer.js temp.out
sdiff -s rewrite.pug 404.pug


## TODO
Clean up dependencies

Try minimist or mri or yargs-parser instead of command-line-args