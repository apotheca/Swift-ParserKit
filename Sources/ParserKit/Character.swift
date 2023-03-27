import Foundation
import FunctorKit

public extension Parse {
    
    /// Parses any `Character`. A convenient alias for ``anyToken``, specific to the `Character` token type.
    ///
    /// This parser succeeds for any character.
    ///
    /// ```swift
    /// let a = try! anyChar.parse("a")
    /// ```
    ///
    /// - Returns: The parsed  `Character`.
    /// 
    static var anyChar: Parser<Character> {
        return anyToken
    }
    
    /// Parses a single character `c`.
    ///
    /// This parser succeeds if the next character matches `c`.
    ///
    /// ```swift
    /// let semicolon = try! char(";").parse(";")   // Succeeds
    /// let comma     = try! char(",").parse(";")   // Fails
    /// ```
    ///
    /// See also ``satisfy(_:)``.
    ///
    /// - Parameters:
    ///     - c: The character to match against.
    ///
    /// - Returns: The parsed character (i.e. `c`).
    static func char(_ c: Character) -> Parser<Character> {
        return satisfy { $0 == c } <?> "char \(c)"
    }
    
    /// Parses a single character that is contained in `string`.
    ///
    /// This parser succeeds if the next character is one of the characters in `string`.
    ///
    /// ```swift
    /// let abc = oneOf("abc")
    /// let a = abc.parse("a")   // Succeeds
    /// let b = abc.parse("b")   // Succeeds
    /// let c = abc.parse("c")   // Succeeds
    /// let d = abc.parse("d")   // Fails
    /// ```
    ///
    /// > WARNING: Apple's string mangling results in this function not always producing the expected behavior for certain characters. Notably, `oneOf("\n").parse("\n")` can fail unexpectedly. Use `satisfy { $0.isNewline }` instead.
    ///
    /// > TODO: static func oneOf<C: Collection>(_ collection: C) -> Parser<Character> where C.Element == Character
    ///
    /// See also ``satisfy(_:)``.
    ///
    /// - Parameters:
    ///     - string: The string of characters to match against.
    ///
    /// - Returns: The parsed character.
    static func oneOf(_ string: String) -> Parser<Character> {
        return satisfy { string.contains($0) } <?> "oneOf \(string)"
    }
    
    //static func oneOf<C: Collection>(collection: C) -> Parser<Character> where C.Element == Character {
    //    return satisfy { collection.contains($0) } <?> "oneOf \(Array(collection))"
    //}
    
    /// Parses a single character that is *not* contained in `string`. Dual to ``oneOf(_:)``
    ///
    /// This parser succeeds if the next character is *not* one of the characters in `string`.
    ///
    /// ```swift
    /// let abc = noneOf("abc")
    /// let X = abc.parse("x")   // Succeeds
    /// let y = abc.parse("y")   // Succeeds
    /// let z = abc.parse("z")   // Succeeds
    /// let a = abc.parse("a")   // Fails
    /// ```
    ///
    /// > WARNING: Apple's string mangling results in this function not always producing the expected behavior for certain characters. Notably, `noneOf("\n").parse("\n")` can succeed unexpectedly. Use `satisfy { !$0.isNewline }` instead.
    ///
    /// - Parameters:
    ///     - string: The string of characters to match against.
    ///
    /// - Returns: The parsed character.
    static func noneOf(_ string: String) -> Parser<Character> {
        return satisfy { !string.contains($0) } <?> "noneOf \(string)"
    }
    
    //static var control: Parser<Character> {
    //    fatalError("Unimplemented: \(#function)")
    //}

    /// Parses a single whitespace character. Equivalent to `inlineSpace <|> lineBreak`.
    ///
    /// This parser succeeds if the next character matches any whitespace character.
    ///
    /// ```swift
    /// let space   = try! whitespace.parse(" ")    // Succeeds
    /// let tab     = try! whitespace.parse("\t")   // Succeeds
    /// let newline = try! whitespace.parse("\n")   // Succeeds
    /// let a       = try! whitespace.parse("a")    // Fails
    /// ```
    ///
    /// - Returns: The parsed whitespace character.
    static var whitespace: Parser<Character> {
        return satisfy { $0.isWhitespace } <?> "whitespace"
    }
    
