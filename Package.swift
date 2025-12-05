// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Notchy",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "Notchy",
            targets: ["Notchy"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Notchy",
            dependencies: [],
            path: "Notchy",
            resources: [
                .copy("Resources")
            ]
        )
    ]
)