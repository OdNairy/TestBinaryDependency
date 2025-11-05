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
            url: "https://github.com/OdNairy/TestBinaryDependency/releases/download/1.0.1/TestLibrary-v1.0.1.xcframework.zip",
            checksum: "333dc261ef748b1b9e6324a59591d804567002b8a95fbde8c7c3fe462c16090c"
        )
    ]
)
