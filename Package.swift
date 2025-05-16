// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SettingsController",
    defaultLocalization: .init(rawValue: "en"),
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "SettingsController",
            targets: ["SettingsController"]),
    ],
    dependencies: [
        .package(url: "https://github.com/sparrowcode/AlertKit.git", .upToNextMajor(from: "5.1.9")),
        .package(url: "https://github.com/sparrowcode/SafeSFSymbols.git", .upToNextMajor(from: "2.0.1")),
        .package(url: "https://github.com/VladLikov/ReviewHelper.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "SettingsController",
            dependencies: [
                "AlertKit",
                "SafeSFSymbols",
                "AppReview",
            ],
            resources: [.process("Resources")]),
    ]
)
