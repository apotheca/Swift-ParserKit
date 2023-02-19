// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ParserKit",
    products: [
        .library(
            name: "ParserKit",
            targets: ["ParserKit"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ParserKit",
            dependencies: []),
        .testTarget(
            name: "ParserKitTests",
            dependencies: ["ParserKit"]),
    ]
)
