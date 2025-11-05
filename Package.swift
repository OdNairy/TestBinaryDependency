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
            url: "https://github.com/OdNairy/TestBinaryDependency/releases/download/1.0.4/TestLibrary-v1.0.4.xcframework.zip",
            checksum: "60d7ee1545b3a4bb304d2ccfe133c817cd9596146e5f617d1c72aa3f09c2e03b"
        )
    ]
)
