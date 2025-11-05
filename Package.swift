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
            url: "https://github.com/OdNairy/TestBinaryDependency/releases/download/1.0.2/TestLibrary-v1.0.2.xcframework.zip",
            checksum: "1f8ab52250f5c9b36058354215e577c8d6be1af6d50ac119245170ca4e7c5ad6"
        )
    ]
)
