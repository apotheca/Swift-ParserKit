import XCTest
import FunctorKit
@testable import ParserKit

final class CombinatorTests: XCTestCase {
    
    func testChoice() throws {
        
        let a = Parse.char("a")
        let b = Parse.char("b")
        let c = Parse.char("c")

        let p = Parse.choice([ a, b, c ]).many
        
        let abc = try p.parse("abc")
        let cba = try p.parse("cba")
        
        let p2 = (a <|> b <|> c).many
        XCTAssertEqual(abc, try p2.parse("abc"))
        XCTAssertEqual(cba, try p2.parse("cba"))
        
        let p3 = (.empty <|> Parse.char("x"))
        let x = try p3.parse("x")
        XCTAssertEqual(x, "x")
        
    }
    
    func testCount() throws {
        
        let p = Parse.char("a").count(3)
        
        XCTAssertThrowsError(try p.parse())
        XCTAssertThrowsError(try p.parse("a"))
        XCTAssertThrowsError(try p.parse("aa"))
        
        let a3 = try p.parse("aaa")
        XCTAssertEqual(a3, ["a", "a", "a"])
        
        XCTAssertThrowsError(try p.parse("aaaa"))
        XCTAssertNoThrow(try p.skipRemainingInput.parse("aaaa"))
    }
    
    func testOption() throws {
        let p = Parse.char("a").option("_")
        XCTAssertEqual("_", try p.parse())
        XCTAssertEqual("a", try p.parse("a"))
        XCTAssertEqual("_", try p.skipRemainingInput.parse("b"))
    }
    
    func testBetween() throws {
        
        let p = Parse.char("a").between(Parse.char("("),Parse.char(")"))
        XCTAssertEqual("a", try p.parse("(a)"))

    }
    
    func testSurround() throws {
        let p = Parse.char("a").surround(Parse.char("|"))
        XCTAssertEqual("a", try p.parse("|a|"))
    }
    
    func testChain() throws {
        let min = Parser({ (x: Character) in { (y: Character) in if x < y { return x } else { return y } }})
        let p = Parse.digit.chain(min)
        XCTAssertThrowsError(try p.parse())
        XCTAssertEqual("2", try p.parse("3924576"))
        let p2 = Parse.digit.chain(min, else:"!")
        XCTAssertEqual("!", try p2.parse())
        XCTAssertEqual("2", try p2.parse("3924576"))
        
    }
    
    func testSep() throws {
        let p = Parse.char("a").sep(Parse.char("b"), by: Parse.inlineSpace)
        let (a,b) = try p.parse("a b")
        XCTAssertEqual(a, "a")
        XCTAssertEqual(b, "b")
    }
    
    func testManySep() throws {
        let p = Parse.anyChar.many(sepBy: Parse.inlineSpace)
        XCTAssertEqual([], try p.parse())
        XCTAssertEqual(["a","b","c"], try p.parse("a b c"))
        XCTAssertThrowsError(try p.parse("a b c "))
    }
    
    func testSomeSep() throws {
        let p = Parse.anyChar.some(sepBy: Parse.inlineSpace)
        XCTAssertThrowsError(try p.parse())
        XCTAssertEqual(["a","b","c"], try p.parse("a b c"))
        XCTAssertThrowsError(try p.parse("a b c "))
    }
    
    func testManyEnd() throws {
        let p = Parse.anyChar.many(endBy: Parse.inlineSpace)
        XCTAssertEqual([], try p.parse())
        XCTAssertEqual(["a","b","c"], try p.parse("a b c "))
        XCTAssertThrowsError(try p.parse("a b c"))
    }
    
    func testSomeEnd() throws {
        let p = Parse.anyChar.some(endBy: Parse.inlineSpace)
        XCTAssertThrowsError(try p.parse())
        XCTAssertEqual(["a","b","c"], try p.parse("a b c "))
        XCTAssertThrowsError(try p.parse("a b c"))
    }
    
    func testManySepEnd() throws {
        let p = Parse.anyChar.many(sepEndBy: Parse.inlineSpace)
        XCTAssertEqual([], try p.parse())
        XCTAssertEqual(["a","b","c"], try p.parse("a b c"))
        XCTAssertEqual(["a","b","c"], try p.parse("a b c "))
    }
    
    func testSomeSepEnd() throws {
        let p = Parse.anyChar.some(sepEndBy: Parse.inlineSpace)
        XCTAssertThrowsError(try p.parse())
        XCTAssertEqual(["a","b","c"], try p.parse("a b c"))
        XCTAssertEqual(["a","b","c"], try p.parse("a b c "))
    }
    
    func testManyTill() throws {
        let p = ("foo" as Parser).many(till: ";")
        XCTAssertThrowsError(try p.parse())
        XCTAssertEqual([], try p.parse(";"))
        XCTAssertEqual(["foo","foo","foo"], try p.parse("foofoofoo;"))
        XCTAssertThrowsError(try p.parse("foofoofoo"))
    }
    
    func testSomeTill() throws {
        let p = ("foo" as Parser).some(till: ";")
        XCTAssertThrowsError(try p.parse())
        XCTAssertThrowsError(try p.parse(";"))
        XCTAssertEqual(["foo","foo","foo"], try p.parse("foofoofoo;"))
        XCTAssertThrowsError(try p.parse("foofoofoo"))
    }
    
    func testNotFollowedBy() throws {
        let p = ("foo" as Parser).notFollowedBy("bar")
        XCTAssertEqual("foo", try p.parse("foo"))
        XCTAssertEqual("foo", try p.skipRemainingInput.parse("foob"))
        XCTAssertEqual("foo", try p.skipRemainingInput.parse("fooba"))
        XCTAssertEqual("foo", try p.skipRemainingInput.parse("foobaa"))
        XCTAssertThrowsError(try p.parse("foobar"))
    }
    
}
