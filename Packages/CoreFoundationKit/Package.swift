// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "CoreFoundationKit",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "CoreFoundationKit",
            targets: ["CoreFoundationKit"]
        )
    ],
    targets: [
        .target(
            name: "CoreFoundationKit",
            dependencies: []
        ),
        .testTarget(
            name: "CoreFoundationKitTests",
            dependencies: ["CoreFoundationKit"]
        )
    ]
)
