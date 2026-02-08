// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "FeatureMealLog",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "FeatureMealLog",
            targets: ["FeatureMealLog"]
        )
    ],
    dependencies: [
        .package(path: "../CoreDomain"),
        .package(path: "../CoreStorage"),
        .package(path: "../CoreAnalytics"),
    ],
    targets: [
        .target(
            name: "FeatureMealLog",
            dependencies: [
                "CoreDomain",
                "CoreStorage",
                "CoreAnalytics",
            ]
        ),
        .testTarget(
            name: "FeatureMealLogTests",
            dependencies: ["FeatureMealLog"]
        )
    ]
)
