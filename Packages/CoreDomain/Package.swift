// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "CoreDomain",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "CoreDomain",
            targets: ["CoreDomain"]
        )
    ],
    dependencies: [
        .package(path: "../CoreFoundationKit"),
    ],
    targets: [
        .target(
            name: "CoreDomain",
            dependencies: [
                "CoreFoundationKit",
            ]
        ),
        .testTarget(
            name: "CoreDomainTests",
            dependencies: ["CoreDomain"]
        )
    ]
)
