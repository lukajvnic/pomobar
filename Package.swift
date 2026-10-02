// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Pomobar",
    platforms: [.macOS(.v26)],
    targets: [
        .executableTarget(
            name: "Pomobar",
            path: "Sources/Pomobar"
        )
    ]
)
