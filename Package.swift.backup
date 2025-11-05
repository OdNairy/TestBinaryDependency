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
            url: "https://github.com/OdNairy/TestBinaryDependency/releases/download/v1.0.0/TestLibrary-v1.0.0.xcframework.zip",
            checksum: "04d4e7592fc09f26e563ba46734606f8c12bd4f8dc0be359b0c995d6c9d2f941"
        )
    ]
)
