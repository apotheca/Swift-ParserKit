public extension Parse {
    
    /// Skips any whitespace, discarding the value.
    ///
    /// - Returns: Nothing.
    static var skipWhitespace: Parser<()> {
        return whitespace.skipMany
    }
    
    /// Skips any inline whitespace, discarding the value
    ///
    /// - Returns: Nothing.
    static var skipInlineSpace: Parser<()> {
        return inlineSpace.skipMany
    }
    
    /// Skips any single-line comments. Line comments start with the `prefix`, and consume there rest of the line.
    ///
    /// - Parameters:
    ///     - prefix: The prefix that a comment starts with, eg `"//"`.
    ///
    /// - Returns: Nothing.
    static func skipLineComment(_ prefix: String) -> Parser<()> {
        return string(prefix) *> notLineBreak.skipSome
    }
    
    /// Parses a value, skipping and consuming any trailing whitespace.
    ///
    /// - Parameters:
    ///     - p: The parser to wrap.
    ///
    /// - Returns: The parsed value.
    static func lexeme<A>(_ p: Parser<A>) -> Parser<A> {
        return p <* skipWhitespace
    }
    
    /// Parses a string as a symbol lexeme, skipping and consuming any trailing whitespace.
    ///
    /// - Parameters:
    ///     - s: The symbol.
    ///
    /// - Returns: The parsed symbol.
    static func symbol(_ s: String) -> Parser<String> {
        return lexeme(string(s))
    }
    
    /// Parses a value enclosed in parenthesis symbols.
    ///
    /// - Parameters:
    ///     - p: The enclosed parser.
    ///
    /// - Returns: The parsed value.
    static func parens<A>(_ p: Parser<A>) -> Parser<A> {
        return p.between(symbol("("), symbol(")"))
    }
    
    /// Parses a value enclosed in brace symbols.
    ///
    /// - Parameters:
    ///     - p: The enclosed parser.
    ///
    /// - Returns: The parsed value.
    static func braces<A>(_ p: Parser<A>) -> Parser<A> {
        return p.between(symbol("{"), symbol("}"))
    }
    
    /// Parses a value enclosed in angle symbols.
    ///
    /// - Parameters:
    ///     - p: The enclosed parser.
    ///
    /// - Returns: The parsed value.
    static func angles<A>(_ p: Parser<A>) -> Parser<A> {
        return p.between(symbol("<"), symbol(">"))
    }
    
    /// Parses a value enclosed in bracket symbols.
    ///
    /// - Parameters:
    ///     - p: The enclosed parser.
    ///
    /// - Returns: The parsed value.
    static func brackets<A>(_ p: Parser<A>) -> Parser<A> {
        return p.between(symbol("["), symbol("]"))
    }
    
    /// Parses a semicolon symbol.
    ///
    /// - Returns: The parsed semicolon.
    static var semicolon: Parser<String> {
        return symbol(";")
    }
    
    /// Parses a comma symbol.
    ///
    /// - Returns: The parsed comma.
    static var comma: Parser<String> {
        return symbol(",")
    }
    
    /// Parses a colon symbol.
    ///
    /// - Returns: The parsed colon.
    static var colon: Parser<String> {
        return symbol(":")
    }
    
    /// Parses a period symbol.
    ///
    /// - Returns: The parsed semicolon.
    static var dot: Parser<String> {
        return symbol(".")
    }
    
}
