// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "FKKit",
  platforms: [
    .iOS(.v15),
    .macOS(.v10_15),
  ],
  products: [
    .library(name: "FKUIKit", targets: ["FKUIKit"]),
    .library(name: "FKEmptyStateCoreLite", targets: ["FKEmptyStateCoreLite"]),
    .library(name: "FKCoreKit", targets: ["FKCoreKit"]),
    .library(name: "FKCompositeKit", targets: ["FKCompositeKit"]),
  ],
  targets: [
    .target(
      name: "FKUIKit",
      dependencies: ["FKEmptyStateCoreLite"],
      path: "Sources/FKUIKit",
      exclude: [
        "Components/EmptyState/CoreLite",
      ]
    ),
    .target(
      name: "FKEmptyStateCoreLite",
      path: "Sources/FKUIKit/Components/EmptyState/CoreLite"
    ),
    .target(
      name: "FKCoreKit",
      path: "Sources/FKCoreKit"
    ),
    .target(
      name: "FKCompositeKit",
      dependencies: ["FKUIKit", "FKCoreKit"],
      path: "Sources/FKCompositeKit"
    ),
  ],
  swiftLanguageModes: [.v6]
)

