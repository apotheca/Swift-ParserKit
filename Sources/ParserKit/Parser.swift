import Foundation

// TODO: ParserInput streams
//public enum ParserInput<Token> {
//    case sequence(AnySequence<Token>)
//    case collection(AnyCollection<Token>)
//}

/// The parser input type. Currently, it is always `String`.
public typealias ParserInput = String

/// The parser token type. Currently, it is always `Character`.
public typealias ParserToken = Character

/// A structure for keep track of ther parser's position within the input stream.
///
/// Useful for reporting the positions of errors.
public struct ParserCursor {
    
    /// The current line position.
    ///
    /// This value is incremented by linebreaks.
    public let line: Int
    
    /// The column position within the current line.
    ///
    /// This value is incremented by each token and is reset by linebreaks.
    ///
    /// This value counts tabs (`\t`) as four spaces (`    `).
    public let column: Int
    
    /// The character offset within the current input.
    ///
    /// This value is incremented by each token.
    public let offset: Int
    
    /// Creates a cursor with the following line, column, and total offset positions.
    public init(line: Int, column: Int, offset: Int) {
        self.line = line
        self.column = column
        self.offset = offset
    }
    
    /// The default starting cursor
    public static let zero: ParserCursor = ParserCursor(line: 0,column: 0, offset: 0)
    
    /// Increments the line, column, and offset accordingly.
    ///
    /// This allows us to treat tabs as groups of four spaces.
    public func increment(_ token: ParserToken) -> ParserCursor {
        switch token {
        case "\n":
            return ParserCursor(line: line + 1, column: 0,          offset: offset + 1)
        case "\t":
            return ParserCursor(line: line,     column: column + 4, offset: offset + 1)
        default:
            return ParserCursor(line: line,     column: column + 1, offset: offset + 1)
        }
    }
    
}

/// The parser internal state.
///
/// This structure is used to keep track of the cursor and input, as well as any other data in the future.
public struct ParserState {
    
    public let cursor: ParserCursor
    public let input: ParserInput
    
    public init(cursor: ParserCursor, input: ParserInput) {
        self.cursor = cursor
        self.input = input
    }
    
}

/// An enumeration of possible parsing errors.
public enum ParserError: Swift.Error, Equatable {
    
    /// Unexpected end of input, thrown by ``Parse/peekToken``and ``Parse/anyToken`` (and thus by ``Parse/satisfy(_:)``) .
    case endOfInput
    /// Unexpected input remaining,thrown by ``Parse/eof`` and ``Parser/parse(_:)`` .
    case inputRemaining(String)
    /// Unexpected input, thrown by ``Parse/satisfy(_:)``
    case unexpected(String)
    /// Expected parsable input, thrown by ``Parser/label(_:)``
    case expected(String)
    /// Thrown for a custom reason, thrown by any custom parser.
    case failure(String)
    /// Thrown by empty
    case empty
}

/// An representation of a ``ParserError`` at a specific ``ParserCursor`` position within the input.
///
/// Useful for figuring out where an error occurred.
public struct ParserFailure: Swift.Error {
    
    public let cursor: ParserCursor
    public let error: ParserError
    
    public init(cursor: ParserCursor, error: ParserError) {
        self.cursor = cursor
        self.error = error
    }
    
}

/// The resulting value of a parser, or any error encountered while producing it.
public enum ParserResult<Content> {
    
    case failure(ParserFailure)
    case success(Content)
    
    public func map<A>(_ fn: @escaping (Content) -> A) -> ParserResult<A> {
        switch self {
        case let .failure(e): return .failure(e)
        case let .success(a): return .success(fn(a))
        }
    }
    
}

/// The core of the ``ParserKit`` library.
///
/// This struct is a strongly-typed wrapper around `(State) -> Result<(Content,State)>`, and it contains all of the functions necessary for composing larger parsers out of smaller parser combinators.
public struct Parser<Content> {
    
    public typealias Input = ParserInput
    public typealias Token = Input.Element
    public typealias Cursor = ParserCursor
    public typealias State = (Cursor, Input)
    public typealias Error = ParserError
    public typealias Result = ParserResult
    
    /// The core of ``Parser`` is a simple function that takes input, and produces a value plus the remaining input, unless it fails with an error.
    public let runParser: (State) -> Result<(Content,State)>
    
    /// Creates a new parser from the given value, lazily with an autoclosure.
    ///
    /// This is effectively a lazy ``Parser/pure(_:)``, useful for fixing Swift's strict / eager evaluation sometimes
    ///
    /// See also ``Parser/fix(_:)``.
    ///
    /// - Parameters:
    ///     - value: The lazy value.
    ///
    /// - Returns: A parser that returns the lazy value.
    public init(_ value: @escaping @autoclosure () -> Content) {
        self.runParser = { .success( (value(), $0) ) }
    }
    
