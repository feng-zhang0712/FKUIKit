# FKDivider

`FKDivider` is a lightweight, native Swift divider component for iOS with UIKit and SwiftUI support.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
  - [Swift Package Manager](#swift-package-manager)
  - [CocoaPods](#cocoapods)
- [Usage](#usage)
  - [Quick Start](#quick-start)
  - [Basic Divider](#basic-divider)
  - [1px Auto Scale](#1px-auto-scale)
  - [Indent & Margin](#indent--margin)
  - [Dashed Divider](#dashed-divider)
  - [Gradient Divider](#gradient-divider)
  - [Auto Pin to Edge](#auto-pin-to-edge)
  - [Global Configuration](#global-configuration)
  - [Interface Builder Usage](#interface-builder-usage)
  - [SwiftUI Support](#swiftui-support)
- [API Reference](#api-reference)
- [License](#license)

## Overview

`FKDivider` solves common UIKit/SwiftUI separator pain points:

- blurry lines on different screen scales
- repetitive Auto Layout code for edge-pinned separators
- limited customization in native separators

It provides a production-ready divider abstraction with pixel-perfect rendering, configurable line styles, gradient support, global defaults, and easy integration for both UIKit and SwiftUI.

## Features

- Horizontal and vertical divider support
- 1 physical pixel auto-scaling (`isPixelPerfect`) for Retina clarity
- Solid and dashed styles with customizable dash pattern
- Fully configurable thickness, color, and content insets
- Gradient divider support with configurable direction and colors
- Fast auto-pinning helpers for top/bottom/left/right edges
- Global default configuration via `FKDividerManager.shared`
- Per-instance override with `FKDividerConfiguration`
- Interface Builder support with `@IBDesignable` + `@IBInspectable`
- Dark mode friendly (dynamic color refresh)
- Thread-safe convenience API for adding dividers from any thread
- Pure Swift implementation, no third-party dependency

## Requirements

- iOS 13.0+
- Swift 5.9+
- Xcode 14.0+

## Installation

### Swift Package Manager

Add `FKKit` and use the `FKUIKit` product.

```swift
dependencies: [
  .package(url: "https://github.com/feng-zhang0712/FKKit.git", from: "0.34.0")
],
targets: [
  .target(
    name: "YourApp",
    dependencies: [
      .product(name: "FKUIKit", package: "FKKit")
    ]
  )
]
```

Then import:

```swift
import FKUIKit
```

### CocoaPods

```ruby
pod 'FKKit/FKUIKit'
```

Then run:

```bash
pod install
```

## Usage

### Quick Start

One-line divider creation:

```swift
let divider = FKDivider()
```

### Basic Divider

Horizontal divider:

```swift
var config = FKDividerConfiguration()
config.direction = .horizontal
let divider = FKDivider(configuration: config)
```

Vertical divider:

```swift
var config = FKDividerConfiguration()
config.direction = .vertical
let divider = FKDivider(configuration: config)
```

### 1px Auto Scale

Enable physical-pixel rendering (default enabled):

```swift
var config = FKDividerConfiguration()
config.isPixelPerfect = true
let divider = FKDivider(configuration: config)
```

Disable it and use logical point thickness:

```swift
var config = FKDividerConfiguration()
config.isPixelPerfect = false
config.thickness = 1.0
```

### Indent & Margin

Use `contentInsets` to shorten the rendered line:

```swift
var config = FKDividerConfiguration()
config.contentInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
let divider = FKDivider(configuration: config)
```

Use `margin` with auto-pinning helper:

```swift
containerView.fk_addDivider(at: .bottom, margin: 20)
```

### Dashed Divider

```swift
var config = FKDividerConfiguration()
config.lineStyle = .dashed
config.dashPattern = [6, 3] // draw 6pt, gap 3pt
let divider = FKDivider(configuration: config)
```

### Gradient Divider

```swift
var config = FKDividerConfiguration()
config.showsGradient = true
config.gradientStartColor = .systemBlue
config.gradientEndColor = .systemTeal
config.gradientDirection = .horizontal
let divider = FKDivider(configuration: config)
```

### Auto Pin to Edge

Attach dividers directly to container edges without manual constraints:

```swift
containerView.fk_addDivider(at: .top)
containerView.fk_addDivider(at: .bottom, margin: 16)
containerView.fk_addDivider(at: .left)
containerView.fk_addDivider(at: .right)
```

### Global Configuration

Set project-wide defaults:

```swift
@MainActor
func setupDividerDefaults() {
  var global = FKDividerConfiguration()
  global.color = .separator
  global.thickness = 1
  global.isPixelPerfect = true
  FKDividerManager.shared.defaultConfiguration = global
}
```

Per-instance override:

```swift
var local = FKDividerManager.shared.defaultConfiguration
local.lineStyle = .dashed
let divider = FKDivider(configuration: local)
```

### Interface Builder Usage

`FKDivider` is `@IBDesignable` and exposes `@IBInspectable` bridges:

- `ibDirection` (`0: horizontal`, `1: vertical`)
- `ibLineStyle` (`0: solid`, `1: dashed`)
- `ibThickness`
- `ibColor`
- `ibInsetLeft`, `ibInsetRight`, `ibInsetTop`, `ibInsetBottom`
- `ibPixelPerfect`
- `ibShowsGradient`
- `ibGradientStartColor`, `ibGradientEndColor`, `ibGradientDirection`
- `ibDashLength`, `ibDashGap`

You can drop a `UIView` in XIB/Storyboard, set its class to `FKDivider`, and configure these properties visually.

### SwiftUI Support

Use `FKDividerView` with the same configuration model:

```swift
import SwiftUI
import FKUIKit

struct DemoView: View {
  var body: some View {
    VStack(spacing: 20) {
      FKDividerView(
        configuration: .init(
          direction: .horizontal,
          lineStyle: .solid,
          color: .separator
        )
      )
      .frame(height: 1)

      FKDividerView(
        configuration: .init(
          direction: .horizontal,
          lineStyle: .dashed,
          dashPattern: [4, 2],
          showsGradient: true,
          gradientStartColor: .systemPink,
          gradientEndColor: .systemPurple
        )
      )
      .frame(height: 1)
    }
    .padding()
  }
}
```

## API Reference

Core types:

- `FKDivider`: UIKit divider view
- `FKDividerConfiguration`: full divider style/config model
- `FKDividerManager`: global default configuration manager
- `FKDividerView`: SwiftUI adapter view

Enums:

- `FKDividerDirection` (`horizontal`, `vertical`)
- `FKDividerLineStyle` (`solid`, `dashed`)
- `FKDividerGradientDirection` (`horizontal`, `vertical`)
- `FKDividerPinnedEdge` (`top`, `bottom`, `left`, `right`)

Key APIs:

- `FKDivider(configuration:)`
- `FKDivider.apply(configuration:)`
- `UIView.fk_addDivider(at:configuration:margin:)`
- `FKDividerManager.shared.defaultConfiguration`

## License

`FKDivider` is part of FKKit and is distributed under the MIT License.  
See [LICENSE](../../../../LICENSE).
