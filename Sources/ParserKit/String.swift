import FunctorKit

public extension Parse {
    
    /// Parses an exact string.
    ///
    /// - Parameters:
    ///     - s: The string to be matched.
    ///
    /// - Returns: A parser that produces the exact string, if it matched.
    static func string(_ s: String) -> Parser<String> {
        switch s {
        case "":
            return .pure("")
        default:
            let p = char(s.first!)
            let ps = string(String(s.dropFirst()))
            return { c in { cs in String(c) + cs } } <^> p <*> ps <?> "string \(s)"
            // Alternatively:
            // return p.map { c in { cs in String(c) + cs } } .ap(ps)
        }
        
    }
    
    /// Parses any of several exact strings.
    ///
    /// - Parameters:
    ///     - s: The array of strings to be matched.
    ///
    /// - Returns: A parser that produces the first string in `s` that matches.
    static func strings(_ s: [String]) -> Parser<String> {
        return choice(s.map(string))
    }
    
}
