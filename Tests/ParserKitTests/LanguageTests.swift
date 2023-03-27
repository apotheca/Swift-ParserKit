import XCTest
import FunctorKit
@testable import ParserKit

final class LanguageTests: XCTestCase {
    
    func testSkipWhitespace() throws {
        let p = Parse.string("a") <* Parse.skipWhitespace
        XCTAssertNoThrow(try p.parse("a"))
        XCTAssertNoThrow(try p.parse("a "))
        XCTAssertNoThrow(try p.parse("a \t"))
        XCTAssertNoThrow(try p.parse("a \t\n"))
    }
    
    func testSkipInlineSpace() throws {
        let p = Parse.string("a") <* Parse.skipInlineSpace
        XCTAssertNoThrow(try p.parse("a"))
        XCTAssertNoThrow(try p.parse("a "))
        XCTAssertNoThrow(try p.parse("a \t"))
        XCTAssertThrowsError(try p.parse("a \t\n"))
    }
    
    func testSkipLineComment() throws {
        let p = Parse.string("a") <* Parse.skipInlineSpace <* Parse.skipLineComment("//")
        XCTAssertEqual("a", try p.parse("a // This is a comment"))
    }
    
    func testLexeme() throws {
        let p = Parse.lexeme(Parse.string("a"))
        XCTAssertNoThrow(try p.parse("a"))
        XCTAssertNoThrow(try p.parse("a "))
        XCTAssertNoThrow(try p.parse("a \t"))
        XCTAssertNoThrow(try p.parse("a \t\n"))
    }
    
    func testSymbol() throws {
        let p = Parse.symbol("a")
        XCTAssertNoThrow(try p.parse("a"))
        XCTAssertNoThrow(try p.parse("a "))
        XCTAssertNoThrow(try p.parse("a \t"))
        XCTAssertNoThrow(try p.parse("a \t\n"))
    }
    
    func testParens() throws {
        let p = Parse.parens(Parse.symbol("a"))
        XCTAssertNoThrow(try p.parse("(a)"))
        XCTAssertNoThrow(try p.parse("( a )"))
        XCTAssertNoThrow(try p.parse("(  a  )  "))
    }
    
    func testBraces() throws {
        let p = Parse.braces(Parse.symbol("a"))
        XCTAssertNoThrow(try p.parse("{a}"))
        XCTAssertNoThrow(try p.parse("{ a }"))
        XCTAssertNoThrow(try p.parse("{  a  }  "))
    }
    
    func testAngles() throws {
        let p = Parse.angles(Parse.symbol("a"))
        XCTAssertNoThrow(try p.parse("<a>"))
        XCTAssertNoThrow(try p.parse("< a >"))
        XCTAssertNoThrow(try p.parse("<  a  >  "))
    }
    
    func testBrackets() throws {
        let p = Parse.brackets(Parse.symbol("a"))
        XCTAssertNoThrow(try p.parse("[a]"))
        XCTAssertNoThrow(try p.parse("[ a ]"))
        XCTAssertNoThrow(try p.parse("[  a  ]  "))
    }
    
    func testSemicolon() throws {
        let p = Parse.semicolon
        XCTAssertEqual(";", try p.parse(";"))
        XCTAssertEqual(";", try p.parse("; "))
        XCTAssertEqual(";", try p.parse(";  "))
    }
    
    func testComma() throws {
        let p = Parse.comma
        XCTAssertEqual(",", try p.parse(","))
        XCTAssertEqual(",", try p.parse(", "))
        XCTAssertEqual(",", try p.parse(",  "))
    }
    
    func testColon() throws {
        let p = Parse.colon
        XCTAssertEqual(":", try p.parse(":"))
        XCTAssertEqual(":", try p.parse(": "))
        XCTAssertEqual(":", try p.parse(":  "))
    }
    
    func testDot() throws {
        let p = Parse.dot
        XCTAssertEqual(".", try p.parse("."))
        XCTAssertEqual(".", try p.parse(". "))
        XCTAssertEqual(".", try p.parse(".  "))
    }
    
}
