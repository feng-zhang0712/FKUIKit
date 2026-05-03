// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "FKKit",
  platforms: [
    .iOS(.v15),
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
        // Module docs only — avoids SwiftPM “unhandled file” warnings for README.md
        "Components/Badge/README.md",
        "Components/BlurView/README.md",
        "Components/Button/README.md",
        "Components/CornerShadow/README.md",
        "Components/Divider/README.md",
        "Components/EmptyState/README.md",
        "Components/ExpandableText/README.md",
        "Components/MultiPicker/README.md",
        "Components/PresentationController/README.md",
        "Components/ProgressBar/README.md",
        "Components/Refresh/README.md",
        "Components/Skeleton/README.md",
        "Components/TabBar/README.md",
        "Components/TextField/README.md",
        "Components/Toast/README.md",
      ]
    ),
    .target(
      name: "FKEmptyStateCoreLite",
      path: "Sources/FKUIKit/Components/EmptyState/CoreLite"
    ),
    .target(
      name: "FKCoreKit",
      path: "Sources/FKCoreKit",
      exclude: [
        "Async/README.md",
        "BusinessKit/README.md",
        "FileManager/README.md",
        "Logger/README.md",
        "Network/README.md",
        "Permissions/README.md",
        "Security/README.md",
        "Storage/README.md",
        "Utils/README.md",
      ]
    ),
    .target(
      name: "FKCompositeKit",
      dependencies: ["FKUIKit", "FKCoreKit"],
      path: "Sources/FKCompositeKit",
      exclude: [
        // Module docs only — avoids SwiftPM “unhandled file” warnings for README.md
        "Components/AnchoredDropdownController/README.md",
        "Components/Base/README.md",
        "Components/ListKit/README.md",
      ]
    ),
    .testTarget(
      name: "FKCoreKitTests",
      dependencies: ["FKCoreKit"],
      path: "Tests/FKCoreKitTests"
    ),
  ],
  swiftLanguageModes: [.v6]
)
