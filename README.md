# ParserKit

A Swift implementation of a monadic parser-combinator library. Analogous to [parsec](https://hackage.haskell.org/package/parsec), from `Haskell`.

This library provides an implementation of parser combinators, a flexible and functional method of parsing data wherein we build up larger parsers by using smaller parsers as components. In particular, by treating parsers as functions, we can write simple parsers that take advantage of reuseable code, reducing the total amount of complexity and leading to an easier understanding of what's going on in your code.

# Features

- A small codebase with no dependencies.
- Generic `Parser` class with primitive and complex combinators, and custom infix operators.
- Swift DocC documentation with a quickstart and tutorials.
- Example playgrounds
- Unit tests

# Quickstart

To get started, simply import this library.

```swift
import ParserKit
```

Write some parsers as an extension to the `Parse` namespace.

```swift
extension Parse {
    enum CSV {
        static let cell  = satisfy { $0 != "," && !$0.isNewline }.many.map { String($0) }
        static let row   = cell.many(sepBy: ",")
        static let table = row.many(sepEndBy: lineBreak)
    }
}
```

Parse some text.

```swift
let csv = try! Parse.CSV.table.parse("""
foo,bar,baz,qux
zip,zap,bip,bap
if,then,else,ni
""")
```

Do something with the result.

```swift
print(csv)
// Prints:
// [["foo", "bar", "baz", "qux"], ["zip", "zap", "bip", "bap"], ["if", "then", "else", "ni"]]
print(csv[1][2])
// Prints:
// bip
```

For more details, tutorials, and live Xcode mouseover help, be sure to build and read the full `DocC` documentation.

# Future work

- `attempt` / explicit backtracking
- Making `Input` / `State` parametric a la GParser<Input,State,Content>
- Canonical / exported versions of CSV, Math, Json and other tutorial primitives
- Better / pretty-printed errors, make `label` actually do something
- Complete symmetry between `Parser<T>._` and `Parse._`. Eg `parens(char(_))` vs `char(_).parens()`.
- Tutorials covering more combinators and their use cases
- Better explanation of 'fix'
- Better UTF8 support
- CharacterSet support
- Prefer `static let` over `static var` over `static func()` as appropriate.
- Debate over nomenclature `whitespace`, `space` vs `inlineSpace` vs `ASCII space 32`, `newline` vs `lineBreak`

# Known Issues

- It is currently a one-shot parser, and requires the input to be fully loaded in memory for parsing. This implicitly supports infinite backtracking, but that cannot be assumed in the future.
- The error reporting is minimal, and gives you the cursor of the last failed parse. The `label` function exists, but is effectively useless.
- This parser aims for simplicity of implementation, and some parser combinators could be implemented more efficiently.
- Due to Swift string and character mangling under the hood, functions like `oneOf` and `noneOf` do not function as expected when applied to newlines.
- Using the terminology 'throws' in the documentation for both raising parser errors, and raising swift runtime execution errors, is confusing. However, throws only means `(A) throws -> B` in the case of `Parser/parse(_:)`, and otherwise means failing parser. We will probably clean up the terminology or write an explainer later.
- Awkward single-character argument names in tutorials / documentation.
