# ``ParserKit/Parser``

@Metadata {
    @DocumentationExtension(mergeBehavior: append)
}

## Topics

### Creating parsers

- ``init(_:)``
- ``init(fail:)``
- ``raw(_:)``

### Running parsers

- ``runParser``
- ``parse(_:)``

### Functor

- ``map(_:)``
- ``constMap(_:)``

### Applicative

- ``pure(_:)``
- ``ap(_:)``
- ``constAp(_:)``
- ``skipAp(_:)``

### Monad

- ``bind(_:)``

### Alternative
- ``empty``
- ``alt(_:)``

### Recursive

- ``fix(_:)``

### Combinators

- ``count(_:)``
- ``option(_:)``
- ``between(_:_:)``
- ``surround(_:)``
- ``sep(_:by:)``
- ``notFollowedBy(_:)``

### Many

- ``many``
- ``many(sepBy:)``
- ``many(sepEndBy:)``
- ``many(endBy:)``
- ``many(till:)``

### Some

- ``some``
- ``some(sepBy:)``
- ``some(sepEndBy:)``
- ``some(endBy:)``
- ``some(till:)``

### Chain

- ``chain(_:)``
- ``chain(_:else:)``

### Skip

- ``skip``
- ``skipMany``
- ``skipSome``
- ``skipRemainingInput``

### Errors

- ``label(_:)``
- ``endOfInput()``
- ``expected(_:)``
- ``fail(_:)``
- ``failure(_:)``
- ``inputRemaining(_:)``
- ``unexpected(_:)``
