// Currying
// Allows us to replace:
//  let plusFn = { x in { y in x + y }}
// With:
//  let plusFn = curry(+)
// This makes it easier to write code like:
//  let plus = curry(+) <^> integer <*> integer
public func curry<A,B,C>(_ fn: @escaping (A,B) -> C) -> ((A) -> ((B) -> C)) {
    return { a in { b in fn(a,b) } }
}

// Uncurrying
public func uncurry<A,B,C>(_ fn: @escaping (A) -> ((B) -> C)) -> ((A,B) -> C) {
    return { (a,b) in fn(a)(b) }
}

public func curry3<A,B,C,D>(_ fn: @escaping (A,B,C) -> D) -> ((A) -> ((B) -> ((C) -> D))) {
    return { a in { b in { c in fn(a,b,c) } } }
}
public func uncurry3<A,B,C,D>(_ fn: @escaping (A) -> ((B) -> ((C) -> D))) -> ((A,B,C) -> D) {
    return { (a,b,c) in fn(a)(b)(c) }
}
