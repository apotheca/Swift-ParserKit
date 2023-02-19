import Foundation

// In Haskell:
//  infixl 4 <$>, <$, $>
//  infixl 4 <*>, <*, *>
infix operator <^>  : FmapPrecedence
infix operator <^   : FmapPrecedence
infix operator ^>   : FmapPrecedence
infix operator <*>  : FmapPrecedence
infix operator <*   : FmapPrecedence
infix operator *>   : FmapPrecedence

precedencegroup FmapPrecedence {
    associativity: left
    higherThan: ChoicePrecedence
}

// In Haskell:
// infixl 3 <|>
infix operator <|> : ChoicePrecedence

precedencegroup ChoicePrecedence {
    associativity: left
    higherThan: BindPrecedence
}

// In Haskell:
//  infixl 1  >>, >>-
infix operator >>-  : BindPrecedence
infix operator >>   : BindPrecedence

precedencegroup BindPrecedence {
    associativity: left
    higherThan: RightBindPrecedence
}

// In Haskell:
//  infixr 1  =<<
infix operator -<<  : RightBindPrecedence

precedencegroup RightBindPrecedence {
    associativity: right
    higherThan: LabelPrecedence
}

// In Haskell:
//  infix 0 <?>
infix operator <?> : LabelPrecedence

precedencegroup LabelPrecedence {
    associativity: left
    higherThan: TernaryPrecedence
}

public extension Array {
    
    static func <^><B>(fn: @escaping (Element) -> B, a: [Element]) -> [B] {
        return a.map(fn)
    }
    
}

public extension Dictionary {
    
    static func <^><B>(fn: @escaping (Value) -> B, a: [Key:Value]) -> [Key:B] {
        return a.mapValues(fn)
    }
    
}

/// An infix operator for ``Parser/map(_:)``
public func <^><A,B>(fn: @escaping (A) -> B, p: Parser<A>) -> Parser<B> {
    return p.map(fn)
}

/// A convenient alias for ``Parser/constMap(_:)``
public func <^<A,B>(const: A, p: Parser<B>) -> Parser<A> {
    return p.constMap(const)
}

/// A convenient alias for ``Parser/constMap(_:)``
public func ^><A,B>(p: Parser<A>, const: B) -> Parser<B> {
    return p.constMap(const)
}

/// An infix operator for ``Parser/ap(_:)``
public func <*><A,B> (p: Parser<(A) -> B>, q:  Parser<A>) -> Parser<B> {
    return p.ap(q)
}

/// An infix operator for ``Parser/constAp(_:)``
public func <*<A,B> (p: Parser<A>, q: Parser<B>) -> Parser<A> {
    return ({ x in { _ in x }} <^> p) <*> q
}

/// An infix operator for ``Parser/skipAp(_:)``
public func *><A,B> (p: Parser<A>, q: Parser<B>) -> Parser<B> {
    return ({ _ in { y in y }} <^> p) <*> q
}

/// An infix operator for ``Parser/alt(_:)``
public func <|><A>(p: Parser<A>, q: Parser<A>) -> Parser<A> {
    return p.alt(q)
}

/// An infix operator for ``Parser/bind(_:)``
public func >>-<A,B> (p: Parser<A>, q: @escaping (A) -> Parser<B>) -> Parser<B> {
    p.bind(q)
}

/// An infix operator for ``Parser/bind(_:)`` that discards the result of the first parser.
///
/// Note the relationship to ``*>``, which is derived from ``Parser/ap(_:)`` compared to `>>`, which is derived from ``Parser/bind(_:)``.
public func >><A,B> (p: Parser<A>, q: Parser<B>) -> Parser<B> {
    p.bind { _ in q }
}

/// A flipped infix operator for ``Parser/bind(_:)``
public func -<<<A,B> (p: @escaping (B) -> Parser<A>, q: Parser<B>) -> Parser<A> {
    q.bind(p)
}

/// An infix operator for ``Parser/label(_:)``
public func <?><A>(p: Parser<A>, s: String) -> Parser<A> {
    return p.label(s)
}
