# FKCornerShadow

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [High Performance Advantages (No Offscreen Rendering)](#high-performance-advantages-no-offscreen-rendering)
- [Supported Views](#supported-views)
- [Requirements](#requirements)
- [Installation](#installation)
- [Basic Usage](#basic-usage)
  - [Add Any Corner Radius](#add-any-corner-radius)
  - [Add High Performance Shadow](#add-high-performance-shadow)
  - [Corner + Shadow Combination](#corner--shadow-combination)
  - [Add Border & Gradient](#add-border--gradient)
- [Advanced Usage](#advanced-usage)
  - [Custom Shadow (Color/Offset/Blur/Spread)](#custom-shadow-coloroffsetblurspread)
  - [Multi-Corners Independent Settings](#multi-corners-independent-settings)
  - [Global Style Configuration](#global-style-configuration)
  - [Auto Layout Adaptation](#auto-layout-adaptation)
  - [Reset Style](#reset-style)
- [API Reference](#api-reference)
- [Performance Optimization](#performance-optimization)
- [Best Practices](#best-practices)
- [Notes](#notes)
- [License](#license)

## Overview
`FKCornerShadow` is a pure native Swift component for arbitrary corner radius and high-performance shadow rendering in UIKit.

It is designed for large iOS codebases where smooth scrolling and reusable cells are critical. The component provides:
- one-line application of corner + border + shadow styles,
- protocol-oriented and non-invasive APIs,
- global style templates with per-view overrides,
- automatic updates when view bounds change.

No third-party dependencies are required. Only `UIKit`, `Foundation`, and `CoreGraphics` APIs are used.

## Features
- Pure native Swift implementation (`Swift 5.9+` API style, iOS 13+ compatibility target).
- Arbitrary corner control with `UIRectCorner` (`single`, `multiple`, or `all` corners).
- Rounded path + border path synchronization (solid or gradient border).
- High-performance shadow based on explicit `shadowPath`.
- Side-specific shadow support (`top`, `left`, `bottom`, `right`, and combinations).
- Gradient fill + corner + shadow composition.
- Global default style via `FKCornerShadowManager`.
- Per-view style override through lightweight `UIView` extension APIs.
- Built for reusable list scenes (`UITableViewCell` / `UICollectionViewCell`) with reset APIs.

## High Performance Advantages (No Offscreen Rendering)
`FKCornerShadow` is optimized around explicit path rendering:

- **Corner rendering:** uses `UIBezierPath` + `CAShapeLayer` mask and updates only when bounds change.
- **Shadow rendering:** uses `CALayer.shadowPath` / side shadow carrier layers with explicit paths.
- **No dynamic blur path guessing:** avoids expensive implicit shadow calculations.
- **Auto-layout friendly:** swizzled layout refresh updates paths after size changes, preventing repeated manual recalculation.
- **Reusable-cell friendly:** style reset APIs prevent stale layers and duplicated effects in fast scrolling.

In practical list-heavy interfaces, this approach significantly reduces frame drops compared with default implicit shadow rendering.

## Supported Views
`FKCornerShadow` is implemented on `UIView` extension APIs, so it works with:

- `UIView`
- `UIButton`
- `UILabel`
- `UIImageView`
- `UIScrollView`
- `UITableViewCell` (`contentView` recommended)
- `UICollectionViewCell` (`contentView` recommended)
- Any custom `UIView` subclass

## Requirements
- iOS 13.0+
- Swift 5.9+
- UIKit / Foundation / CoreGraphics
- No Objective-C dependency
- No third-party library dependency

## Installation
Add `FKUIKit` via Swift Package Manager.

### Xcode
1. Open **File** -> **Add Package Dependencies...**
2. Enter repository URL:
   - `https://github.com/feng-zhang0712/FKKit.git`
3. Select product:
   - `FKUIKit`

### Package.swift
```swift
dependencies: [
  .package(url: "https://github.com/feng-zhang0712/FKKit.git", from: "0.22.0")
],
targets: [
  .target(
    name: "YourTarget",
    dependencies: [
      .product(name: "FKUIKit", package: "FKKit")
    ]
  )
]
```

## Basic Usage

### Add Any Corner Radius
```swift
import UIKit
import FKUIKit

profileContainer.fk_applyCornerShadow(
  corners: [.topLeft, .bottomRight],
  cornerRadius: 16,
  fillColor: .systemBackground
)
```

### Add High Performance Shadow
```swift
avatarView.fk_setShadow(
  color: .black,
  opacity: 0.16,
  offset: CGSize(width: 0, height: 6),
  blur: 14,
  spread: 0,
  sides: .all
)
```

### Corner + Shadow Combination
```swift
let style = FKCornerShadowStyle(
  corners: [.topLeft, .topRight],
  cornerRadius: 18,
  fillColor: .secondarySystemBackground,
  shadow: FKCornerShadowShadow(
    color: .black,
    opacity: 0.14,
    offset: CGSize(width: 0, height: 5),
    blur: 12,
    spread: 0,
    sides: [.bottom]
  )
)

cardView.fk_applyCornerShadow(style)
```

### Add Border & Gradient
```swift
let fillGradient = FKCornerShadowGradient(
  colors: [.systemPurple, .systemBlue],
  startPoint: CGPoint(x: 0, y: 0),
  endPoint: CGPoint(x: 1, y: 1)
)

let borderGradient = FKCornerShadowGradient(
  colors: [.white.withAlphaComponent(0.9), .white.withAlphaComponent(0.2)],
  startPoint: CGPoint(x: 0, y: 0.5),
  endPoint: CGPoint(x: 1, y: 0.5)
)

let style = FKCornerShadowStyle(
  corners: .allCorners,
  cornerRadius: 20,
  fillGradient: fillGradient,
  border: .gradient(gradient: borderGradient, width: 1.5)
)

bannerView.fk_applyCornerShadow(style)
```

## Advanced Usage

### Custom Shadow (Color/Offset/Blur/Spread)
```swift
let customShadow = FKCornerShadowShadow(
  color: UIColor(red: 0, green: 0, blue: 0, alpha: 1),
  opacity: 0.22,
  offset: CGSize(width: 2, height: 10),
  blur: 18,
  spread: 4,
  sides: [.bottom, .right]
)

var style = FKCornerShadowStyle.none
style.cornerRadius = 14
style.corners = .allCorners
style.fillColor = .systemBackground
style.shadow = customShadow

floatingPanel.fk_applyCornerShadow(style)
```

### Multi-Corners Independent Settings
```swift
var style = FKCornerShadowStyle.none
style.corners = [.topLeft, .bottomLeft, .bottomRight]
style.cornerRadius = 24
style.fillColor = .systemTeal

shapeView.fk_applyCornerShadow(style)
```

### Global Style Configuration
```swift
FKCornerShadowManager.shared.configureDefaultStyle { style in
  style.corners = .allCorners
  style.cornerRadius = 12
  style.fillColor = .secondarySystemBackground
  style.border = .solid(color: .separator, width: 0.5)
  style.shadow = FKCornerShadowShadow(
    color: .black,
    opacity: 0.12,
    offset: CGSize(width: 0, height: 4),
    blur: 10,
    spread: 0,
    sides: .all
  )
}

// One-line application from global template.
titleLabel.fk_applyCornerShadowFromGlobal()

// Override part of global style locally.
subtitleLabel.fk_applyCornerShadowFromGlobal { style in
  style.corners = [.topLeft, .topRight]
  style.cornerRadius = 10
}
```

### Auto Layout Adaptation
`FKCornerShadow` updates rendering paths when the view’s bounds change during Auto Layout.
No manual path recalculation is required in common cases.

```swift
override func viewDidLayoutSubviews() {
  super.viewDidLayoutSubviews()
  // Usually not required, but safe to re-apply style after major layout transitions.
  // cardView.fk_applyCornerShadowFromGlobal()
}
```

### Reset Style
```swift
// Full reset
cell.contentView.fk_resetCornerShadow()

// Partial reset
cell.contentView.fk_resetShadow()
cell.contentView.fk_resetBorder()
cell.contentView.fk_resetCorners()

override func prepareForReuse() {
  super.prepareForReuse()
  contentView.fk_resetCornerShadow()
}
```

## API Reference
### Core Models
- `FKCornerShadowStyle`
- `FKCornerShadowShadow`
- `FKCornerShadowBorder`
- `FKCornerShadowGradient`
- `FKCornerShadowSide`

### Global Configuration
- `FKCornerShadowManager.shared.defaultStyle`
- `FKCornerShadowManager.shared.configureDefaultStyle(_:)`
- `FKCornerShadowManager.shared.resetDefaultStyle()`

### UIView Extension APIs
- `fk_applyCornerShadow(_ style: FKCornerShadowStyle)`
- `fk_applyCornerShadow(corners:cornerRadius:fillColor:fillGradient:border:shadow:)`
- `fk_applyCornerShadowFromGlobal(configure:)`
- `fk_setCorners(_:radius:fillColor:)`
- `fk_setShadow(color:opacity:offset:blur:spread:sides:)`
- `fk_setBorder(_:)`
- `fk_resetCornerShadow()`
- `fk_resetCorners()`
- `fk_resetShadow()`
- `fk_resetBorder()`
- `fk_cornerShadowCurrentStyle`

## Performance Optimization
- Prefer `fk_applyCornerShadow(_:)` with a prebuilt style object in hot paths.
- For list reuse, always call `fk_resetCornerShadow()` in `prepareForReuse()`.
- Avoid applying styles repeatedly before the final layout pass in complex animations.
- Use side-specific shadows only when needed; `.all` is cheaper because it uses host-layer `shadowPath`.
- Keep gradient layer counts minimal on deeply nested reusable views.

## Best Practices
- Apply style on container views rather than heavily nested leaf views whenever possible.
- For `UITableViewCell` and `UICollectionViewCell`, style `contentView` to avoid clipping surprises.
- Use global style as baseline, then override only the properties needed per screen.
- Keep corner radius and shadow settings consistent across design systems for better cache locality and UI coherence.
- If a view has very frequent size changes, avoid unnecessary repeated style mutation.

## Notes
- All public APIs are expected to run on the main thread.
- The current package platform declaration may differ from component-level compatibility notes in this README.
- `FKCornerShadow` is non-invasive and does not require subclassing existing UIKit views.

## License
`FKCornerShadow` is distributed under the same license as this repository. See [LICENSE](../../../LICENSE).
```