    /// Parses a single *inline* whitespace character.
    ///
    /// This parser succeeds if the next character matches any *inline* whitespace character.
    ///
    /// ```swift
    /// let space   = try! inlineSpace.parse(" ")    // Succeeds
    /// let tab     = try! inlineSpace.parse("\t")   // Succeeds
    /// let newline = try! inlineSpace.parse("\n")   // Fails
    /// ```
    ///
    /// - Returns: The parsed inline whitespace character.
    static var inlineSpace: Parser<Character> {
        return satisfy { $0.isWhitespace && !$0.isNewline } <?> "inlineSpace"
    }
    
    /// Parses a single *linebreak* whitespace character.
    ///
    /// This parser succeeds if the next character matches any *linebreak* whitespace character.
    ///
    /// ```swift
    /// let space   = try! lineBreak.parse(" ")    // Fails
    /// let tab     = try! lineBreak.parse("\t")   // Fails
    /// let newline = try! lineBreak.parse("\n")   // Succeeds
    /// ```
    ///
    /// - Returns: The parsed linebreak whitespace character.
    static var lineBreak: Parser<Character> {
        return satisfy { $0.isNewline } <?> "lineBreak"
    }
    
    /// Parses a single non-whitespace character. Dual to ``whitespace``
    ///
    /// This parser succeeds if the next character *does not* match any whitespace character.
    ///
    /// ```swift
    /// let space   = try! notWhitespace.parse(" ")    // Fails
    /// let tab     = try! notWhitespace.parse("\t")   // Fails
    /// let newline = try! notWhitespace.parse("\n")   // Fails
    /// let a       = try! notWhitespace.parse("a")    // Succeeds
    /// ```
    ///
    /// - Returns: The parsed non-whitespace character.
    static var notWhitespace: Parser<Character> {
        return satisfy { !$0.isWhitespace } <?> "whitespace"
    }
    
    /// Parses a single non- inline whitespace character. Dual to ``inlineSpace``.
    ///
    /// This parser succeeds if the next character *does not* match any inline whitespace character.
    ///
    /// ```swift
    /// let space   = try! notInlineSpace.parse(" ")    // Fails
    /// let tab     = try! notInlineSpace.parse("\t")   // Fails
    /// let newline = try! notInlineSpace.parse("\n")   // Succeeds
    /// let a       = try! notInlineSpace.parse("a")    // Succeeds
    /// ```
    ///
    /// - Returns: The parsed non- inline whitespace character.
    static var notInlineSpace: Parser<Character> {
        return satisfy { !$0.isWhitespace || $0.isNewline } <?> "inlineSpace"
    }
    
    /// Parses a single non- linebreak character. Dual to ``lineBreak``
    ///
    /// This parser succeeds if the next character *does not* match any linebreak character.
    ///
    /// ```swift
    /// let space   = try! notLineBreak.parse(" ")    // Succeeds
    /// let tab     = try! notLineBreak.parse("\t")   // Succeeds
    /// let newline = try! notLineBreak.parse("\n")   // Fails
    /// let a       = try! notLineBreak.parse("a")    // Succeeds
    /// ```
    ///
    /// - Returns: The parsed non- linebreak character.
    static var notLineBreak: Parser<Character> {
        return satisfy { !$0.isNewline } <?> "lineBreak"
    }
    
    /// Parses a single lowercase character.
    ///
    /// This parser succeeds if the next character matches any lowercase character.
    ///
    /// ```swift
    /// let a    = try! lower.parse("a")    // Succeeds
    /// let b    = try! lower.parse("B")    // Fails
    /// let zero = try! lower.parse("0")    // Fails
    /// let mark = try! lower.parse("!")    // Fails
    /// ```
    ///
    /// - Returns: The parsed lowercase character.
    static var lower: Parser<Character> {
        return oneOf("abcdefghijklmnopqrstuvwxyz") <?> "lower"
    }
    
