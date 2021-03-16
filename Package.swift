// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Swagen",
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
