// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "FeatureCampusStore",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "FeatureCampusStore",
            targets: ["FeatureCampusStore"]
        )
    ],
    dependencies: [
        .package(path: "../CoreDomain"),
        .package(path: "../CoreNetworking"),
        .package(path: "../CoreDesignSystem"),
    ],
    targets: [
        .target(
            name: "FeatureCampusStore",
            dependencies: [
                "CoreDomain",
                "CoreNetworking",
                "CoreDesignSystem",
            ]
        ),
        .testTarget(
            name: "FeatureCampusStoreTests",
            dependencies: ["FeatureCampusStore"]
        )
    ]
)
