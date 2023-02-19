import XCTest
@testable import ParserKit

final class StringTests: XCTestCase {
    
        func testString() throws {
            let p = Parse.string("foo")
            XCTAssertNoThrow(try p.parse("foo"))
            XCTAssertThrowsError(try p.parse("bar"))
            XCTAssertThrowsError(try p.parse("f"))
            XCTAssertThrowsError(try p.parse("fo"))
            XCTAssertThrowsError(try p.parse("fp"))
            XCTAssertThrowsError(try p.parse("fop"))
            XCTAssertThrowsError(try p.parse("foop"))
        }
    
    func testStrings() throws {
        let p = Parse.strings([ "foo", "bar", "qux" ])
        XCTAssertNoThrow(try p.parse("foo"))
        XCTAssertNoThrow(try p.parse("bar"))
        XCTAssertNoThrow(try p.parse("qux"))
        XCTAssertThrowsError(try p.parse("zap"))
    }
    
    
}
