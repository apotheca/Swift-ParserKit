import XCTest
import FunctorKit
@testable import ParserKit

final class ParserTests: XCTestCase {
    
    // Fix point
    
    func testFix() throws {
        func succ(_ rec: Parser<Int>) -> Parser<Int> {
            return "s" *> rec.map({ $0 + 1 })
        }
        let zero: Parser<Int> = "z" ^> 0
        let nat: Parser<Int> = Parse.fix { rec in
            succ(rec) <|> zero
        }
        XCTAssertEqual(0, try nat.parse("z"))
        XCTAssertEqual(1, try nat.parse("sz"))
        XCTAssertEqual(3, try nat.parse("sssz"))
        XCTAssertThrowsError(try nat.parse("sssx"))
    }
    
    // Functor
    
    func testMap() throws {
        let p = { $0 * 2 } <^> Parser(5)
        // Alternatively:
        // let p = Parser(5).map { $0 * 2 }
        let a = try p.parse()
        XCTAssertEqual(a, 10)
    }
    
    // Applicative
    
    func testPure() throws {
        let p = Parser.pure(5)
        let a = try p.parse()
        XCTAssertEqual(a, 5)
    }
    
    func testAp() throws {
        let p = { x in { y in x + y } } <^> Parser(5) <*> Parser(10)
        // Alternatively:
        // let p = Parser(5).map { x in { y in x + y } } .ap(Parser(10))
        let a = try p.parse()
        XCTAssertEqual(a, 15)
    }
    
    // Monad
    
    func testBind() throws {
        let p = Parser(5) >>- { x in Parser(x + 15) }
        // Alternatively:
        // let p = Parser(5).bind { x in Parser(x + 15) }
        let a = try p.parse()
        XCTAssertEqual(a, 20)
    }
    
    // Alternative
    
    func testEmpty() throws {
        let p = Parser<()>.empty
        XCTAssertThrowsError(try p.parse())
    }
    
    func testAlt() throws {
        let p = Parser.empty <|> Parser(5)
        // Alternatively:
        // let p = Parser.empty.alt(Parser(5))
        let a = try p.parse()
        XCTAssertEqual(a, 5)
        
        let p2 = Parser(5) <|> Parser.empty
        let a2 = try p2.parse()
        XCTAssertEqual(a2, 5)
    }
    
    func testMany() throws {
        let p = Parse.char("a").many
        
        XCTAssertEqual(try p.parse(), [])
        
        let aList = try p.parse("aaa")
        XCTAssertEqual(aList, ["a","a","a"])
    }
    
    func testSome() throws {
        let p = Parse.char("a").some
        
        XCTAssertThrowsError(try p.parse())
        
        let aList = try p.parse("aaa")
        XCTAssertEqual(aList, ["a","a","a"])
    }
    
    // TODO: Error tests
    
    // TODO: Label tests
    
    func testLabel() throws {
        let label = "abc-word"
        let p = (Parse.oneOf("abc").many <* Parse.eof) <?> label
        XCTAssertNoThrow(try p.parse("abc"))
        do {
            let _ = try p.parse("abcdef")
        } catch let f as ParserFailure {
            XCTAssertEqual(.expected(label), f.error)
        }
    }
    
}
