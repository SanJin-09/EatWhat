// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "CoreDesignSystem",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "CoreDesignSystem",
            targets: ["CoreDesignSystem"]
        )
    ],
    dependencies: [
        .package(path: "../CoreFoundationKit"),
    ],
    targets: [
        .target(
            name: "CoreDesignSystem",
            dependencies: [
                "CoreFoundationKit",
            ]
        ),
        .testTarget(
            name: "CoreDesignSystemTests",
            dependencies: ["CoreDesignSystem"]
        )
    ]
)
