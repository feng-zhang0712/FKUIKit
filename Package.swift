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
    .library(name: "FKPopover", targets: ["FKPopover"]),
    .library(name: "FKPresentation", targets: ["FKPresentation"]),
    .library(name: "FKUIKitCore", targets: ["FKUIKitCore"]),
  ],
  targets: [
    .target(
      name: "FKBar",
      dependencies: ["FKButton", "FKUIKitCore"],
      path: "Sources/FKBar"
    ),
    .target(
      name: "FKButton",
      dependencies: ["FKUIKitCore"],
      path: "Sources/FKButton"
    ),
    .target(
      name: "FKPopover",
      dependencies: ["FKBar", "FKPresentation", "FKUIKitCore"],
      path: "Sources/FKPopover"
    ),
    .target(
      name: "FKPresentation",
      dependencies: ["FKUIKitCore"],
      path: "Sources/FKPresentation"
    ),
    .target(
      name: "FKUIKitCore",
      path: "Sources/FKUIKitCore"
    ),
  ],
  swiftLanguageModes: [.v6]
)
