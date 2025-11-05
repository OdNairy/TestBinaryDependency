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
            url: "https://github.com/OdNairy/TestBinaryDependency/releases/download/2.0.1/TestLibrary-v2.0.1.xcframework.zip",
            checksum: "707eb9c4066c098f1ef7152feddb3ea5b9bdee26f67289bf03e86ea5a2f40cd1"
        )
    ]
)
