# Writing a JSON parser

Create a parser for reading JSON (**J**ava**S**cript **O**bject **N**otation) files.

## Overview

JSON is the de-facto internet standard file format for data storage and exchange across APIs, often used for sending data to and from mobile applications and web pages. It is intended to be a lightweight format that is self-descriptive and easy to understand.

A JSON value is either: a primitive null, boolean, number, or string; an array of values; or a dictionary of key-value pairs, where the keys are strings.

Compared to simple CSV tables, JSON data is a little more complicated - it is recursive, has many different cases, and may fail to parse if the input has incorrect syntax. Despite this additional complexity, the JSON syntax specification is still small enough to print on a business card.

![A specification of the JSON grammar printed on a business card.](json_business_card)

In Swift, we can use `Codable` to automatically convert Swift data to JSON strings and back, using `JSONEncoder`, and `JSONDecoder`. There is, however, a distinct lack of ability to capture and inspect or modify the intermediate JSON structure, and we are limited to acting upon JSON only in the form of contiguous blobs of JSON-encoded strings. 

> NOTE: To get around this, it is fairly common to decode the JSON-encoded string back into `[String:Any]`, `[Any]`, or `Any` using `JSONDecoder`, effectively using `Codable` for reflection. There are more than a few open-source implementations of vaguely equivalent `DictionaryEncoder` classes that do exactly this. The end result allows us to somewhat tediously traverse the JSON data structure. However, these solutions are dissatisfying, as working with the `Any` type is awkward, requires a lot of casting, and doesn't benefit from any of Swift's strongly-typed functional architecture.

Here, we will build a parser for a strongly-typed `Json` enum that allows for case analysis.

Because JSON has whitespace that may be ignored, for this parser we will use some of the more advanced functions, such as ``Parse/lexeme(_:)`` and ``Parse/symbol(_:)``, which consume trailing whitespace automatically.

For convenience, we will write our parsers as an extension to the ``Parse`` namespace.

```swift
extension Parse {
    // Our parsers go here
}
```

## Our JSON data type

Our specification of the JSON data type is quite simple.

```swift
indirect enum Json {
    
    case object([String:Json])
    case array([Json])
    case string(String)
    case number(Decimal)
    case bool(Bool)
    case null

}
```