    /// Creates a parser from a raw `(State) -> Result<(Content,State)>` function, continuing the parse from the provided state.
    ///
    /// You probably don't need this, unless you are constructing new primitive parsers.
    ///
    /// > NOTE: This function is private because it causes interference with inferring ``Parser/init(_:)`` sometimes.
    ///
    /// - Parameters:
    ///     - fn: The raw parser state function.
    ///
    /// - Returns: A parser that continues from the provided state..
    private init(fn: @escaping (State) -> Result<(Content,State)>) {
        self.runParser = fn
    }
    
    /// Creates a parser from a raw `(State) -> Result<(Content,State)>` function, continuing the parse from the provided state.
    ///
    /// You probably don't need this, unless you are constructing new primitive parsers.
    ///
    /// - Parameters:
    ///     - fn: The raw parser state function.
    ///
    /// - Returns: A parser that continues from the provided state..
    public static func raw(_ fn: @escaping (State) -> Result<(Content,State)>) -> Self {
        return self.init(fn: fn)
    }
    
    /// Creates a parser from a raw ``ParserError``
    ///
    ///You probably don't need this, unless you are constructing new primitive parsers.
    ///
    /// - Parameters:
    ///     - fail: The error to fail with.
    ///
    /// - Returns: A parser that immediately fails with the provided error.
    public init(fail error: ParserError) {
        self.runParser = { st in .failure(ParserFailure(cursor: st.0, error: error)) }
    }
    
    /// Runs the parser, extracting the resulting value.
    ///
    /// This function throws a ``ParserError/inputRemaining(_:)`` if it does not consume all input. It also throws some ``ParserError`` if a value cannot be produced.
    ///
    /// To make a parser consume all input, use  ``Parse/eof`` (as in `(p <* eof).parse("input")`).
    ///
    ///NOTE: For convenience, parse() is the same as parse("").
    ///
    /// - Parameters:
    ///     - input: The string input to be parsed, else the empty string.
    ///
    /// - Returns: The fully parsed value..
    public func parse(_ input: String = "") throws -> Content {
        switch runParser((Cursor.zero,input)) {
        case let .failure(e):
            throw e
        case let .success((_, (_,input))) where !input.isEmpty:
            throw Error.inputRemaining(input)
        case let .success((output, _)):
            return output
        }
    }
    
    /// The fixpoint parser; useful for fixing Swift's strict / eager evaluation
    ///
    /// This can be necessary for recursive parsers. See also: ``Parser/init(_:)``.
    ///
    /// > NOTE: This probably could be implemented via the init autoclosure but this is fine too.
    ///
    /// - Parameters:
    ///     - fn: A non-recursive base parser that takes an explicit parameter for continuation / recursion.
    ///
    /// - Returns: The recursive parser.
    public static func fix(_ fn: @escaping (Self) -> Self) -> Self {
        var p: Self!
        let lazy = Self { st in
            return p.runParser(st)
        }
        p = fn(lazy)
        return p
    }
    
    // Functor
    
    /// Map a function over the content of a parser, transforming it.
    ///
    /// > NOTE: This requires that the function be escaping, because a parser combinatior maps via function composition.
    ///
    /// This function has a convenient infix operator alias ``<^>``
    ///
    /// - Parameters:
    ///     - fn: A function that transforms the content of the parser.
    ///
    /// - Returns: The transformed parser.
    public func map<A>(_ fn: @escaping (Content) -> A) -> Parser<A> {
        return Parser<A> { st in
            let result = runParser(st)
            switch result {
            case let .failure(e):
                return .failure(e)
            case let .success((a,st2)):
                return .success((fn(a),st2))
            }
        }
    }
    
    public func constMap<A>(_ const: A) -> Parser<A> {
        return map { _ in const }
    }
    
    // Applicative
    
    /// Lifts a value into a parser.
    ///
    /// - Parameters:
    ///     - val: The value to parse.
    ///
    /// - Returns: A parser that immediately succeeds with the value.
    public static func pure(_ val: Content) -> Parser<Content> {
        return Parser.raw { st in
            return .success((val,st))
        }
    }
    
