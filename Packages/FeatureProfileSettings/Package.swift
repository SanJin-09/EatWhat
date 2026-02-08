// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "FeatureProfileSettings",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "FeatureProfileSettings",
            targets: ["FeatureProfileSettings"]
        )
    ],
    dependencies: [
        .package(path: "../CoreDomain"),
        .package(path: "../CoreStorage"),
    ],
    targets: [
        .target(
            name: "FeatureProfileSettings",
            dependencies: [
                "CoreDomain",
                "CoreStorage",
            ]
        ),
        .testTarget(
            name: "FeatureProfileSettingsTests",
            dependencies: ["FeatureProfileSettings"]
        )
    ]
)
