// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TestLibrary",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "TestLibrary",
            targets: ["TestLibrary"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "TestLibrary",
            url: "https://github.com/OdNairy/TestBinaryDependency/releases/download/2.0.3/TestLibrary.xcframework.zip",
            checksum: "eadc1b79fa7b53afaf9ed98a64ef11b9e15be7ca53b3e898605c7f0158db78e8"
        )
    ]
)
