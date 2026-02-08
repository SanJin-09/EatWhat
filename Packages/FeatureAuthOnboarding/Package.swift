// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "FeatureAuthOnboarding",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "FeatureAuthOnboarding",
            targets: ["FeatureAuthOnboarding"]
        )
    ],
    dependencies: [
        .package(path: "../CoreDomain"),
        .package(path: "../CoreNetworking"),
        .package(path: "../CoreStorage"),
    ],
    targets: [
        .target(
            name: "FeatureAuthOnboarding",
            dependencies: [
                "CoreDomain",
                "CoreNetworking",
                "CoreStorage",
            ]
        ),
        .testTarget(
            name: "FeatureAuthOnboardingTests",
            dependencies: ["FeatureAuthOnboarding"]
        )
    ]
)
