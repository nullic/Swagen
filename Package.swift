// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Swagen",
    platforms: [ .macOS(.v10_14)],
    products: [
        .executable(name: "swagen", targets: ["Swagen"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMajor(from: "0.0.0")),
    ],
    targets: [
        .target(name: "Swagen", dependencies: [.product(name: "ArgumentParser", package: "swift-argument-parser"),], path: "Swagen"),
    ]
)
