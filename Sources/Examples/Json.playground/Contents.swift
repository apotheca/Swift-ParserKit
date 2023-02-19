import Foundation
import ParserKit

indirect enum Json {
    
    case object([String:Json])
    case array([Json])
    case string(String)
    case number(Decimal)
    case bool(Bool)
    case null
    
}

extension Json: CustomStringConvertible {
    
    var description: String {
        switch self {
        case let .object(xs):
            let pairs = xs.map { k, v in Json.escape(k) + ": " + v.description }
            return "{ " + pairs.joined(separator: ", ") + " }"
        case let .array(xs):
            return "[ " + xs.map { $0.description } .joined(separator: ", ") + " ]"
        case let .string(s):
            return Json.escape(s)
        case let .number(d):
            return "\(d)"
        case let .bool(b):
            return "\(b)"
        case .null:
            return "null"
        }
    }
    
}

extension Json: CustomDebugStringConvertible {
    
    var debugDescription: String {
        switch self {
        case let .object(d):
            return "object(\(d.debugDescription))"
        case let .array(a):
            return "array(\(a.debugDescription))"
        case let .string(s):
            return "string(\(s.debugDescription))"
        case let .number(n):
            return "number(\(n))"
        case let .bool(b):
            return "bool(\(b))"
        case .null:
            return "null"
        }
    }
    
}

extension Json {
    
    static func escape(_ string: String) -> String {
        return "\"" + string.map(escape).joined() + "\""
    }

    static func escape(_ char: Character) -> String {
        switch char {
        case "\\":      return "\\\\"
        case "\"":      return "\\\""
        case "\n":      return "\\n"
        case "\t":      return "\\t"
        case "\u{C}":   return "\\f"
        case "\u{8}":   return "\\b"
        case "\r":      return "\\r"
        default:        return String(char)
        }
    }

    static func unescape(_ c: Character) -> Character {
        switch c {
        case "n": return "\n"
        case "t": return "\t"
        case "f": return "\u{C}"
        case "b": return "\u{8}"
        case "r": return "\r"
        default:  return c
        }
    }

}

extension Parse {

    static func jsonNull() -> Parser<Json> {
        return symbol("null") ^> .null
    }

    static func jsonBool() -> Parser<Json> {
        return  symbol("true")  ^> .bool(true)
            <|> symbol("false") ^> .bool(false)
    }

    static func jsonNumber() -> Parser<Json> {
        return lexeme(jsonScientific).map { .number($0) }
    }

    static var jsonScientific: Parser<Decimal> {
        let sign = "+" <|> "-" <|> ""
        let digits = digit.some
        let signedDigits = { s in { ns in s + ns } } <^> sign <*> digits
        let real = signedDigits
        let frac = { e in { fs in e + fs } } <^> "." <*> digits <|> ""
        let exp = { e in { fs in e + fs } } <^> "e" <*> signedDigits <|> ""
        return { r in { f in { e in Decimal(string: r + f + e)! } } } <^> real <*> frac <*> exp
    }

    static func jsonString() -> Parser<Json> {
        return lexeme(jsonEscapedString).map { .string($0) }
    }

    static var jsonEscapedString: Parser<String> {
        return jsonEscapedChar.many
            .between("\"", "\"")
            .map { String($0) }
    }

    static var jsonEscapedChar: Parser<Character> {
        return notJsonEscapable <|> "\\" *> (jsonUnicode <|> jsonEscapable)
    }

    static var notJsonEscapable: Parser<Character> {
        return satisfy { !$0.isNewline && !"\\\"\n\t\u{C}\u{8}\r".contains($0) }
    }

    static var jsonEscapable: Parser<Character> {
        return oneOf("\\/\"ntfbr").map { Json.unescape($0) }
    }

    static var jsonUnicode: Parser<Character> {
        return "u" *> hexDigit.count(4) >>- { hexChars in
            if hexChars.isEmpty {
                return .failure("empty unicode escape")
            } else {
                if let code = Int(String(hexChars), radix: 16), let c = UnicodeScalar(code) {
                    return .pure(Character(c))
                } else {
                    return .failure("bad unicode escape")
                }
            }
        }
    }

    static func jsonArray(_ rec: Parser<Json>) -> Parser<Json> {
        return brackets(rec.many(sepBy: symbol(","))).map { .array($0) }
    }
    
    static func jsonObject(_ rec: Parser<Json>) -> Parser<Json> {
        return braces(jsonAssoc(rec).many(sepBy: symbol(",")))
            .map { .object(Dictionary($0) { l, r in r }) }
    }

    static func jsonAssoc(_ rec: Parser<Json>) -> Parser<(String,Json)> {
        return lexeme(jsonEscapedString) >>- { k in symbol(":") *> rec.map { v in (k,v) } }
    }

    static var json: Parser<Json> {
        return fix { rec in
            return  jsonObject(rec)
                <|> jsonArray(rec)
                <|> jsonString()
                <|> jsonNumber()
                <|> jsonBool()
                <|> jsonNull()
        }
    }
    
}

let json = try! Parse.json.parse("""
{
    "foo" : [ "bar", 0.035e6, true, null ]
}
""")
print(json)
// Prints:
// { "foo": [ "bar", 35000, true, null ] }
print(json.debugDescription)
// Prints:
// object(["foo": array([string(bar), number(35000), bool(true), null])])

print("Done")
