# Writing a math expression parser

Create a parser for performing simple math calculations.

## Overview

To showcase our ability to build more complex and more useful parsers, we will now build an expression parser for simple math problems, involving parenthesis, multiplication, division, addition, and subtraction, and have it actually carry out and return the result of evaluating the expression.

> NOTE: Sharp readers will have noticed that this is simply PEMDAS minus the E.

For convenience, we will write our parsers as an extension to the ``Parse`` namespace.

```swift
extension Parse {
    public enum Math {
        // Our parsers go here
    }
}
```

## The integer parser

We'll start with a simple integer parser.


```swift
let integer = lexeme(digit.some).map { Int(String($0))! }
```

An integer is some digits (``Parser/some`` and ``Parse/digit``), and we use ``Parse/lexeme(_:)`` to consume any trailing whitespace, because we want to be able to insert spaces in-between our number and operators. Finally, we convert the parsed integer into an `Int`.

## The operator parsers

Here, we define our math functions. Because we are building a parser using combinators, we need to be able to [act on a single argument at a time](https://en.wikipedia.org/wiki/Currying). So, rather than having a binary function `(Int,Int) -> Int` that takes two `Int` at the same time, and produces an `Int`, we need to define our binary operations as a function that takes one `Int` and produces a `(Int) -> Int`, which we can then feed the second argument. More on that shortly.

We define the `Binop` typealias to make referring to this a little bit easier. Then we simply define our binary functions.

```swift
typealias Binop = (Int) -> ((Int) -> Int)

let mul:   Binop = { x in { y in x * y }}
let div:   Binop = { x in { y in x / y }}
let plus:  Binop = { x in { y in x + y }}
let minus: Binop = { x in { y in x - y }}
```

We then match each operator to a math symbol in our binary operator parsers, using ``^>`` to return the actual function instead of the symbol. Multiplication and division are of the same precedence, as are addition and subtraction.

```swift
let mulop = symbol("*") ^> mul
        <|> symbol("/") ^> div

let addop = symbol("+") ^> plus
        <|> symbol("-") ^> minus
```

We use ``<|>``, a convenient infix operator for ``Parser/alt(_:)``, to first try one parser, then try another if the first one fails.

## The expression parsers

Now, we define our expression parsers.

```swift
let factor = { rec in parens(rec) <|> integer }
let term   = { rec in factor(rec).chain(mulop) }
let expr   = fix { rec in term(rec).chain(addop) }
```

A factor is either a subexpression enclosed in parenthesis using ``Parse/parens(_:)``, or an integer. A term is one or more factors, ``Parser/chain(_:)`` -ed together with multiplicative operations. An expression is one or more terms, this time ``Parser/chain(_:)`` -ed together with additive operations. All together, this gives parenthesis P the highest precedence, followed by multiplication and division MD with the next-highest precedence, and lastly giving addition and subtraction AS the lowest precedence. We use explicit recursion with the ``Parser/fix(_:)`` function here in order to stop Swift from eagerly evaluating an infinite loop.

> TIP: Try to figure out how to add Exponentiation to the expression parser using `^` to give us a complete PEMDAS parser. How would you go about giving it the proper precedence? Can you spot the pattern?

That's it! We're now ready to evaluate some simple mathematical expressions!

## Our final code

Let's take a look at all of our code put together.

```swift
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
```

That's a nice tidy paragraph. So what does it do?

## Testing it out

Let's test it out.

```swift
let result = try! Parse.Math.expr.parse("5 + 3 * (12 - 10 / 2)")
print(result)
// Prints:
// 26
```

Wow! It actually prints out the proper result! we can give it any well-formatted math expression, and not only will it parse it, but it will perform the evaluation at the same time!

## Conclusion

We've shown how parsing can be useful for more than just reading static data from a file - we can actually use it to perform work at the same time! This forms the basis of [Parse, don't validate](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/),  a powerful functional programming pattern.
