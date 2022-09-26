# line-lexer

Parses one line at a time. To be used by lexing-transformer.

## Incremental build / WIP

```shell
npm test
```

## Test

```shell
npm test
```

## Build for deployment

```shell
npm run build
```

## Roundtrip from Pug -> AST -> Pug (can't do include yet)
See "all" project.

## CommonJS
I was trying to publish all of my libraries as an ES module and as a CommonJS module but either I have "type=module" in my package.json so I can use imports and run tests or I have it removed so Parcel correctly handles publishing both types. For now I'm just exporting an ES module.

## TODO
Clean up dependencies

Try minimist or mri or yargs-parser instead of command-line-args

### Failing tests
#### #1
mixin.attrs.pug
```
LexingError: Error parsing mixins.pug: Internal lexer engine error on line 29: The lex grammar programmer pushed a non-existing condition name "MULTI_LINE_ATTRS_END"; this is a fatal error and should be reported to the application programmer team!

  Erroneous area:
1: <MULTI_LINE_ATTRS_END>div#interpolation= str + 'interpolated'
^........................^
```

#### #2
mixins.pug
```
  Erroneous area:
1: <MULTI_LINE_ATTRS_END>div#interpolation= str + 'interpolated'
^........................^
```

#### #3
tags.self-closing.pug
```
LexingError: Error parsing /Users/aakoch/projects/new-foo/workspaces/lexing-transformer/build/in/tags.self-closing.pug: Lexical error on line 177: Unrecognized text.

Erroneous area:
1: #{
^..^
```

#### #4
xml.pug (XML not supported because I have limited the set of keywords to HTML)
```
LexingError: Error parsing /Users/aakoch/projects/new-foo/workspaces/lexing-transformer/build/in/xml.pug: Lexical error on line 2: Unrecognized text.

Erroneous area:
1: category(term='some term')/
^..^
```