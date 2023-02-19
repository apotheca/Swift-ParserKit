import Foundation
import ParserKit

extension Parse {
    enum CSV {
        static let cell  = satisfy { $0 != "," && !$0.isNewline }.many.map { String($0) }
        static let row   = cell.many(sepBy: ",")
        static let table = row.many(sepEndBy: lineBreak)
    }
}

let csv = try! Parse.CSV.table.parse("""
foo,bar,baz,qux
zip,zap,bip,bap
if,then,else,ni
""")

print(csv)
// Prints:
// [["foo", "bar", "baz", "qux"], ["zip", "zap", "bip", "bap"], ["if", "then", "else", "ni"]]

print(csv[1][2])
// Prints:
// bip