    /// Applies a lifted function to a lifted value, producing a parser that returns the result of applying the function to the value.
    ///
    /// This function is useful when you have a parser for a function, and a parser for an argument, and you want to get a parser for the result.
    ///
    /// Consider the relationship between ``Parser/ap(_:)`` and regular function application. Note that `f(a)` is equivalent to `pure(f).ap(pure(a))`:
    ///
    /// ```swift
    /// let b =      f    (     a )
    /// let b = pure(f).ap(pure(a)).parse()
    /// ```
    ///
    /// This function has a convenient infix operator alias ``<*>``. This can reduce the number of parenthesis.
    ///
    /// ```swift
    /// let r = f.ap(a).ap(b).ap(c)
    /// let r = f <*> a <*> b <*> c
    /// ```
    /// Consider the relationship between `ap` and ``Parser/map(_:)``. Note that `pure(f) <*> a` is equivalent to `f <^> a`:
    ///
    /// ```swift
    /// let r = pure(f) <*> a
    /// let r =      f  <^> a
    /// ```
    ///
    /// - Parameters:
    ///     - arg: A parser that produces an argument
    ///
    /// - Returns: A parser applying the result of arg to the contained function.
    public func ap<X,Y>(_ arg: Parser<X>) -> Parser<Y> where Content == ((X) -> Y) {
        return Parser<Y> { (st) in
            switch runParser(st) {
            case let .failure(e):
                return .failure(e)
            case let .success((f,st2)):
                switch arg.runParser(st2) {
                case let .failure(e):
                    return .failure(e)
                case let .success((a,st3)):
                    return .success((f(a), st3))
                }
            }
        }
    }
    
    /// Parses one value followed by another, ignoring the result of the second parser.
    ///
    /// - Parameters:
    ///     - q: A parser to ignore.
    ///
    /// - Returns: A parser that returns the value of the first parser..
    public func constAp<B> (_ q: Parser<B>) -> Parser<Content> {
        return self.map { x in { _ in x } } .ap(q)
    }
    
    
    /// Parses one value followed by another, ignoring the result of the first parser
    ///
    /// - Parameters:
    ///     - q: A parser to return the value of.
    ///
    /// - Returns: A parser that returns the value of q.
    public func skipAp<B> (_ q: Parser<B>) -> Parser<B> {
        return self.map { _ in { y in y } } .ap(q)
    }
    
    // Monad
    
    /// Parsers one value, and apply it immediately to a function to produce another parser.
    ///
    /// This is useful when you want to do something with the results of a parser, inside another parser, and is more convenient than calling ``Parser/runParser`` and handling the state manually.
    ///
    /// ```swift
    /// let foobar = string("foo") >>- ( foo in
    ///     string("bar") >>- { bar in
    ///         let result = (foo,bar)
    ///         return .pure(result)
    ///     }
    /// )
    /// ```
    ///
    /// This function has a convenient infix operator alias ``>>-``. This can reduce the number of parenthesis.
    ///
    ///```swift
    /// let bParser = aParser >>- { a in
    ///     return a.toB()
    /// }
    /// ```
    ///
    /// Consider the relationship between `bind` and ``Parser/map(_:)``.
    ///
    /// - Parameters:
    ///     - fn: A function that produces a parser.
    ///
    /// - Returns: A parser applying the result of this parser to fn.
    public func bind<B>(_ fn: @escaping (Content) -> Parser<B>) -> Parser<B> {
        return Parser<B> { (st) in
            switch runParser(st) {
            case let .failure(e):
                return .failure(e)
            case let .success((a,st2)):
                return fn(a).runParser(st2)
            }
        }
    }
    
    // Alternative

    /// The empty parser; it fails immediately.
    ///
    /// - Returns: The empty parser.
    public static var empty: Parser<Content> {
        return Parser(fail: .empty)
    }
    
    /// The alternative parser; if the first parser fails, it ignores the failure and tries the second parser.
    ///
    /// - Parameters:
    ///     - alt: A parser to try in case the first one fails.
    ///
    /// - Returns: A parser that tries both parsers before failing.
    public func alt(_ alt: Parser<Content>) -> Parser<Content> {
        return Parser { (st) in
            switch runParser(st) {
            case .failure(_):
                return alt.runParser(st)
            case let right:
                return right
            }
        }
    }
    
    /// Parses one or more occurrences of the value.
    ///
    /// - Returns: A parser that produces a list of one or more values.

    public var some: Parser<[Content]> {
        return self.map { x in { xs in [x] + xs } } .ap(self.many)
    }
    
    
    /// Parses zero or more occurrences of the value.
    ///
    /// NOTE: This parser never fails, and may return an empty list without consuming input. This can cause a parser to loop forever. Users should be wary of using `many`, especially when dealing with recursive parsers.
    ///
    /// - Returns: A parser that produces a list of zero or more values.
    public var many: Parser<[Content]> {
        return Parser<[Content]> { st in
            switch self.runParser(st) {
            case .failure(_):
                return Parser<[Content]>.pure([]).runParser(st)
            case let .success((x,st2)):
                return (self.many.map { xs in [x] + xs }).runParser(st2)
            }
        }
    }
    
    // Parse errors
    
