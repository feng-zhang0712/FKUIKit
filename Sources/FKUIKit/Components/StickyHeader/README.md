# FKStickyHeader

`FKStickyHeader` is a pure Swift, non-invasive sticky section header component for iOS.

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
  - [Swift Package Manager](#swift-package-manager)
  - [CocoaPods](#cocoapods)
- [Usage](#usage)
  - [Quick Start](#quick-start)
  - [UICollectionView Support](#uicollectionview-support)
  - [Custom Offset](#custom-offset)
  - [Sticky Animation](#sticky-animation)
  - [State Callback](#state-callback)
  - [Waterfall List Support](#waterfall-list-support)
  - [Global Configuration](#global-configuration)
  - [SwiftUI Support](#swiftui-support)
- [API Reference](#api-reference)

## Overview
`FKStickyHeader` solves the common pain points of native grouped sticky headers on iOS:
- No custom base list class required.
- No third-party dependency.
- No intrusive business code refactor.

It can be enabled on existing `UIScrollView`, `UITableView`, and `UICollectionView` with one call, while still supporting advanced customization such as sticky offset, transition animation, and state lifecycle callbacks.

## Features
- Non-invasive integration for existing UIKit and SwiftUI screens.
- One-line enable API for `UITableView` and `UICollectionView`.
- Multi-section sticky behavior with push-out interaction (next section pushes current sticky header).
- Custom sticky reference offset for navigation bars or top overlay views.
- Progress-based transition callback for alpha, scale, color, and typography animation.
- Sticky lifecycle callbacks: `willSticky`, `didSticky`, `didUnsticky`.
- Runtime controls: enable/disable sticky, dynamic target updates, manual active target switching.
- Thread-safe public API (automatically dispatches UI updates to main thread).
- Global default configuration with per-list override.
- Designed for iOS 13+ with dark mode, safe area, and rotation compatibility.

## Requirements
- iOS 13.0+
- Swift 5.9+
- Xcode 14+

## Installation

### Swift Package Manager
Add FKKit in `Package.swift`:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "YourApp",
  platforms: [
    .iOS(.v13)
  ],
  dependencies: [
    .package(url: "https://github.com/your-org/FKKit.git", from: "1.0.0")
  ],
  targets: [
    .target(
      name: "YourApp",
      dependencies: [
        .product(name: "FKUIKit", package: "FKKit")
      ]
    )
  ]
)
```

### CocoaPods
Add `FKUIKit` to your `Podfile`:

```ruby
platform :ios, '13.0'
use_frameworks!

target 'YourApp' do
  pod 'FKUIKit'
end
```

Then run:

```bash
pod install
```

## Usage

### Quick Start
Enable sticky headers on a grouped `UITableView` in one line:

```swift
tableView.fk_enableSectionStickyHeaders()
```

### UICollectionView Support
Enable sticky headers on a `UICollectionView`:

```swift
collectionView.fk_enableSectionStickyHeaders()
```

### Custom Offset
Avoid overlap with navigation bars or custom top containers:

```swift
var configuration = FKStickyConfiguration.default
configuration.referenceOffsetY = 44
tableView.fk_enableSectionStickyHeaders(configuration: configuration)
```

### Sticky Animation
Drive custom animation with transition progress (`0...1`):

```swift
tableView.fk_enableSectionStickyHeaders { section, headerView in
  FKStickyTarget(
    id: "table_header_\(section)",
    viewProvider: { [weak headerView] in headerView },
    threshold: tableView.rectForHeader(inSection: section).minY,
    onTransition: { progress, view in
      view.alpha = 0.75 + 0.25 * progress
      view.transform = CGAffineTransform(scaleX: 0.98 + 0.02 * progress, y: 0.98 + 0.02 * progress)
      view.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.08 + 0.16 * progress)
    }
  )
}
```

### State Callback
Listen to sticky lifecycle for business logic:

```swift
let target = FKStickyTarget(
  id: "section_0",
  viewProvider: { [weak header] in header },
  threshold: 0,
  onStateChanged: { state in
    switch state {
    case .willSticky(let id):
      print("will sticky:", id)
    case .didSticky(let id):
      print("did sticky:", id)
    case .didUnsticky(let id):
      print("did unsticky:", id)
    }
  }
)
```

### Waterfall List Support
Use custom section header kind when your waterfall layout provides supplementary headers:

```swift
collectionView.fk_enableSectionStickyHeaders(
  elementKind: UICollectionView.elementKindSectionHeader
)
```

### Global Configuration
Set app-wide defaults once, then override per list only when needed:

```swift
FKStickyManager.shared.updateTemplateConfiguration { config in
  config.referenceOffsetY = 8
  config.transitionDistance = 24
  config.animationCurve = .easeInOut
}
```

### SwiftUI Support
Bridge sticky behavior to SwiftUI `List` or `ScrollView`:

```swift
import SwiftUI
import FKUIKit

struct StickyListView: View {
  var body: some View {
    List {
      Section("Section A") {
        Text("A1")
        Text("A2")
      }
      Section("Section B") {
        Text("B1")
        Text("B2")
      }
    }
    .fk_stickyHeader { _ in
      // Provide targets after you resolve UIKit section header views.
      []
    }
  }
}
```

## API Reference
- `FKStickyConfiguration`: Type-safe sticky configuration model (offset, transition, curve, enable state, scroll callback).
- `FKStickyTarget`: Sticky target descriptor (threshold, activation offset, style callback, transition callback, state callback).
- `FKStickyState`: Sticky lifecycle event enum.
- `FKStickyStyle`: Visual sticky style enum.
- `FKStickyEngine`: Core runtime engine for target management, sticky layout updates, and manual sticky control.
- `FKStickyManager`: Global default configuration manager.
- `UIScrollView+FKSticky`: One-line sticky enable APIs for `UIScrollView`, `UITableView`, and `UICollectionView`.
- `FKStickyHeaderAdapter` / `View.fk_stickyHeader(...)`: SwiftUI integration layer.
