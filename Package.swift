// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Wolt",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Wolt", targets: ["Wolt"])
    ],
    targets: [
        .executableTarget(
            name: "Wolt",
            path: "Sources/Wolt"
        )
    ]
)
