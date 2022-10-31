// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "KeyChainClient",
    platforms: [.iOS(.v13), .macOS(.v10_15)],
    products: [
        .library(
            name: "KeyChainClientAPI",
            targets: [ "KeyChainClientAPI", ]),
        .library(
            name: "KeyChainClientAsync",
            targets: [ "KeyChainClientAsync", ]),
        .library(
            name: "KeyChainClientLive",
            targets: [ "KeyChainClientLive", ]),
        .library(
            name: "KeyChainClientTest",
            targets: [ "KeyChainClientTest", ]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", branch: "main"),
        .package(url: "https://github.com/fltrWallet/HaByLo", branch: "main"),
    ],
    targets: [
        .target(
            name: "KeyChainClientAPI",
            dependencies: [ "HaByLo" ]),
        .target(
            name: "KeyChainClientAsync",
            dependencies: [ "HaByLo",
                            "KeyChainClientAPI",
                            .product(name: "NIOCore", package: "swift-nio"),
                            .product(name: "NIOPosix", package: "swift-nio"), ]),
        .target(
            name: "KeyChainClientLive",
            dependencies: [ "HaByLo",
                            "KeyChainClientAPI",
                            "KeyChainClientAsync", ]),
        .target(
            name: "KeyChainClientTest",
            dependencies: [ "HaByLo",
                            "KeyChainClientAPI", ]),
        .testTarget(
            name: "KeyChainClientTests",
            dependencies: [ "HaByLo",
                            .product(name: "NIOCore", package: "swift-nio"),
                            .product(name: "NIOPosix", package: "swift-nio"),
                            "KeyChainClientAPI",
                            "KeyChainClientAsync",
                            "KeyChainClientLive",
                            "KeyChainClientTest" ]),
    ]
)
