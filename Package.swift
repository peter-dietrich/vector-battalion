// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VectorBattalion",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "VectorBattalion", targets: ["VectorBattalion"])],
    targets: [.executableTarget(name: "VectorBattalion", path: "Sources/VectorBattalion")]
)
