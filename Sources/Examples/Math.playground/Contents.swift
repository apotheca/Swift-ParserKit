import Foundation
import ParserKit

extension Parse {
    
    enum Math {
        
        typealias Binop = (Int) -> ((Int) -> Int)

        static let integer = lexeme(digit.some).map { Int(String($0))! }

        static let mul:   Binop = { x in { y in x * y } } // curry(*)
        static let div:   Binop = { x in { y in x / y } } // curry(/)
        static let plus:  Binop = { x in { y in x + y } } // curry(+)
        static let minus: Binop = { x in { y in x - y } } // curry(-)

        static let mulop = symbol("*") ^> mul
                       <|> symbol("/") ^> div

        static let addop = symbol("+") ^> plus
                       <|> symbol("-") ^> minus

        static let factor = { rec in parens(rec) <|> integer }
        static let term   = { rec in factor(rec).chain(mulop) }
        static let expr   = fix { rec in term(rec).chain(addop) }
    }
    
}

let result = try! Parse.Math.expr.parse("5 + 3 * (12 - 10 / 2)")
print(result)
// Prints:
// 26
