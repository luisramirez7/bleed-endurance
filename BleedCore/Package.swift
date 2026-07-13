// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BleedCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "BleedCore", targets: ["BleedCore"])
    ],
    targets: [
        .target(name: "BleedCore"),
        .testTarget(name: "BleedCoreTests", dependencies: ["BleedCore"]),
    ]
)
