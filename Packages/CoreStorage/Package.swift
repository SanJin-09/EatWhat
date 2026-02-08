// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "CoreStorage",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "CoreStorage",
            targets: ["CoreStorage"]
        )
    ],
    dependencies: [
        .package(path: "../CoreFoundationKit"),
    ],
    targets: [
        .target(
            name: "CoreStorage",
            dependencies: [
                "CoreFoundationKit",
            ]
        ),
        .testTarget(
            name: "CoreStorageTests",
            dependencies: ["CoreStorage"]
        )
    ]
)
