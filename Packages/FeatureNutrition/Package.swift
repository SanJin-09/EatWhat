// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "FeatureNutrition",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "FeatureNutrition",
            targets: ["FeatureNutrition"]
        )
    ],
    dependencies: [
        .package(path: "../CoreDomain"),
        .package(path: "../CoreNetworking"),
        .package(path: "../CoreDesignSystem"),
    ],
    targets: [
        .target(
            name: "FeatureNutrition",
            dependencies: [
                "CoreDomain",
                "CoreNetworking",
                "CoreDesignSystem",
            ]
        ),
        .testTarget(
            name: "FeatureNutritionTests",
            dependencies: ["FeatureNutrition"]
        )
    ]
)
