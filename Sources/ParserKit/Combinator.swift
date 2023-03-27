import Foundation
import FunctorKit

public extension Parse {
    
    /// Tries to apply each parser in `parsers` in order, until one of them succeeds. Equivalent to using ``Parser/alt(_:)`` repeatedly.
    ///
    /// This parser succeeds if any of the parsers succeeds.
    ///
    /// ```swift
    /// let foobarqux = choice([
    ///       string("foo"),
    ///       string("bar"),
    ///       string("qux"),
    /// ])
    /// let foo = try! foobarqux.parse("foo") // Succeeds
    /// let bar = try! foobarqux.parse("bar") // Succeeds
    /// let qux = try! foobarqux.parse("qux") // Succeeds
    /// let zap = try! foobarqux.parse("zap") // Fails
    /// ```
    ///
    /// - Parameters:
    ///     - parsers: The list of parsers to try matching against.
    ///
    /// - Returns: The value of the succeeding parser.
    static func choice<T>(_ parsers: [Parser<T>]) -> Parser<T> {
        return parsers.reduce(.empty) { a, b in a <|> b }
    }
    
    /// This parser only succeeds when parser `p` fails.
    ///
    /// This parser does not consume any input.
    ///
    /// - Parameters:
    ///     - p: The parser to fail.
    ///
    /// - Returns: `()` if it succeeds.
    static func notFollowedBy<A>(_ p: Parser<A>) -> Parser<()> {
        return (nil as Parser).notFollowedBy(p)
    }
    
}

public extension Parser {
    
    /// Parses `n` occurrences of the value. If `n` is smaller or equal to zero, the parser returns `[]`.
    ///
    /// ```swift
    /// let fiveAs = char("a").count(5)
    /// let aaaaa = try! fiveAs.parse("aaaaa")  // Succeeds
    /// let aaaa = try! fiveAs.parse("aaaab")   // Fails
    /// ```
    ///
    /// - Parameters:
    ///     - n: The number of times to apply the parser.
    ///
    /// - Returns: The list of `n` parsed values.
    func count(_ n: Int) -> Parser<[Content]> {
        switch n {
        case _ where n <= 0:
            return .pure([])
        default:
            return { x in { xs in [x] + xs } } <^> self <*> self.count(n - 1)
        }
    }

    /// Tries to apply the parser, otherwise returning a default value `a`.
    ///
    /// ```swift
    /// let xElseA = char("x").option("a")
    /// let x = try! xElseA.parse("x")  // Succeeds
    /// let a = try! xElseA.parse("y")  // Succeeds
    /// ```
    ///
    /// > WARNING: This parser never fails. It does not yet consider whether the parser has consumed any input. In the future, this parser will only return the default value if it fails without consuming input
    ///
    /// - Parameters:
    ///     - a: The value to return if the parser fails.
    ///
    /// - Returns: The parsed value, else the default `a`.
    func option(_ a: Content) -> Self {
        return self <|> .pure(a)
    }

    /// Parses a value in between two other parsers, `open` and `close`. Equivalent to `open *> self <* close`.
    ///
    /// ```swift
    /// let open = char("(")
    /// let close = char(")")
    /// let foo = try! string("foo").between(open,close).parse("(foo)") // Succeeds
    /// ```
    ///
    /// - Parameters:
    ///     - open: The left opening parser. Its value is discarded.
    ///     - close: The right closing parser. Its value is discarded.
    ///
    /// - Returns: The parsed value.
    func between<Open,Close>(_ open: Parser<Open>, _ close: Parser<Close>) -> Self {
        return open *> self <* close
    }

    /// Parses a value surrounded by `quote`. Equivalent to `quote *> self <* quote`.
    ///
    /// ```swift
    /// let quote = char("'")
    /// let foo = try! string("foo").surround(quote).parse("'foo'") // Succeeds
    /// ```
    ///
    /// - Parameters:
    ///     - quote: The quoting parser. Its values are discarded.
    ///
    /// - Returns: The parsed value.
    func surround<Quote>(_ quote: Parser<Quote>) -> Self {
        return quote *> self <* quote
    }

    /// Parses zero or more occurrences of the parser, separated by `op`, The resulting values are combined them using a left-associative application of `op`. If there are zero resulting values, the value `a` is returned instead.
    ///
    /// ```swift
    /// typealias Binop = (Int) -> ((Int) -> Int)
    /// let min  = Parser<Binop> { x in { y in Swift.min(x,y) }}
    /// let p    = digit.map { Int(String($0))! } .chain(min, else: 0)
    /// let two  = try! p.parse("3924576") // Succeeds
    /// let zero = try! p.parse()          // Succeeds
    /// ```
    ///
    /// See also ``chain(_:)``.
    ///
    /// - Parameters:
    ///     - op: The combining parser.
    ///     - a:   The default value
    ///
    /// - Returns: The combined value, else `a`.
    func chain(_ op: Parser<(Content) -> ((Content) -> Content)>, else a: Content) -> Self {
        return self.chain(op) <|> .pure(a)
    }

