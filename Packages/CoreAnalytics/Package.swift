// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "CoreAnalytics",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "CoreAnalytics",
            targets: ["CoreAnalytics"]
        )
    ],
    dependencies: [
        .package(path: "../CoreFoundationKit"),
        .package(path: "../CoreNetworking"),
    ],
    targets: [
        .target(
            name: "CoreAnalytics",
            dependencies: [
                "CoreFoundationKit",
                "CoreNetworking",
            ]
        ),
        .testTarget(
            name: "CoreAnalyticsTests",
            dependencies: ["CoreAnalytics"]
        )
    ]
)
