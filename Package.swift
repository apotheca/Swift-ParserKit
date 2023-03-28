// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ParserKit",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "ParserKit",
            targets: ["ParserKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apotheca/Swift-FunctorKit", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "ParserKit",
            dependencies: [
                .product(name: "FunctorKit", package: "Swift-FunctorKit"),
            ]),
        .testTarget(
            name: "ParserKitTests",
            dependencies: [
                .product(name: "FunctorKit", package: "Swift-FunctorKit"),
                "ParserKit"
            ]),
    ]
)
