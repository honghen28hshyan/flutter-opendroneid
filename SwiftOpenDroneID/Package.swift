// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SwiftOpenDroneID",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "SwiftOpenDroneID",
            targets: ["SwiftOpenDroneID"]),
    ],
    targets: [
        .target(
            name: "SwiftOpenDroneID",
            dependencies: []),
        .testTarget(
            name: "SwiftOpenDroneIDTests",
            dependencies: ["SwiftOpenDroneID"]),
    ]
)
