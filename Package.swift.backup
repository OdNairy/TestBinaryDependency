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
            url: "https://github.com/OdNairy/TestBinaryDependency/releases/download/1.0.0/TestLibrary-v1.0.0.xcframework.zip",
            checksum: "f79c53d7fa653225e2d0352b2049e67e9eb2c0b2d1fb3356a29dc44402c12b4c"
        )
    ]
)
