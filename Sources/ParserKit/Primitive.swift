import FunctorKit

public extension Parse {
    
    /// Peeks at the next token, without consuming it.
    ///
    /// This parser fails with ``ParserError/endOfInput`` if it encounters the end of input.
    ///
    /// - Returns: A parser that produces the next token, if it exists.
    static var peekToken: Parser<Character> {
        return Parser.raw { st in
            switch st.1.first {
            case .none:
                return .failure(ParserFailure(cursor: st.0, error: .endOfInput))
            case let .some(c):
                return .success((c,st))
            }
        }
    }
    
    /// Parses any token.
    ///
    /// This parser fails with ``ParserError/endOfInput`` if it encounters the end of input.
    ///
    /// - Returns: A parser that produces any token, if it exists.
    static var anyToken: Parser<Character> {
        return Parser.raw { (st) in
            switch st.1.first {
            case .none:
                return .failure(ParserFailure(cursor: st.0, error: .endOfInput))
            case let .some(c):
                let cs = String(st.1.dropFirst())
                return .success((c,(st.0.increment(c),cs)))
            }
        }
    }
    
    /// Parses any token, matching it against a supplied predicate.
    ///
    /// This parser fails with ``ParserError/unexpected(_:)`` if it encounters a token that does not satisfy the supplied predicate.
    ///
    /// This parser fails with ``ParserError/endOfInput`` if it encounters the end of input.
    ///
    /// - Parameters:
    ///     - pred: The token predicate.
    ///
    /// - Returns: A parser that produces the next token, if it matches the predicate.
    static func satisfy(_ pred: @escaping (Character) -> Bool) -> Parser<Character> {
        return anyToken >>- { c in
            if pred(c) {
                return .pure(c)
            } else {
                return .unexpected(String(c))
            }
        }
    }
    
    /// Parses the end of file (input).
    ///
    /// This parser fails with ``ParserError/inputRemaining(_:)`` if it encounters any remaining input.
    ///
    /// - Returns: A parser that succeeds if there is no more input.
    static var eof: Parser<()> {
        return Parser.raw { st in
            switch st.1 {
            case "":
                return .success(((), st))
            default:
                return .failure(ParserFailure(cursor: st.0, error: .inputRemaining(st.1)))
            }
        }
    }
    
    /// Skips the remaining input, discarding it.
    ///
    /// Note that `skipRemainingInput <* eof` does not fail.
    ///
    /// > TODO: Rename discardRemainingInput, to disambiguate it from skip.
    ///
    /// - Returns: A parser that skips the remaining input.
    static var skipRemainingInput: Parser<()> {
        return anyToken.skipMany
    }
    
}

public extension Parser {
    
    /// Parses a single value and then discards the resulting value. Equivalent to `p ^> ()`.
    ///
    /// - Returns: A parser that produces a single value and then discards it.
    var skip: Parser<()> {
        // NOTE: Prefer `*> nil` over `^> ()`
        return self *> nil
        // Alternatively:
        // return self *> .pure(())
        // return self ^> ()
    }
    
    /// Parses zero or more occurrences of the value, and then discards the resulting values
    ///
    /// NOTE: This parser never fails, and may not consume input.
    ///
    /// - Returns: A parser that produces zero or more values, and then discards them.
    var skipMany: Parser<()> {
        return self.many.skip
    }

    /// Parses one or more occurrences of the value, and then discards the resulting values
    ///
    /// - Returns: A parser that produces one or more values, and then discards them.
    var skipSome: Parser<()> {
        return self.some.skip
    }
    
    /// Skips the remaining input, discarding it.
    ///
    /// Note that `skipRemainingInput <* eof` does not fail.
    ///
    /// A convenient alias for `p <* skipRemainingInput`.
    ///
    /// > TODO: Rename discardRemainingInput, to disambiguate it from skip.
    ///
    /// - Returns: A parser that skips the remaining input.
    var skipRemainingInput: Self {
        return self <* Parse.skipRemainingInput
    }
}
