// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "CoreNetworking",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "CoreNetworking",
            targets: ["CoreNetworking"]
        )
    ],
    dependencies: [
        .package(path: "../CoreFoundationKit"),
    ],
    targets: [
        .target(
            name: "CoreNetworking",
            dependencies: [
                "CoreFoundationKit",
            ]
        ),
        .testTarget(
            name: "CoreNetworkingTests",
            dependencies: ["CoreNetworking"]
        )
    ]
)
