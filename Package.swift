// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VectorClock",
    products: [
        .library(
            name: "VectorClock",
            targets: ["VectorClock"]),
    ],
    targets: [
        .target(
            name: "VectorClock",
            dependencies: []),
        .testTarget(
            name: "VectorClockTests",
            dependencies: ["VectorClock"]),
    ]
)
