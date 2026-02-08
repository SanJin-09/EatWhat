// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "FeatureReview",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "FeatureReview",
            targets: ["FeatureReview"]
        )
    ],
    dependencies: [
        .package(path: "../CoreDomain"),
        .package(path: "../CoreNetworking"),
        .package(path: "../CoreAnalytics"),
    ],
    targets: [
        .target(
            name: "FeatureReview",
            dependencies: [
                "CoreDomain",
                "CoreNetworking",
                "CoreAnalytics",
            ]
        ),
        .testTarget(
            name: "FeatureReviewTests",
            dependencies: ["FeatureReview"]
        )
    ]
)