    /// Parses one or more occurrences of the parser, separated by `op`, The resulting values are combined them using a left-associative application of `op`.
    ///
    /// ```swift
    /// typealias Binop = (Int) -> ((Int) -> Int)
    /// let min  = Parser<Binop> { x in { y in Swift.min(x,y) }}
    /// let p    = digit.map { Int(String($0))! } .chain(min)
    /// let two  = try! p.parse("3924576") // Succeeds
    /// let zero = try! p.parse()          // Fails
    /// ```
    ///
    /// This parser can for example be used to eliminate left recursion which typically occurs in expression grammars.
    ///
    /// ```swift
    /// typealias Binop = (Int) -> ((Int) -> Int)
    ///
    /// let integer = lexeme(digit.some.map { Int(String($0))! })
    ///
    /// let mul:   Binop = { x in { y in x * y }}
    /// let div:   Binop = { x in { y in x / y }}
    /// let plus:  Binop = { x in { y in x + y }}
    /// let minus: Binop = { x in { y in x - y }}
    ///
    /// let mulop = symbol("*") ^> mul
    ///         <|> symbol("/") ^> div
    ///
    /// let addop = symbol("+") ^> plus
    ///         <|> symbol("-") ^> minus
    ///
    /// let factor = { (rec: Parser<Int>) in parens(rec) <|> integer }
    /// let term   = { (rec: Parser<Int>) in factor(rec).chain(mulop) }
    /// let expr   = fix { rec in term(rec).chain(addop) }
    ///
    /// let result = try! expr.parse("5 + 3 * (12 - 10 / 2)")
    /// ```
    ///
    /// > NOTE: The `Binop` pattern `typealias Binop = (Int) -> ((Int) -> Int)` is used to stop Swift from falsely inferring a call to `Parser(fn:)` instead of `Parser(_:)`
    ///
    /// See also ``chain(_:else:)``.
    ///
    /// - Parameters:
    ///     - op: The combining parser.
    ///
    /// - Returns: The combined value.
    func chain(_ op: Parser<(Content) -> ((Content) -> Content)>) -> Self {
        func loop(_ x: Content) -> Self {
            return (op >>- { f in
                self >>- { y in
                    loop(f(x)(y))
                }
            }) <|> .pure(x)
        }
        return self >>- loop
    }
    
    /// Parses two values, one followed by the other, separated by `sep`, The resulting values are returned as a pair, and the separator is discarded.
    ///
    /// ```swift
    /// let (a,b) = try! char("a").sep(char("b"), by: inlineSpace).parse("a b")
    /// ```
    /// 
    /// - Parameters:
    ///     - p: The other parser.
    ///     - sep: The separator parser.
    ///
    /// - Returns: The pair of values.
    func sep<A,Sep>(_ p: Parser<A>, by sep: Parser<Sep>) -> Parser<(Content,A)> {
        return self <* sep >>- { a in
            return p >>- { b in
                return .pure((a,b))
            }
        }
    }

    /// Parses zero or more values, separated by `sep`.
    ///
    /// - Parameters:
    ///     - sep: The separator parser.
    ///
    /// - Returns: The list of values.
    func many<S>(sepBy sep: Parser<S>) -> Parser<[Content]> {
        return self.some(sepBy: sep) <|> .pure([])
    }

    /// Parses one or more values, separated by `sep`.
    ///
    /// - Parameters:
    ///     - sep: The separator parser.
    ///
    /// - Returns: The list of values.
    func some<S>(sepBy sep: Parser<S>) -> Parser<[Content]> {
        return { x in { xs in [x] + xs } } <^> self <*> (sep *> self).many
    }

    /// Parses zero or more values, separated and ended by `sep`.
    ///
    /// - Parameters:
    ///     - sep: The separator parser.
    ///
    /// - Returns: The list of values.
    func some<Sep>(endBy sep: Parser<Sep>) -> Parser<[Content]> {
        return (self <* sep).some
    }

    /// Parses one or more values, separated and ended by `sep`.
    ///
    /// - Parameters:
    ///     - sep: The separator parser.
    ///
    /// - Returns: The list of values.
    func many<Sep>(endBy sep: Parser<Sep>) -> Parser<[Content]> {
        return (self <* sep).many
    }

    /// Parses zero or more values, separated and optionally ended by `sep`.
    ///
    /// - Parameters:
    ///     - sep: The separator parser.
    ///
    /// - Returns: The list of values.
    func many<Sep>(sepEndBy sep: Parser<Sep>) -> Parser<[Content]> {
        return self.some(sepEndBy: sep) <|> .pure([])
    }

    /// Parses one or more values, separated and optionally ended by `sep`.
    ///
    /// - Parameters:
    ///     - sep: The separator parser.
    ///
    /// - Returns: The list of values.
    func some<Sep>(sepEndBy sep: Parser<Sep>) -> Parser<[Content]> {
        return self >>- { x in
            return (sep *> self.many(sepEndBy: sep) >>- { xs in
                return .pure([x] + xs)
            }) <|> .pure([x])
        }
    }
    
    /// Parses zero or more values,  ended by `end`.
    ///
    /// - Parameters:
    ///     - end: The end parser.
    ///
    /// - Returns: The list of values.
    func many<End>(till end: Parser<End>) -> Parser<[Content]> {
        return end ^> [] <|> some(till: end)
    }
    
    /// Parses one or more values,  ended by `end`.
    ///
    /// - Parameters:
    ///     - end: The end parser.
    ///
    /// - Returns: The list of values.
    func some<End>(till end: Parser<End>) -> Parser<[Content]> {
        return self >>- { head in
            return many(till: end) >>- { rest in
                return .pure([head] + rest)
            }
        }
    }
    
    /// This parser only succeeds when parser `p` fails after first parsing a value.
    ///
    /// This parser does not consume any input after parsing the first value.
    ///
    /// - Parameters:
    ///     - p: The parser to fail.
    ///
    /// - Returns: The first value.
    func notFollowedBy<A>(_ p: Parser<A>) -> Self {
        // TODO: attempt( ... )
        return self >>- { value in
            return (p >>- { a in
                return .unexpected("\(a)") as Self
            }) <|> Parser(value)
        }
    }

}
