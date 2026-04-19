// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "FKKit",
  platforms: [
    .iOS(.v15),
  ],
  products: [
    .library(name: "FKUIKit", targets: ["FKUIKit"]),
    .library(name: "FKCompositeKit", targets: ["FKCompositeKit"]),
  ],
  targets: [
    .target(
      name: "FKUIKit",
      path: "Sources/FKUIKit"
    ),
    .target(
      name: "FKCompositeKit",
      dependencies: ["FKUIKit"],
      path: "Sources/FKCompositeKit"
    ),
  ],
  swiftLanguageModes: [.v6]
)

