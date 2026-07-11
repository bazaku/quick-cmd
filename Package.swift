// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "QuickCmd",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "QuickCmdCore"),
        .executableTarget(
            name: "QuickCmd",
            dependencies: ["QuickCmdCore"]
        ),
        .testTarget(
            name: "QuickCmdCoreTests",
            dependencies: ["QuickCmdCore"]
        ),
    ]
)
