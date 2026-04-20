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
    .library(name: "FKCoreKit", targets: ["FKCoreKit"]),
    .library(name: "FKCompositeKit", targets: ["FKCompositeKit"]),
  ],
  targets: [
    .target(
      name: "FKUIKit",
      path: "Sources/FKUIKit"
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

