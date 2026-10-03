// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KeychainStore",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
        .watchOS(.v7),
        .tvOS(.v14)
    ],
    products: [
        .library(
            name: "KeychainStore",
            targets: ["KeychainStore"]
        )
    ],
    targets: [
        .target(
            name: "KeychainStore",
            dependencies: []
        ),
        .testTarget(
            name: "KeychainStoreTests",
            dependencies: ["KeychainStore"]
        )
    ]
)