We also have some convenience functions that perform the necessary magick for escaping and unescaping json strings and characters. Without getting too much into it, JSON strings are enclosed in double quotes `"`, and so they require double quotes and a few other characters to be escaped (prefixed with a backslash `\`) and unescaped. These functions aren't just used in the parser, so we'll make them part of the `Json` type.

```swift
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
```

We'll also provide some convenient protocol implementations for printing out our JSON values.

We'll use `CustomStringConvertible` to encode our `Json` data back into a JSON string.

```swift
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
```

> WARNING: This function does not escape extended UTF8 characters.

For debugging, we will use `CustomStringConvertible` to print our `Json` data as a Swift source code string.

```swift
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
```

Now that we have our data type and boilerplate out of the way, its time to build some parsers.

## The Null parser

We'll start at the bottom, with the `null` parser.

```swift
static func jsonNull() -> Parser<Json> {
    return symbol("null") ^> .null
}
```

This parser is trivial, as we simply need match the `null` keyword using ``Parse/symbol(_:)``, which both matches the provided string, as well as consuming any trailing whitespace. However, that returns the string `"null"` rather than `Json.null`, and so we use ``^>`` to replace the returned value.

> NOTE: `p ^> v` is equivalent to `p *> pure(v)`

## The Bool parser

Next up is the `bool` parser.

```swift
static func jsonBool() -> Parser<Json> {
    return  symbol("true")  ^> .bool(true)
        <|> symbol("false") ^> .bool(false)
}
```

This parser is slightly more complex than null - here we have two cases to deal with, `true` and `false`. We do the same thing as before, matching on a keyword symbol and replacing the matched string with the proper value. Because we have two potential parse cases, `true` and `false`, we use ``<|>`` (aka the ``Parser/alt(_:)`` parser) to combine them and automatically try the second parser if the first one fails.

## The Number parser

Now we get to some of the more complicated aspects of JSON - parsing a number.

```swift
static func jsonNumber() -> Parser<Json> {
    return lexeme(jsonScientific).map { .number($0) }
}
```

> NOTE: Here we used ``Parse/lexeme(_:)`` instead of ``Parse/symbol(_:)``, because `symbol` takes a string, whereas `lexeme` takes any parser. This is because `symbol(s)` = lexeme(string(s)).

We're going to cheat slightly, and rely on `Foundation` to handle converting the string number to a `Decimal`, but we're still going to need to parse it first.

```swift
static var jsonScientific: Parser<Decimal> {
    let sign = "+" <|> "-" <|> ""
    let digits = digit.some
    let signedDigits = { s in { ns in s + ns } } <^> sign <*> digits
    let real = signedDigits
    let frac = { e in { fs in e + fs } } <^> "." <*> digits <|> ""
    let exp = { e in { fs in e + fs } } <^> "e" <*> signedDigits <|> ""
    return { r in { f in { e in Decimal(string: r + f + e)! } } } <^> real <*> frac <*> exp
}
```

This needs a little bit of explaining. 

A number in JSON can be expressed as an integer `123`, as a floating point with a decimal `123.0`, or as a scientific number `12.3e2`. It may have a positive sign `+3` or negative sign `-1`. This means that it comes in three parts - the `real`, the `fractional`, and the `exponential`, where the `real` is required, and the `fractional` and `exponential` are optional.

First, we construct some primitive parsers.

A `sign` may be `+`, `-`, or nothing.

```swift
let sign = "+" <|> "-" <|> ""
```

A `digits` is just some sequence of digits.

```swift
let digits = digit.some
```

A `signedDigits` combines `sign` and `digits`.

```swift
let signedDigits = { s in { ns in s + ns } } <^> sign <*> digits
```

Then, we parse our real, fractional, and exponential parts.

The `real` portion consists of some signed digits.

```swift
let real = signedDigits
```

The `fraction` portion consists of either a dot `.` followed by some digits, or nothing. If there is no fractional part, it consumes no input and returns an empty string.

```swift
let frac = { d in { ds in d + ds } } <^> "." <*> digits <|> ""
```

The `exponent` portion consists of either an `e` followed by some signed digits (as we might have a negative exponent), or nothing. If there is no exponentional part, it consumes no input and returns an empty string.

```swift
let exp = { e in { fs in e + fs } } <^> "e" <*> signedDigits <|> ""
```

Once we have parsers for all of our parts, we combine them and return a parser that joins them into a single string, converting it to a `Decimal`. Note that we use `!` to force the optional, since we have just used the parser to prove that it is a well-formatted number.

```swift
return { r in { f in { e in Decimal(string: r + f + e)! } } } <^> real <*> frac <*> exp
```

<!-- TODO: Maybe discuss using `curry` and `curry3` instead of nested functions -->

## The String parser

Next up, we have the string parser.

```swift
static func jsonString() -> Parser<Json> {
    return lexeme(jsonEscapedString).map { .string($0) }
}
```

A JSON string is many escaped json characters, enclosed in double quotes `"`.

```swift
static var jsonEscapedString: Parser<String> {
    return jsonEscapedChar.many
        .between("\"", "\"")
        .map { String($0) }
}
```

An escaped JSON character is either a plain (not-escapable) character, else an escaping backslash `\` followed by a JSON unicode sequence or JSON escapable character.

```swift
static var jsonEscapedChar: Parser<Character> {
    return notJsonEscapable <|> "\\" *> (jsonUnicode <|> jsonEscapable)
}
```

Most characters don't need to be escaped, so its easier to specify which ones they aren't. We need to escape backslashes `\`, double quotes `"`, carriage returns `\r`, `newlines `\n`, tabs `\t, backspaces `\b`, and form feeds `\f`, so if the character isn't any one of those, it doesn't need to be escaped.

```swift
static var notJsonEscapable: Parser<Character> {
    return satisfy { !$0.isNewline && !"\\\"\n\t\u{C}\u{8}\r".contains($0) }
}
```

When we do encounter an escaped character during parsing, we unescape it to get back the original character.

```swift
static var jsonEscapable: Parser<Character> {
    return oneOf("\\/\"ntfbr").map { Json.unescape($0) }
}
```

Finally, when we encounter an escaped unicode sequence, we parse it as a single character `u` followed by four hex digit characters. We then turn those four characters into a `String`, then an `Int`, then a `UnicodeScalar`, and finally a `Character`.

```swift
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
```

That's it, we're done with strings. At last, we have finished our primitive element parsers. Now, we move on to the recursive parsers. Compared to the number and string parsers, they are only a few lines each.

## The Array parser

A JSON array is an opening bracket `[`, followed by a sequence of zero or more JSON values separated by commas `,`, ending with a closing bracket `]`. We use ``Parse/brackets(_:)``, which is equivalent to `symbol("[") *> x <* symbol("]")`.

```swift
static func jsonArray(_ rec: Parser<Json>) -> Parser<Json> {
    return brackets(rec.many(sepBy: symbol(","))).map { .array($0) }
}
```

Because Swift is a strictly-evaluating language, we make the recursion explicit, and pass in the recurring parser as an argument. If we tried to make two parsers mutually recursive, the strictness will cause it to attempt to evaluate an infinite loop. Explicit recursion helps solve this.

> NOTE: This explicit recursion is useful when parsing recursive objects using base functors, which turn recursion points into generics where `Json <==> JsonF<Json>`. In this case, the declaration type would change to `func jsonArray<T>(_ rec: Parser<T>) -> Parser<JsonF<T>>`  but the function would otherwise be unchanged.

## The Object parser

A JSON object is an opening brace `{`, followed by a sequence of zero or more JSON key-value pairs separated by commas `,`, ending with a closing brace `}`. We use ``Parse/braces(_:)``, which is equivalent to `symbol("{") *> x <* symbol("}")`.

```swift
static func jsonObject(_ rec: Parser<Json>) -> Parser<Json> {
    return braces(jsonAssoc(rec).many(sepBy: symbol(",")))
        .map { .object(Dictionary($0) { l, r in r }) }
}
```

> NOTE: In the case of duplicate keys, we override the earlier ones using the later ones.

A JSON key-value pair is a JSON string key, followed by a colon `:`, and a JSON value, where we put them together into a tuple pair.

```swift
static func jsonAssoc(_ rec: Parser<Json>) -> Parser<(String,Json)> {
    return lexeme(jsonEscapedString) >>- { k in symbol(":") *> rec.map { v in (k,v) } }
}
```

We also use explicit recursion here, and pass it through `jsonObject` and `jsonAssoc`.

That's the end of all of the component parsers.

## The JSON parser

To finish it all up, we now need to build the final JSON parser out of all of the individual cases.

We could try to define it recursively:

```swift
static var json: Parser<Json> {
    return  jsonObject(json)
        <|> jsonArray(json)
        <|> jsonString()
        <|> jsonNumber()
        <|> jsonBool()
        <|> jsonNull()
}
```

The problem is, we need to pass the parser to itself, and doing this causes a bunch of errors.

- Attempting to access 'json' within its own getter
- Function call causes an infinite recursion

We can try to get rid of the explicit recursion entirely:

```swift
static func jsonArray() -> Parser<Json> {
    return brackets(json.many(sepBy: symbol(","))).map { .array($0) }
}

static func jsonObject() -> Parser<Json> {
    return braces(jsonAssoc().many(sepBy: symbol(",")))
        .map { .object(Dictionary($0) { l, r in r }) }
}

static func jsonAssoc() -> Parser<(String,Json)> {
    return lexeme(jsonEscapedString) >>- { k in symbol(":") *> json.map { v in (k,v) } }
}

static var json: Parser<Json> {
    return  jsonObject()
        <|> jsonArray()
        <|> jsonString()
        <|> jsonNumber()
        <|> jsonBool()
        <|> jsonNull()
}
```

It now compiles, but it will loop indefinitely if you attempt to parse any values with it.

Instead, we will use ``Parser/fix(_:)``, which feeds a parser to itself as its own argument lazily, without looping forever. This is why were using explicit recursion earlier.

```swift
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
```

That's it. Our JSON parser is done.

## Our final code

Let's take a look at all of our code put together.

```swift
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
        return notEscapable <|> "\\" *> (jsonUnicode <|> escapable)
    }

    static var notEscapable: Parser<Character> {
        return satisfy { !$0.isNewline && !"\\\"\n\t\u{C}\u{8}\r".contains($0) }
    }

    static var escapable: Parser<Character> {
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
```

That's quite a bit more code than our CSV parser, but at the same time, most of it is support for the Json type, and the actual parsing happens in under a hundred lines of code.

## Testing it out

Let's test it out.

```swift
let json = try! Parse.json.parse("""
{
    "foo" : [ "bar", 0.035e6, true, null ]
}
""")
```

As you can see, if we print out the result, we have successfully parsed the JSON "file" into a strongly-typed `JSON` object:

```swift
print(json)
// Prints:
// { "foo": [ "bar", 35000, true, null ] }
print(json.debugDescription)
// Prints:
// object(["foo": array([string(bar), number(35000), bool(true), null])])
```

## Conclusion

This was a significant amount of work, but in the end we've implemented a parser for one of the most common data formats on the planet.
