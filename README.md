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

### Failing tests:
filters-empty.pug                     inheritance.extend.include.pug        mixin.merge.pug
filters.coffeescript.pug              inheritance.extend.mixins.block.pug   mixins-copy.pug
filters.custom.pug                    inheritance.extend.mixins.pug         mixins.pug
filters.include.pug                   inheritance.extend.pug                namespaces.pug
filters.inline.pug                    inheritance.extend.whitespace.pug     pipeless-filters.pug
filters.less.pug                      inline-block-comment.pug              tag-blocks.pug
filters.markdown.pug                  layout.multi.append.prepend.block.pug tags.self-closing.pug
filters.nested.pug                    layout.prepend.without-block.pug      xml.pug
filters.stylus.pug                    mixin-at-end-of-file.pug              yield-before-conditional-head.pug
filters.verbatim.pug                  mixin-block-with-space.pug            yield-head.pug
html.pug                              mixin.block-tag-behaviour.pug         yield-title-head.pug
include-only-text-body.pug            mixin.blocks.pug