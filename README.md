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