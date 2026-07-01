// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "LidBright",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "LidBrightCore",
            targets: ["LidBrightCore"]
        ),
        .executable(
            name: "LidBright",
            targets: ["LidBrightApp"]
        ),
        .executable(
            name: "LidBrightCoreBehaviorTests",
            targets: ["LidBrightCoreBehaviorTests"]
        )
    ],
    targets: [
        .target(
            name: "LidBrightCore"
        ),
        .executableTarget(
            name: "LidBrightApp",
            dependencies: ["LidBrightCore"],
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "LidBrightCoreBehaviorTests",
            dependencies: ["LidBrightCore"]
        )
    ]
)
