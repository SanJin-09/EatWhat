// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "FeatureRecommendation",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "FeatureRecommendation",
            targets: ["FeatureRecommendation"]
        )
    ],
    dependencies: [
        .package(path: "../CoreDomain"),
        .package(path: "../CoreNetworking"),
        .package(path: "../CoreAnalytics"),
    ],
    targets: [
        .target(
            name: "FeatureRecommendation",
            dependencies: [
                "CoreDomain",
                "CoreNetworking",
                "CoreAnalytics",
            ]
        ),
        .testTarget(
            name: "FeatureRecommendationTests",
            dependencies: [
                "FeatureRecommendation",
                "CoreDomain",
            ]
        )
    ]
)
