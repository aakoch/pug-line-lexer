# Jison parsers

## Build

To build a lexer and run the tests included at the bottom of the file:
```shell
npx jison -o build/stream_reader_helper.cjs --main src/stream_reader_helper.jison && DEBUG='stream-reader-helper' node build/stream_reader_helper.cjs
```

or

To just build the lexer you can run this:
```shell
npm run build
```

## Run

...and then run it like so:

```shell
node src/lines_runner.mjs src/lines_test.pug
```


## Roundtrip from Pug -> AST -> Pug (can't do include yet)
npx jison -o build/indent.cjs --main src/indent.jison && node build/indent.cjs 404.pug -o temp.out
node child_writer.js temp.out
sdiff -s rewrite.pug 404.pug


## TODO
Try minimist or mri or yargs-parser instead of command-line-args