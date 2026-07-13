// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CodexHUD",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "CodexHUD", targets: ["CodexHUD"])
    ],
    targets: [
        .executableTarget(name: "CodexHUD"),
        .testTarget(name: "CodexHUDTests", dependencies: ["CodexHUD"])
    ]
)
