// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "soundpool_macos",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "soundpool-macos", targets: ["soundpool_macos"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "soundpool_macos",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
