import XCTest
@testable import ParserKit

final class PrimitiveTests: XCTestCase {
    
    func testPeekToken() throws {
        
        XCTAssertThrowsError(try Parse.peekToken.parse())
        
        let input = "abc"
        let p = Parse.peekToken
        switch p.runParser((.zero,input)) {
        case let .failure(e):
            XCTFail("Failed to parse: \(e)")
        case let .success((peek, (_,remainingInput))):
            XCTAssertEqual(peek, input.first!)
            XCTAssertEqual(input, remainingInput)
        }
    }

    func testAnyToken() throws {
        
        let p = Parse.anyToken
        
        XCTAssertEqual("a", try p.parse("a"))
        XCTAssertEqual("b", try p.parse("b"))
        XCTAssertEqual("c", try p.parse("c"))
        
        XCTAssertEqual(["a","b","c"], try p.many.parse("abc"))
        
    }

    func testSatisfy() throws {
        
        let p = Parse.satisfy { x in x == "a" || x == "b" || x == "c" }
        
        XCTAssertNoThrow(try p.parse("a"))
        XCTAssertNoThrow(try p.parse("b"))
        XCTAssertNoThrow(try p.parse("c"))
        
        XCTAssertThrowsError(try p.parse("z"))
        
    }

    func testEof() throws {
        let p = Parser(5) <* Parse.eof
        XCTAssertNoThrow(try p.parse())
    }

    func testSkip() throws {
        let p = Parse.string("foo").skip
        // XCTAssertEqual((), p.parse("foo"))
        XCTAssertTrue(try () == p.parse("foo"))
    }
    
    // TODO:
    func testSkipMany() throws {
        let p = Parse.string("foo").skipMany
        XCTAssertTrue(try () == p.parse(""))
        XCTAssertTrue(try () == p.parse("foo"))
        XCTAssertTrue(try () == p.parse("foofoofoo"))
    }
    
    // TODO:
    func testSkipSome() throws {
        let p = Parse.string("foo").skipSome
        XCTAssertThrowsError(try p.parse(""))
        XCTAssertTrue(try () == p.parse("foo"))
        XCTAssertTrue(try () == p.parse("foofoofoo"))
    }
    
    // TODO:
    func testSkipRemainingInput() throws {
        let p = Parse.string("foo").skipRemainingInput
        XCTAssertEqual("foo", try p.parse("foo"))
        XCTAssertEqual("foo", try p.parse("fooblargh"))
    }
    
}
