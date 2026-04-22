# FKSwipeAction

[![iOS](https://img.shields.io/badge/iOS-13.0%2B-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange.svg)](https://swift.org/)
[![SPM](https://img.shields.io/badge/Swift%20Package%20Manager-supported-brightgreen.svg)](https://swift.org/package-manager/)
[![CocoaPods](https://img.shields.io/badge/CocoaPods-supported-brightgreen.svg)](https://cocoapods.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-lightgrey.svg)](../../../../LICENSE)

High-performance, non-invasive swipe actions (WeChat/QQ-like) for **UITableView** and **UICollectionView**, with a lightweight **SwiftUI** bridge. Implemented with **pure Swift + UIKit**, no third-party dependencies.

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
  - [Custom Action Buttons](#custom-action-buttons)
  - [Swipe Direction](#swipe-direction)
  - [Multiple Expand Toggle](#multiple-expand-toggle)
  - [State Callback](#state-callback)
  - [Global Configuration](#global-configuration)
  - [SwiftUI Support](#swiftui-support)
- [API Reference](#api-reference)
- [License](#license)

## Overview

`FKSwipeAction` provides **multi-button swipe actions** for list items, similar to what you see in WeChat/QQ.

Unlike UIKit’s built-in patterns (which typically require implementing delegate APIs, customizing cell behaviors, or accepting limited styling), FKSwipeAction focuses on:

- **Non-invasive integration**: enable swipe actions with **one line** on an existing `UITableView` / `UICollectionView`.
- **No cell subclassing**: works with your existing cells and list architecture.
- **Fully customizable actions**: title/icon/layout/width/corner/gradient background/callback per button.
- **Smooth interaction**: rubber-banding, snapping open/close, optional “only one open at a time”.

## Features

- **Non-invasive enablement** for `UITableView` and `UICollectionView` (no subclassing required)
- **Multiple action buttons** per side
- **Per-button customization**
  - Title, icon, font, text color
  - Solid color / gradient background
  - Width, corner radius
  - Tap callback
- **Bidirectional swipe**
  - Swipe left to reveal right actions
  - Swipe right to reveal left actions
- **Snapping & rubber-band feel**
  - Configurable open threshold
  - Auto align to open/close on release
- **Mutual exclusion**
  - Default: only one cell stays open
  - Can be disabled to allow multiple open cells
- **Auto close**
  - Tap outside to close
  - Close on vertical scroll begin
  - Close after action tapped (optional)
- **State callback** for swipe start/end and action tap
- **Thread-safe API surface**
  - Can be called from any thread (UI work is scheduled onto main thread)
- **Adaptive by default**
  - Auto Layout friendly (buttons live behind `contentView` transform)
  - Supports rotation, safe area, and varying cell heights
- **SwiftUI bridge** for `List`/UIKit-backed scroll containers

## Requirements

- iOS 13.0+
- Swift 5.9+
- Xcode 14+

## Installation

### Swift Package Manager

Add FKKit to your project, then import `FKUIKit`.

In Xcode:

- `File` → `Add Packages...`
- Paste your repository URL
- Select the package and add it to your app target

Or in `Package.swift`:

```swift
dependencies: [
  .package(url: "https://your.repo.url/FKKit.git", from: "1.0.0")
]
```

Then add `FKKit` (or `FKUIKit`) to your target dependencies:

```swift
.target(
  name: "YourApp",
  dependencies: [
    .product(name: "FKUIKit", package: "FKKit")
  ]
)
```

### CocoaPods

Add to your `Podfile`:

```ruby
platform :ios, '13.0'
use_frameworks!

target 'YourApp' do
  pod 'FKKit'
end
```

Then install:

```bash
pod install
```

## Usage

### Quick Start

Enable swipe actions for a `UITableView` with **one line** (no cell subclassing required):

```swift
tableView.fk_enableSwipeActions { indexPath in
  FKSwipeActionConfiguration(
    rightActions: [
      FKSwipeActionButton(
        id: "delete",
        title: "Delete",
        background: .color(.systemRed),
        width: 84
      ) {
        // handle delete
      }
    ]
  )
}
```

### UICollectionView Support

```swift
collectionView.fk_enableSwipeActions { indexPath in
  FKSwipeActionConfiguration(
    rightActions: [
      FKSwipeActionButton(
        id: "more",
        title: "More",
        background: .horizontalGradient(leading: .systemBlue, trailing: .systemTeal),
        width: 84
      ) {
        // handle more
      }
    ]
  )
}
```

### Custom Action Buttons

Customize title/icon/layout/colors/gradients per action:

```swift
let pin = FKSwipeActionButton(
  id: "pin",
  title: "Pin",
  icon: UIImage(systemName: "pin.fill"),
  background: .color(.systemOrange),
  font: .systemFont(ofSize: 14, weight: .semibold),
  titleColor: .white,
  layout: .iconTop,
  width: 84,
  cornerRadius: 12
) {
  // pin item
}

let share = FKSwipeActionButton(
  id: "share",
  title: "Share",
  icon: UIImage(systemName: "square.and.arrow.up"),
  background: .verticalGradient(top: .systemIndigo, bottom: .systemPurple),
  layout: .iconLeading,
  width: 96
) {
  // share item
}
```

Use them in your configuration:

```swift
FKSwipeActionConfiguration(rightActions: [pin, share])
```

### Swipe Direction

Choose allowed swipe directions:

```swift
// Only swipe left (reveal right actions)
FKSwipeActionConfiguration(
  rightActions: [...],
  allowedDirections: [.left]
)

// Only swipe right (reveal left actions)
FKSwipeActionConfiguration(
  leftActions: [...],
  allowedDirections: [.right]
)

// Both directions
FKSwipeActionConfiguration(
  leftActions: [...],
  rightActions: [...],
  allowedDirections: .both
)
```

### Multiple Expand Toggle

By default, FKSwipeAction keeps **only one cell open at a time** (mutual exclusion).
To allow multiple cells to remain expanded:

```swift
FKSwipeActionConfiguration(
  rightActions: [...],
  allowsOnlyOneOpen: false
)
```

### State Callback

Listen to swipe start/end and button taps:

```swift
FKSwipeActionConfiguration(
  rightActions: [...],
  onEvent: { event in
    switch event {
    case .willBeginSwipe(let indexPath, let direction):
      print("Will begin swipe:", indexPath, direction)
    case .didEndSwipe(let indexPath, let isOpen, let direction):
      print("Did end swipe:", indexPath, "open:", isOpen, "direction:", String(describing: direction))
    case .didTapAction(let indexPath, let actionID):
      print("Tapped action:", actionID, "at", indexPath)
    }
  }
)
```

### Global Configuration

Set app-wide defaults once (e.g. at app launch), then override per list/cell when needed:

```swift
FKSwipeActionManager.globalDefaultConfiguration = FKSwipeActionConfiguration(
  openThreshold: 48,
  allowsOnlyOneOpen: true,
  tapToClose: true,
  autoCloseAfterAction: true,
  usesRubberBand: true
)
```

### SwiftUI Support

In SwiftUI, `List` is typically backed by UIKit list views (varies by iOS version).
FKSwipeAction provides a small background adapter that **non-invasively discovers** the underlying
`UITableView`/`UICollectionView` and enables swipe actions:

```swift
import SwiftUI

struct ContentView: View {
  var body: some View {
    List(0..<20, id: \.self) { row in
      Text("Row \(row)")
    }
    .fk_swipeAction { indexPath in
      FKSwipeActionConfiguration(
        rightActions: [
          FKSwipeActionButton(
            id: "delete",
            title: "Delete",
            background: .color(.systemRed),
            width: 84
          ) {
            // handle delete
          }
        ]
      )
    }
  }
}
```

## API Reference

### Models

- `FKSwipeActionButton`
  - `id`: Stable action identifier for callbacks
  - `title`, `icon`
  - `background`: `.color`, `.verticalGradient`, `.horizontalGradient`
  - `layout`: `.title`, `.icon`, `.iconTop`, `.iconLeading`
  - `width`, `cornerRadius`
  - `handler`: Tap callback

- `FKSwipeActionConfiguration`
  - `leftActions`, `rightActions`
  - `allowedDirections`: `.left`, `.right`, `.both`
  - `openThreshold`: Open distance threshold in points
  - `allowsOnlyOneOpen`: Mutual exclusion toggle
  - `tapToClose`, `autoCloseAfterAction`
  - `usesRubberBand`, `animationDuration`
  - `onEvent`: State callback (`willBeginSwipe`, `didEndSwipe`, `didTapAction`)

### UIKit Integration

- `UITableView.fk_enableSwipeActions(configuration:provider:)`
- `UICollectionView.fk_enableSwipeActions(configuration:provider:)`
- `fk_setSwipeActionsEnabled(_:)`
- `fk_closeSwipeActions(animated:)`

### SwiftUI Integration

- `View.fk_swipeAction(configuration:provider:)`
- `FKSwipeActionAdapter`

## License

FKSwipeAction is released under the **MIT License**. See `LICENSE`.

