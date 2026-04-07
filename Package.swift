// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "FKUIKit",
  platforms: [
    .iOS(.v15),
  ],
  products: [
    .library(name: "FKBar", targets: ["FKBar"]),
    .library(name: "FKButton", targets: ["FKButton"]),
    .library(name: "FKBarPresentation", targets: ["FKBarPresentation"]),
    .library(name: "FKPresentation", targets: ["FKPresentation"]),
    .library(name: "FKUIKitCore", targets: ["FKUIKitCore"]),
  ],
  targets: [
    .target(
      name: "FKUIKitCore",
      path: "Sources/FKUIKitCore"
    ),
    .target(
      name: "FKButton",
      dependencies: ["FKUIKitCore"],
      path: "Sources/FKButton"
    ),
    .target(
      name: "FKBar",
      dependencies: ["FKButton", "FKUIKitCore"],
      path: "Sources/FKBar"
    ),
    .target(
      name: "FKPresentation",
      dependencies: ["FKUIKitCore"],
      path: "Sources/FKPresentation"
    ),
    .target(
      name: "FKBarPresentation",
      dependencies: ["FKBar", "FKPresentation", "FKUIKitCore"],
      path: "Sources/FKBarPresentation"
    ),
  ],
  swiftLanguageModes: [.v6]
)
