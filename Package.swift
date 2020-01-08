// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Swagen",
    products: [
        .executable(name: "swagen", targets: ["Swagen"]),
    ],
    targets: [
        .target(name: "Swagen", path: "Swagen"),
    ]
)
