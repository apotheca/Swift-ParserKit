import XCTest
@testable import ParserKit

final class CharacterTests: XCTestCase {
    
    func testAnyChar() throws {
        let p = Parse.anyChar
        XCTAssertThrowsError(try p.parse())
        XCTAssertEqual("a", try p.parse("a"))
        XCTAssertEqual("0", try p.parse("0"))
        XCTAssertEqual("!", try p.parse("!"))
    }
    
    func testChar() throws {
        let p = Parse.char("p")
        XCTAssertEqual("p", try p.parse("p"))
        XCTAssertThrowsError(try p.parse("0"))
        XCTAssertThrowsError(try p.parse("!"))
    }
    
    func testOneOf() throws {
        let xyz = Parse.oneOf("xyz")
        XCTAssertNoThrow(try xyz.many.parse("xxyzzyzxyz"))
        XCTAssertThrowsError(try xyz.many.parse("xxyzzyzaxyz"))
    }
    
    func testNoneOf() throws {
        let notABC = Parse.noneOf("abc")
        XCTAssertNoThrow(try notABC.many.parse("xxyzzyzxyz"))
        XCTAssertThrowsError(try notABC.many.parse("xxyzzyzaxyz"))
    }
    
    func testWhitepace() throws {
        let p = Parse.letter.many(sepBy: Parse.whitespace)
        XCTAssertEqual(["a","b","c"], try p.parse("a b\nc"))
    }
    
    func testInlineSpace() throws {
        let p = Parse.letter.many(sepBy: Parse.inlineSpace)
        XCTAssertEqual(["a","b","c"], try p.parse("a b c"))
        XCTAssertThrowsError(try p.parse("q r\nx"))
    }
    
    func testLineBreak() throws {
        let p = Parse.letter.many(sepBy: Parse.lineBreak)
        XCTAssertEqual(["a","b","c"], try p.parse("a\nb\nc"))
        XCTAssertThrowsError(try p.parse("a b\nc"))
    }
    
    // TODO: Test notWhitespace, notInlineSpace, notLineBreak
    
    func testLower() throws {
        let p = Parse.lower.many
        XCTAssertEqual(["l","o","w","e","r"], try p.parse("lower"))
        XCTAssertThrowsError(try p.parse("UPPER"))
        XCTAssertThrowsError(try p.parse("01234"))
    }
    
    func testUpper() throws {
        let p = Parse.upper.many
        XCTAssertEqual(["U","P","P","E","R"], try p.parse("UPPER"))
        XCTAssertThrowsError(try p.parse("lower"))
        XCTAssertThrowsError(try p.parse("01234"))
    }
    
    func testLetter() throws {
        let p = Parse.letter.many
        XCTAssertEqual(["l","o","w","e","r"], try p.parse("lower"))
        XCTAssertEqual(["U","P","P","E","R"], try p.parse("UPPER"))
        XCTAssertThrowsError(try p.parse("01234"))
    }
    
    func testAlphaNum() throws {
        let p = Parse.alphaNum.many
        XCTAssertEqual(["l","o","w","e","r"], try p.parse("lower"))
        XCTAssertEqual(["U","P","P","E","R"], try p.parse("UPPER"))
        XCTAssertEqual(["0","1","2","3","4"], try p.parse("01234"))
    }
    
    func testDigit() throws {
        let p = Parse.digit.many
        XCTAssertEqual(["0","1","2","3","4"], try p.parse("01234"))
        XCTAssertThrowsError(try p.parse("lower"))
        XCTAssertThrowsError(try p.parse("UPPER"))
    }

    func testOctDigit() throws {
        let p = Parse.octDigit.many
        XCTAssertNoThrow(try p.parse("01234567"))
        XCTAssertThrowsError(try p.parse("0123456789"))
    }

    func testHexDigit() throws {
        let p = Parse.hexDigit.many
        XCTAssertNoThrow(try p.parse("0123456789ABCDEF"))
        XCTAssertThrowsError(try p.parse("0123456789XYZ"))
    }
    
}
