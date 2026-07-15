// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CodexHUD",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "CodexHUDCore", targets: ["CodexHUD"]),
        .executable(name: "CodexHUD", targets: ["CodexHUDApp"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/swiftlang/swift-testing.git",
            revision: "18c42c19cac3fafd61cab1156d4088664b7424ae"
        )
    ],
    targets: [
        .target(name: "CodexHUD"),
        .executableTarget(name: "CodexHUDApp", dependencies: ["CodexHUD"], path: "App"),
        .testTarget(
            name: "CodexHUDTests",
            dependencies: [
                "CodexHUD",
                .product(name: "Testing", package: "swift-testing")
            ]
        )
    ]
)
