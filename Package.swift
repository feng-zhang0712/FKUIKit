// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "FKKit",
  platforms: [
    .iOS(.v15),
  ],
  products: [
    .library(name: "FKUIKit", targets: ["FKUIKit"]),
    .library(name: "FKBusinessKit", targets: ["FKBusinessKit"]),
  ],
  targets: [
    .target(
      name: "FKUIKit",
      path: "Sources/FKUIKit"
    ),
    .target(
      name: "FKBusinessKit",
      dependencies: ["FKUIKit"],
      path: "Sources/FKBusinessKit"
    ),
  ],
  swiftLanguageModes: [.v6]
)

