# Writing a CSV parser

Create a parser for reading CSV (**C**omma-**S**eparated **V**alues) files.

## Overview

CSV files are a common plain-text file format for data storage and exchange. A CSV file consists of a `table` of `rows` of `cells`. The `rows` in a table are separated by `newlines`, the `cells` in a `row` are separated by `commas`, and the `cells` are `strings` (sequences of letters) that do not contain any `commas` or `newlines`. The format is dead simple, so simple in fact that we can implement a parser for it in only three lines of code.

As such, it makes an effective introduction to the powerful techniques of parsing with combinators. Parser combinators allow you to construct a parser by combining many smaller ones. This makes it easy to start at the bottom, and build our way to the top.

> NOTE: Fun fact: the CSV file format that has been in use for over 50 years, predating the modern existence of databases and datalakes.

For convenience, we will write our parsers as an extension to the ``Parse`` namespace.

```swift
extension Parse {
    enum CSV {
        // Our parsers go here
    }
}
```

## The cell parser

We'll start with the `cell` parser.

```swift
let cell = satisfy { $0 != "," && !$0.isNewline }.many.map { String($0) }
```

Let's break this down. 

A cell is any sequence of characters except for commas and newlines. Why not commas or newlines? Because they are used separate cells and rows, and so cells aren't allowed contain them, as they would start a new cell or row instead.

Here, we use ``Parse/satisfy(_:)`` and pass in the predicate `{ $0 != "," && !$0.isNewline }` to accept any character that is neither a comma or a newline. A cell is a string of zero or more such characters, and so we then use the ``Parser/many`` combinator to specify that we should parse as many characters as we can, until we hit one that doesn't match. Finally, we need to turn the list of characters back into a string, and so we simply finish up with a call to ``Parser/map(_:)`` with `{ String($0) }` to do so.

This gives us our first parser, which parses a single cell.

> WARNING: Due to Apple's string mangling, use `noneOf(",\r\n")` is unreliable. As a result, we use `satisfy { $0 != "," && !$0.isNewline }` instead.

## The row parser

Next is the `row` parser.

```swift
let row = cell.many(sepBy: ",")
```

A row is just a sequence of many cells separated by commas. This means that our row parser is very simple too. Here we use ``Parser/many(sepBy:)``, a variant of ``Parser/many`` which allows us to parse many values with a separator. In this case, our separator is a comma.

Note that ``Parser/many(sepBy:)`` actually accepts a parser as an argument, and we are using `ExpressibleByStringLiteral` to automatically convert `","` to a `Parser<String>` using ``Parse/string(_:)``.

## The table parser

Finally, we have the `table` parser.

```swift
let table = row.many(sepEndBy: lineBreak)
```

A table is just a sequence of many rows separated or ended by newlines. It is similar to the row parser, except here we use ``Parser/many(sepEndBy:)`` because we might have a trailing newline at the end of a file.

And that's it!

## Our final code

Let's take a look at all of our code put together.

```swift
extension Parse {
    enum CSV {
        static let cell  = satisfy { $0 != "," && !$0.isNewline }.many.map { String($0) }
        static let row   = cell.many(sepBy: ",")
        static let table = row.many(sepEndBy: lineBreak)
    }
}
```

See? Three parsers in three lines!

## Testing it out

Let's test it out.

```swift
let csv = try! Parse.CSV.table.parse("""
foo,bar,baz,qux
zip,zap,bip,bap
if,then,else,ni
""")
```

As you can see, if we print out the result, we have successfully parsed the CSV "file" into an array of arrays of strings:

```swift
print(csv)
// Prints:
// [["foo", "bar", "baz", "qux"], ["zip", "zap", "bip", "bap"], ["if", "then", "else", "ni"]]
```

We can even query a specific cell:

```swift
print(csv[1][2])
// Prints:
// "bip""
```

Not bad.

## Conclusion

It turns out that writing a CSV parser was almost trivial - the opening paragraph of this article was longer. Hopefully, this illustrates the power of parser combinators - it's amazing what you can accomplish in a few lines of code!

Fancier parsers may elect to do such things as trim whitespace from cells automatically, or allow escaping of commas and newlines within cells. Doing this is left as an exercise for the reader.



