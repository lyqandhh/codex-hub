// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CodexHUD",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "CodexHUDCore", targets: ["CodexHUD"]),
        .executable(name: "CodexHUD", targets: ["CodexHUDApp"])
    ],
    targets: [
        .target(name: "CodexHUD"),
        .executableTarget(name: "CodexHUDApp", dependencies: ["CodexHUD"], path: "App"),
        .testTarget(name: "CodexHUDTests", dependencies: ["CodexHUD"])
    ]
)
