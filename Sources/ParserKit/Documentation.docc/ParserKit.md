# ``ParserKit``

A Swift implementation of a monadic parser-combinator library. Analogous to [parsec](https://hackage.haskell.org/package/parsec).

## Overview

The beautiful thing about parsers is that if you know how to write them, you don't need to worry about having a favorite programming language, because you can bring it with you to any other language.

Parsers are a powerful tool for solving many problems in programming. We can think of parsers as a function taking some less-structured input, and producing some more-structured output from it, having analyzed its structure. Almost every program uses parsing *somehow*, often to pre-process any input it might receive.

The Swift standard library already comes with a few basic parsers that we use frequently. These are usually manifested as an optional initializer for the data type taking a string argument - for example, `Int("5")!`, or `Decimal(string:"20.4")!`. However, these parsers are bare functions that must be used manually, as they lack the expected support of a full implementation. So, while Swift comes with a few basic *parsers*, it does not really have support for *parsing* in general, and this often leads to ad-hoc implementations and fragile or unmaintainable code in situations where a proper parsing solution might be helpful.

This library provides an implementation of parser combinators, a flexible and functional method of parsing data wherein we build up larger parsers by using smaller parsers as components. In particular, by treating parsers as functions, we can write simple parsers that take advantage of reuseable code, reducing the total amount of complexity and leading to an easier understanding of what's going on in your code.

## Topics

### Tutorials

These are some tutorials.

- <doc:Quickstart>
- ``Parser``
- ``Parse``
- <doc:CSV>
- <doc:Math>
- <doc:JSON>

### Parser Internals

These structures are subject to change.
- ``ParserInput``
- ``ParserToken``
- ``ParserCursor``
- ``ParserState``
- ``ParserError``
- ``ParserFailure``
- ``ParserResult``
