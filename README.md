# pug-line-lexer

Parses one line at a time. To be used by pug-lexing-transformer.

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