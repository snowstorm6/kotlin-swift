// swift-tools-version: 6.0
// Bản chạy trong Terminal: `swift run snake`. Dùng chung 5 file logic trong Snake/Game với app iOS.
import PackageDescription

let package = Package(
    name: "Snake",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "snake",
            path: ".",
            exclude: ["Snake/SnakeApp.swift", "Snake/ContentView.swift"],
            sources: ["Snake/Game", "Terminal"]
        ),
        .testTarget(
            name: "SnakeTests",
            dependencies: ["snake"],
            path: "Tests"
        ),
    ]
)