    /// Fails immediately, using the provided ``ParserError``. Equivalent to calling ``Parser/init(fail:)``
    ///
    /// - Parameters:
    ///     - error: The error to fail with.
    ///
    /// - Returns: A parser that immediately fails with the provided error.
    public static func fail(_ error: Error) -> Parser<Content> {
        return Parser(fail: error)
    }
    
    /// Fails immediately; thrown by ``Parse/peekToken`` and ``Parse/anyToken`` (and thus by ``Parse/satisfy(_:)``) upon an unexpected end of input.
    /// - Returns: A parser that immediately fails.
    public static func endOfInput() -> Parser<Content> {
        return fail(.endOfInput)
    }
    
    /// Fails immediately; thrown by ``Parse/eof`` and ``Parser/parse(_:)`` upon an unexpected input remaining.
    ///
    /// - Parameters:
    ///     - input: The remaining input.
    ///
    /// - Returns: A parser that immediately fails with the remaining input.
    public static func inputRemaining(_ input: String) -> Parser<Content> {
        return fail(.inputRemaining(input))
    }
    
    /// Fails immediately; thrown by ``Parse/satisfy(_:)`` upon unexpected input.
    ///
    /// - Parameters:
    ///     - input: The unexpected input.
    ///
    /// - Returns: A parser that immediately fails with the unexpected input.
    public static func unexpected(_ input: String) -> Parser<Content> {
        return fail(.unexpected(input))
    }
    
    /// Fails immediately; thrown by ``Parser/label(_:)`` upon encountering another error
    ///
    /// - Parameters:
    ///     - label: The label for the expected input.
    ///
    /// - Returns: A parser that immediately fails with the expected label.
    public static func expected(_ label: String) -> Parser<Content> {
        return fail(.expected(label))
    }
    
    /// Fails immediately; thrown for any custom reason.
    ///
    /// - Parameters:
    ///     - reason: The reason for the custom failure.
    ///
    /// - Returns: A parser that immediately fails with the custom reason
    public static func failure(_ reason: String) -> Parser<Content> {
        return fail(.failure(reason))
    }
    
    // Labeling
    
    /// Replaces a complex deeper error with a simpler label of the expected type.
    ///
    /// Useful for renaming errors.
    ///
    /// ```swift
    /// // Reports the expectation as "expected foo or bar or qux"
    /// string("foo") <|> string("bar") <|> string("qux")
    ///
    /// // Reports the expected type as "expected zap"
    /// string("foo") <|> string("bar") <|> string("qux") <?> "zap
    /// ```
    ///
    /// - Parameters:
    ///     - input: The expected input label.
    ///
    /// - Returns: A parser that renames the expected input when there is an error.
    public func label(_ s: String) -> Parser<Content> {
        return Parser<Content> { st in
            switch self.runParser(st) {
            case .failure:
                return .failure(ParserFailure(cursor: st.0, error: .expected(s)))
            case let .success(s):
                return .success(s)
            }
        }
    }
    
}

// Nil as unit
// NOTE: nil as unit yields `foo *> nil` == `foo *> .pure(())` == `foo ^> ()`
extension Parser: ExpressibleByNilLiteral where Content == () {

    public init(nilLiteral: ()) {
        self = .pure(nilLiteral)
    }

}

// Syntax sugar for Parse.string
// NOTE: We cannot conform to where Content == Character and Content == String at the same time
//  Thus, string literals refer to the string parser, and so ",": Parser<String>, not Parser<Character>
extension Parser: ExpressibleByUnicodeScalarLiteral where Content == String {

    public init(unicodeScalarLiteral value: String) {
        self.init(stringLiteral: value)
    }
}

// Syntax sugar for Parse.string
// NOTE: We cannot conform to where Content == Character and Content == String at the same time
//  Thus, string literals refer to the string parser, and so ",": Parser<String>, not Parser<Character>
extension Parser: ExpressibleByExtendedGraphemeClusterLiteral where Content == String {

    public init(extendedGraphemeClusterLiteral value: String) {
        self.init(stringLiteral: value)
    }

}

// Syntax sugar for Parse.string
// NOTE: We cannot conform to where Content == Character and Content == String at the same time
//  Thus, string literals refer to the string parser, and so ",": Parser<String>, not Parser<Character>
extension Parser: ExpressibleByStringLiteral where Content == String {

    public init(stringLiteral value: String) {
        self = Parse.string(value)
    }

}

// Syntax sugar for choice
// NOTE: This sometimes requires explicit type annotation or casting with 'as'
extension Parser: ExpressibleByArrayLiteral {
    
    public typealias ArrayLiteralElement = Self
    
    public init(arrayLiteral elements: Parser<Content>...) {
        self = Parse.choice(Array(elements))
    }
    
}
