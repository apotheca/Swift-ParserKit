# ``ParserKit/Parse``

@Metadata {
    @DocumentationExtension(mergeBehavior: append)
}

## Topics

### Primitive

- ``peekToken``
- ``anyToken``
- ``satisfy(_:)``
- ``eof``
- ``skipRemainingInput``

### Character

- ``anyChar``
- ``char(_:)``
- ``oneOf(_:)``
- ``noneOf(_:)``
- ``whitespace``
- ``inlineSpace``
- ``lineBreak``
- ``notWhitespace``
- ``notInlineSpace``
- ``notLineBreak``
- ``lower``
- ``upper``
- ``letter``
- ``alphaNum``
- ``digit``
- ``octDigit``
- ``hexDigit``

### String

- ``string(_:)``
- ``strings(_:)``

### Combinators

- ``choice(_:)``
- ``notFollowedBy(_:)``

### Recursive

- ``fix(_:)``

### Language

- ``skipWhitespace``
- ``skipInlineSpace``
- ``skipLineComment(_:)``
- ``lexeme(_:)``
- ``symbol(_:)``
- ``parens(_:)``
- ``braces(_:)``
- ``angles(_:)``
- ``brackets(_:)``
- ``semicolon``
- ``comma``
- ``colon``
- ``dot``
