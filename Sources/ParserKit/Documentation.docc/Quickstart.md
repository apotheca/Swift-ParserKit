# Quickstart

Get started parsing quickly.

## Overview

This document is intended to get you up and parsing quickly, without going too much into the theory of construction behind it. If you want a more in-depth explanation, see the advanced tutorials.

To get started, simply import this library.

```swift
import ParserKit
```

## The Parse namespace

For convenience, we have provided the ``Parse`` namespace, where we may declare top-level and static parsers: 

```swift
extension Parse {
    
    // Our static and top-level parsers go here
    
    static let foo: Parser<Foo> = ...
    
    static func barred(_ foo: Foo) -> Parser<Bar> {
        ...
    }
    
}
```

Unless otherwise stated, we will write our parsers in this namespace. This is done to avoid polluting the global namespace or the need to fully qualify references to parsers. This was chosen in favor of extensions to ``Parser``, which can often break type inference requiring explicit type annotation.

Instance parsers may still be written as extensions to ``Parser``, since they chain off of an existing parser.

```swift
extension Parser where Content == Foo {

    // Our instance-level parsers go here.

    var barred: Parser<Bar> {
        ...
    }

}
```

If there is a single canonical format for a given data type, parsers associated with it should be declared as an extension to the data type, or otherwise inside a nested enum extension to Parse.

```swift
enum CSV {
        
    enum Parser {
        // Our parsers go here
        static let cell  = ...
        static let row   = ...
        static let table = ...
    }
    
    let parser = ...
    
}

extension Parse {

    enum CSV {
        // Or here
        static let cell  = ...
        static let row   = ...
        static let table = ...
    }
    
    static let csv = ...
    
}
```

> NOTE: These are not hard rules, and if you prefer another method of organizing parsers, have at it! We've picked this way of doing it to allow you that flexibility!


## The Parser data type

The core of this library is the ``Parser`` data type.

```swift
struct Parser<Content> {
    
    init(_ value: @escaping @autoclosure () -> Content)
    
    func parse(_ input: String = "") throws -> Content
    
}
```

It is a `generic` data type, and its generic argument is the data type that it returns upon a successful parse.

We can create a parser by putting a value into it using ``Parser/init(_:)``.

```swift
let three = Parser(3)
```

We can get the value back out by running the parser using ``Parser/parse(_:)``. If we put a value directly into a parser, we do not need to consume any input to get it out.

```swift
let three = Parser(3)
let n = try three.parse()
print(n)
// Prints:
// 3
```

Other parsers will potentially require and consume input.

## Primitive parsers

A parser reads input one character at a time, and we can match any character with ``Parse/anyChar``, which will always succeed if there is any input, or throw an error if there isn't.

```swift
let anything = try anyChar.parse("a") // Succeeds with a
print(anything)
// Prints:
// a
let nothing = try anyChar.parse()    // Fails with unexpected end of input
```

We can filter characters with a predicate using ``Parse/satisfy(_:)``. If a parser doesn't match the input, it may throw an error instead of returning a value.

```swift
let justS = try satisfy { $0 == "s" }
let s = try justS.parse("s") // Succeeds with s
let x = try justS.parse("x") // Fails
```

## Parsing characters and strings

We can match specific characters using ``Parse/char(_:)``, which is more convenient than `satisfy { $0 == "s" }`

```swift
let c = try char("c").parse("c")
```

We can match whole strings using ``Parse/string(_:)``.

```swift
let str = try string("str").parse("str").
```

For convenience, ``Parser`` has implemented ``ExpressibleByStringLiteral`` using ``Parse/string(_:)``, though this may sometimes (but not always) require explicit type annotation.

```swift
// Require an explicit annotation
let foo = "foo" as Parser
// Does not, because it infers that it is a parser from context.
let foobar = "foo" <|> "bar"
```

## Parsing multiple items

We can match a parser zero or more times using ``Parser/many``. This parser will always succeed, because instead of failing, it will return zero results without consuming input.

```swift
let foos = ("foo" as Parser).many
let threeFoos = try foos.parse("foofoofoo")
print(threeFoos)
// Prints:
// [ "foo", "foo", "foo" ]
let zeroFoos = try foos.parse()
print(zeroFoos)
// Prints:
// [ ]
```

We can match a parser one or more times using ``Parser/some``. This parser will fail if it does not parse at least one value successfully.

```swift
let foos = ("foo" as Parser).some
let threeFoos = try foos.parse("foofoofoo")
print(threeFoos)
// Prints:
// [ "foo", "foo", "foo" ]
let zeroFoos = try foos.parse() // Fails with expected foo
```

## Trying multiple parsers

In addition to trying one parser multiple times, we can also try multiple parsers. If one parser fails, we can try another parser using ``Parser/alt(_:)`` or its infix operator ``<|>``.

```swift
let foobar = "foo" <|> "bar"
let foo = try foobar.parse("foo") // Succeeds with foo
let bar = try foobar.parse("bar") // Succeeds with bar
let qux = try foobar.parse("qux") // Fails
```

If we have multiple alternatives, we can use ``Parse/choice(_:)``. This is the same as using ``<|>`` repeatedly, or `reduce(.empty, <|>)`

