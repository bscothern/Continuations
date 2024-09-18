// swift-tools-version:5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Continuations",
    products: [
        .library(
            name: "Continuations",
            targets: ["Continuations"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-atomics.git", from: "1.0.1"),
    ],
    targets: [
        .target(
            name: "Continuations",
            dependencies: [
                .product(name: "Atomics", package: "swift-atomics")
            ]
        ),
        .testTarget(
            name: "ContinuationsTests",
            dependencies: ["Continuations"]
        ),
    ],
    swiftLanguageVersions: [.v5, .version("6")]
)
