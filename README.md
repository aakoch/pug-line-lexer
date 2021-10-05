# Jison parsers

## Build

To build a lexer and run the tests included at the bottom of the file:
```shell
npx jison -o build/test.js --main src/lines2.jison  && node build/test.js
```

or

To just build the lexer you can run this:
```shell
npx jison -o build/lines.mjs -m es src/line2.jison
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