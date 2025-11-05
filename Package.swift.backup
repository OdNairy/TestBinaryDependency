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
            url: "https://github.com/OdNairy/TestBinaryDependency/releases/download/1.0.3/TestLibrary-v1.0.3.xcframework.zip",
            checksum: "f70b5face59ee225a4a10c0cccdd5548026d46b96b39463850fdf49f661b39b7"
        )
    ]
)
