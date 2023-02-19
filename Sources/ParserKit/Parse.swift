// NOTE: This enum is for convenience, and to avoid explicitly requiring 'Parser<T>.xxx' everywhere.

/// A namespace for parsers.
///
/// We could put these functions in extensions to ``Parser`` but then they require annotating the parser generic type at the use site, as Swift often fails to properly infer it. Alternatively, we could put that in the global namespace, but we have opted to avoid polluting it, with this strategy instead.
///
/// It is suggested that parsers be written as an extension to ``Parse``, in order to reduce boilerplace.
///
/// Consider:
///
/// ```swift
/// // (a,b)
/// let foo = Parse.char("a")
///     .sep(Parse.char("b"), by: Parse.inlineSpace)
///     .between(Parse.char("("),Parse.char("("))
/// ```
///
/// Compare it to:
///
/// ```swift
/// // Also (a,b)
/// extension Parse {
///      static let foo = char("a")
///         .sep(char("b"), by: inlineSpace)
///         .between(char("("),char("("))
/// }
/// ```
///
/// With complicated parsers, this removes an enormous amount of `Parse.`
public enum Parse {
    
    /// A convenient alias for ``Parser/fix(_:)``
    public static func fix<T>(_ fn: @escaping (Parser<T>) -> Parser<T>) -> Parser<T> {
        return Parser<T>.fix(fn)
    }
    
    /// A convenient alias for ``Parser/pure(_:)``
    public static func pure<T>(_ val: T) -> Parser<T> {
        return Parser<T>.pure(val)
    }
    
    /// An convenient alias for ``Parser/empty``
    public static func empty<T>() -> Parser<T> {
        return Parser<T>.empty
    }
    
    /// A convenient alias for ``Parser/fail(_:)``
    public static func fail<T>(_ error: ParserError) -> Parser<T> {
        return Parser<T>.fail(error)
    }
    
    /// A convenient alias for ``Parser/endOfInput()``
    public static func endOfInput<T>() -> Parser<T> {
        return Parser<T>.endOfInput()
    }
    
    /// A convenient alias for ``Parser/inputRemaining(_:)``
    public static func inputRemaining<T>(_ input: String) -> Parser<T> {
        return Parser<T>.inputRemaining(input)
    }
    
    /// A convenient alias for ``Parser/unexpected(_:)``
    public static func unexpected<T>(_ input: String) -> Parser<T> {
        return Parser<T>.unexpected(input)
    }
    
    /// A convenient alias for ``Parser/expected(_:)``
    public static func expected<T>(_ label: String) -> Parser<T> {
        return Parser<T>.expected(label)
    }
    
    /// A convenient alias for ``Parser/failure(_:)``
    public static func failure<T>(_ reason: String) -> Parser<T> {
        return Parser<T>.failure(reason)
    }
    
}