```swift
let trio = choice([ "foo", "bar", "qux" ])
let foo = try trio.parse("foo") // Succeeds with foo
let bar = try trio.parse("bar") // Succeeds with bar
let qux = try trio.parse("qux") // Succeeds with qux
let zap = try trio.parse("zap") // Fails
```

## Transforming parsers

A parser can be transformed using ``Parser/map(_:)`` or its infix operator ``<^>``, which mimics a function call inside of a parser.

```swift
let f = { $0 * 2 }
//        f (          3)
let six = f <^> Parser(3)
let n = try six.parse()
print(n)
// Prints:
// 6
```

We can also ignore the parser's content during ``Parser/map(_:)``, replacing it unconditionally with ``^>`` (or its flipped sibling `<^`), where `p ^> x` is short for `p.map { _ in x }`. The original parser must still succeed, but it will return the new content instead.

```swift
let fooButThree = "foo" ^> 3
let n = try fooButThree.parse("foo") // Succeeds with foo, but returns 3
print(n)
// Prints:
// 3
```

## Applying function-parsers

We can also put a function into a parser using ``Parser/init(_:)``  or ``Parser/pure(_:)``. This yields a function parser `Parser<(In) -> Out>`, and we can then use ``Parser/ap(_:)`` or its infix operator ``<*>`` to apply it to an argument parser `Parser<In>`, combining them into one result parser `Parser<Out>`.

```swift
let f = { $0 * 2 }
//                f  (          2)
let four = Parser(f) <*> Parser(2)
let n = try four.parse()
print(n)
// Prints:
// 4
```

It can also be used to mimic a comma in a function call.

```swift
let f2 = { x in { y in x + y } }
//          f2 (          3  ,          5)
let eight = f2 <^> Parser(3) <*> Parser(5)
let n = try eight.parse()
print(n)
// Prints:
// 8
```

Nested lambdas with types like ``(Int) -> ((Int) -> Int)`` can be hard to read. We could have written the previous example using ``ParserKit/curry(_:)`` instead.

```swift
//                +  (          3  ,          5)
let eight = curry(+) <^> Parser(3) <*> Parser(5)
let n = try eight.parse()
print(n)
// Prints:
// 8
```

We can also combine two parsers by throwing away the result of one and returning only the result of the other, using ``*>`` (or its flipped sibling ``<*``). Both parsers must still succeed, but it will return the new content instead.

```swift
let fooThenBar = "foo" *> "bar"
let bar = try fooThenBar.parse("foobar") // Succeeds with foo and bar, but only returns bar
print(bar)
// Prints:
// bar
```

## Piping parser-functions

We can also peek at the result of a parser mid-parse, by piping it into a parser-function `(In) -> Parser<Out>` using ``Parser/bind(_:)`` or its infix operator ``>>-``. This allows us to use the result of one parser to choose another, which we couldn't do with just ``Parser/map(_:)`` or ``Parser/ap(_:)``

Instead of throwing it away, we can also peek at the result of a parser mid-parse, and use that result to decide what to do with the next parser by piping it into a function that returns another parser.

```swift
let foobar = "foo" <|> "bar"
let quxzap = foobar >>- { fb in
    switch fb {
    case "foo": return "qux" // as Parser
    case "bar": return "zap" // as Parser
    }
}
let qux = try quxzap.parse("fooqux") // Succeeds with foo, which then chooses and succeeds with qux
print(qux)
// Prints:
// qux
let zap = try quxzap.parse("barzap") // Succeeds with bar, which then chooses and succeeds with zap
print(qux)
// Prints:
// zap
```

## Recursive parsers

Parsers frequently require recursion, which can be tricky due to Swift's eager / strict evaluation. We can use explicit recursion and the ``Parser/fix(_:)`` function to safely pass a parser function to itself as an argument, tying the knot without looping forever.

```swift
func succ(_ rec: Parser<Int>) -> Parser<Int> {
    return "s" *> rec.map({ $0 + 1 })
}
let zero: Parser<Int> = "z" ^> 0
let nat: Parser<Int> = fix { rec in
    succ(rec) <|> zero
}
print(try nat.parse("z"))
// Prints:
// 0
print(try nat.parse("sz"))
// Prints:
// 1
print(try nat.parse("sssz"))
// Prints:
// 3
```

## Parser equivalences

Note that these are equivalent:

```swift
let f = { a in { b in ... } }
let a = ...
let b = ...
let fab0 = Parser(f  (          a  ,          b))
let fab1 =        f  <^> Parser(a) <*> Parser(b)
let fab2 = Parser(f) <*> Parser(a) <*> Parser(b)
```

So are these:

```swift
let fooButBar0 = "foo" ^> "bar"
let fooButBar1 = { _ in "bar" } <^> "foo"
let fooButBar2 = "foo" *> Parser("bar")
let fooButBar3 = Parser({ _ in "bar" }) <*> "foo"
let bar = try fooButBar0.parse("foo")
print(bar)
// Prints:
// bar
```

And so are these:

```swift
let fooThenBar0 = "foo" *> "bar"
let fooThenBar1 = "foo" >>- { _ in "bar" }
let bar = try fooThenBar0.parse("foobar")
print(bar)
// Prints:
// bar
```

## Conclusion

There's a lot to unpack here, but this is enough to get you started on the more advanced tutorials.
