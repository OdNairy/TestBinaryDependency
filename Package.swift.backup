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
            checksum: "9739d0fd319e28f899529ba6144716b86566c72ac6650794b962cfb0b09143c6"
        )
    ]
)