    /// Parses a single uppercase character.
    ///
    /// This parser succeeds if the next character matches any uppercase character.
    ///
    /// ```swift
    /// let a    = try! upper.parse("a")    // Fails
    /// let b    = try! upper.parse("B")    // Succeeds
    /// let zero = try! upper.parse("0")    // Fails
    /// let mark = try! upper.parse("!")    // Fails
    /// ```
    ///
    /// - Returns: The parsed uppercase character.
    static var upper: Parser<Character> {
        return oneOf("ABCDEFGHIJKLMNOPQRSTUVWXYZ") <?> "upper"
    }
    
    /// Parses a single letter character. Equivalent to `lower <|> upper`.
    ///
    /// This parser succeeds if the next character matches any letter character.
    ///
    /// ```swift
    /// let a    = try! letter.parse("a")    // Succeeds
    /// let b    = try! letter.parse("B")    // Succeeds
    /// let zero = try! letter.parse("0")    // Fails
    /// let mark = try! letter.parse("!")    // Fails
    /// ```
    ///
    /// - Returns: The parsed letter character.
    static var letter: Parser<Character> {
        return lower <|> upper <?> "letter"
    }
    
    /// Parses a single alphanumeric character. Equivalent to `letter <|> digit`.
    ///
    /// This parser succeeds if the next character matches any alphanumeric character.
    ///
    /// ```swift
    /// let a    = try! alphaNum.parse("a")    // Succeeds
    /// let b    = try! alphaNum.parse("B")    // Succeeds
    /// let zero = try! alphaNum.parse("0")    // Succeeds
    /// let mark = try! alphaNum.parse("!")    // Fails
    /// ```
    ///
    /// - Returns: The parsed alphanumeric character.
    static var alphaNum: Parser<Character> {
        return letter <|> digit <?> "alphaNum"
    }

    //printable :: Parser Char
    //printable = satisfy isPrint
    
    /// Parses a single decimal digit character (a character between '0' and '9').
    ///
    /// This parser succeeds if the next character matches any decimal digit character.
    ///
    /// ```swift
    /// let a    = try! digit.parse("a")    // Fails
    /// let b    = try! digit.parse("B")    // Fails
    /// let zero = try! digit.parse("0")    // Succeeds
    /// let mark = try! digit.parse("!")    // Fails
    /// ```
    ///
    /// - Returns: The parsed decimal digit character.
    static var digit: Parser<Character> {
        return oneOf("0123456789") <?> "digit"
    }
    
    /// Parses a single octal digit character (a character between '0' and '7').
    ///
    /// This parser succeeds if the next character matches any octal digit character.
    ///
    /// ```swift
    /// let zero  = try! octDigit.parse("0")    // Succeeds
    /// let eight = try! octDigit.parse("8")    // Fails
    /// let f     = try! octDigit.parse("F")    // Fails
    /// ```
    ///
    /// - Returns: The parsed octal digit character.
    static var octDigit: Parser<Character> {
        return oneOf("01234567") <?> "octDigit"
    }
    
//    static var hexDigitLower: Parser<Character> {
//        return oneOf("0123456789abcdef") <?> "hexDigitLower"
//    }
//
//    static var hexDigitUpper: Parser<Character> {
//        return oneOf("0123456789ABCDEF") <?> "hexDigitUpper"
//    }

    /// Parses a single hex digit character  (a character between '0' and '9' or 'a' and 'f' or 'A' and 'F').
    ///
    /// This parser succeeds if the next character matches any hex digit character.
    ///
    /// ```swift
    /// let zero  = try! hexDigit.parse("0")    // Succeeds
    /// let eight = try! hexDigit.parse("8")    // Succeeds
    /// let f     = try! hexDigit.parse("F")    // Succeeds
    /// let g     = try! hexDigit.parse("G")    // Fails
    /// ```
    ///
    /// - Returns: The parsed hex digit character.
    static var hexDigit: Parser<Character> {
        return oneOf("0123456789ABCDEFabcdef") <?> "hexDigit"
    }

}
