# FKBadge

`FKBadge` is a native Swift badge component for UIKit apps. It provides red dots, numeric badges, and text badges with flexible styling, animation, and positioning, while keeping your original view hierarchy and constraints intact.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Supported Views](#supported-views)
- [Badge Types](#badge-types)
- [Requirements](#requirements)
- [Installation](#installation)
  - [Swift Package Manager](#swift-package-manager)
- [Basic Usage](#basic-usage)
  - [Red Dot Badge](#red-dot-badge)
  - [Number Badge](#number-badge)
  - [Text Badge](#text-badge)
  - [TabBar Item Badge](#tabbar-item-badge)
  - [Navigation Bar Item Badge](#navigation-bar-item-badge)
- [Advanced Usage](#advanced-usage)
  - [Custom Style (Color, Font, Corner, Border)](#custom-style-color-font-corner-border)
  - [Position & Offset Adjustment](#position--offset-adjustment)
  - [Animation Effects](#animation-effects)
  - [Global Style Configuration](#global-style-configuration)
  - [Update/Remove/Hide Badge](#updateremovehide-badge)
- [API Reference](#api-reference)
  - [Core Types](#core-types)
  - [Main APIs](#main-apis)
  - [`FKBadgeController` Highlights](#fkbadgecontroller-highlights)
- [Best Practices](#best-practices)
- [Notes](#notes)
- [License](#license)

## Overview

The component is designed for large-scale iOS projects:

- Pure UIKit/Foundation implementation
- No third-party dependencies
- Non-intrusive overlay architecture
- One-line APIs for show/update/hide/remove
- Global style management with per-instance overrides

## Features

- Dot badge (no text)
- Number badge with overflow formatting (`99+`, `999+`, etc.)
- Text badge (`NEW`, `Hot`, custom strings)
- Adaptive badge width based on content
- Supports `UIView`, `UIButton`, `UILabel`, `UIImageView`
- Supports `UIBarButtonItem` and `UITabBarItem`
- Custom colors, font, corner radius, border, padding, kerning, size
- Anchor + offset positioning (`topLeading`, `topTrailing`, `bottomLeading`, `bottomTrailing`)
- Fade-in display, plus `pop`, `blink`, and `pulse` animations
- Tap callback support on badge
- Global hide/restore for all active badges
- Main-thread-safe APIs and weak references to avoid leaks

## Supported Views

`FKBadge` can be attached to:

- `UIView` and any subclass
- `UIButton`
- `UILabel`
- `UIImageView`
- `UIBarButtonItem` (custom and system items via host view resolution)
- `UITabBarItem` (custom overlay badge + native `badgeValue` helper)

## Badge Types

- **Red Dot Badge**: visual reminder without text
- **Number Badge**: integer display with max value truncation
- **Text Badge**: custom string display
- **Overflow Badge**: configurable suffix-based overflow (`maxDisplayCount + overflowSuffix`)

## Requirements

- Swift 5.9+
- UIKit / Foundation
- iOS 15+ in the current `FKUIKit` package setup

> Note: The badge implementation itself is UIKit-based and does not depend on Objective-C wrappers or third-party frameworks.

## Installation

### Swift Package Manager

Add `FKKit` as a dependency and use the `FKUIKit` product.

```swift
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
```

Then import:

```swift
import FKUIKit
```

## Basic Usage

### Red Dot Badge

```swift
import UIKit
import FKUIKit

final class DemoViewController: UIViewController {
  @IBOutlet private weak var iconView: UIImageView!

  override func viewDidLoad() {
    super.viewDidLoad()
    iconView.fk_showBadgeDot(animated: true, animation: .pop())
  }
}
```

### Number Badge

```swift
button.fk_showBadgeCount(12, animated: true)

// Alternative API on controller
button.fk_badge.showCount(128, animated: true, animation: .pulse())
```

### Text Badge

```swift
label.fk_showBadgeText("NEW", animated: true, animation: .pop())
```

### TabBar Item Badge

```swift
if let item = tabBarController?.tabBar.items?[0] {
  // Native badgeValue formatting helper
  item.fk_setBadgeCount(120, maxDisplay: 99, overflowSuffix: "+") // shows "99+"

  // Custom overlay badge (dot/number/text)
  item.fk_showBadgeText("Hot", animated: true, animation: .blink())
}
```

### Navigation Bar Item Badge

```swift
let bellItem = UIBarButtonItem(
  image: UIImage(systemName: "bell"),
  style: .plain,
  target: self,
  action: #selector(onBellTap)
)
navigationItem.rightBarButtonItem = bellItem

bellItem.fk_showBadgeCount(8, animated: true, animation: .pop())
```

## Advanced Usage

### Custom Style (Color, Font, Corner, Border)

```swift
var style = FKBadgeConfiguration()
style.backgroundColor = .systemBlue
style.titleColor = .white
style.font = .systemFont(ofSize: 10, weight: .bold)
style.borderWidth = 1
style.borderColor = .white
style.textCornerRadius = 9
style.horizontalPadding = 6
style.verticalPadding = 2
style.textKerning = 0.2
style.dotDiameter = 10
style.maxDisplayCount = 999
style.overflowSuffix = "+"

avatarImageView.fk_badge.configuration = style
avatarImageView.fk_showBadgeCount(1350, animated: true) // shows "999+"
```

### Position & Offset Adjustment

```swift
avatarImageView.fk_badge.setAnchor(.topTrailing, offset: UIOffset(horizontal: 8, vertical: -6))

// Other anchors:
// .topLeading, .bottomLeading, .bottomTrailing
```

### Animation Effects

```swift
// Entrance animation when showing
messageButton.fk_showBadgeCount(3, animated: true, animation: .pop())

// Repeating effects
messageButton.fk_badge.playAnimation(.blink(minAlpha: 0.4, maxAlpha: 1.0, duration: 0.6))
messageButton.fk_badge.playAnimation(.pulse(scale: 1.15, duration: 0.8))
```

### Global Style Configuration

```swift
@MainActor
func configureBadgeTheme() {
  var global = FKBadgeConfiguration()
  global.backgroundColor = .systemRed
  global.titleColor = .white
  global.maxDisplayCount = 99

  FKBadgeManager.shared.defaultConfiguration = global
}
```

```swift
@MainActor
func toggleAllBadges(hidden: Bool) {
  if hidden {
    FKBadgeManager.shared.hideAll(animated: true)
  } else {
    FKBadgeManager.shared.restoreAll(animated: true)
  }
}
```

### Update/Remove/Hide Badge

```swift
// Update count
inboxView.fk_badge.updateCount(42, animated: true, animation: .pop())

// Clear current content (hide badge)
inboxView.fk_hideBadge(animated: true)

// Force hidden / restore automatic rule
inboxView.fk_badge.setHidden(true, animated: true)
inboxView.fk_badge.setHidden(false, animated: true)

// Clear count by setting zero semantics
inboxView.fk_badge.clearCount(animated: true)

// Fully remove controller association from target
inboxView.fk_badge.removeFromTarget()
```

Tap callback:

```swift
inboxView.fk_badge.onTap = { [weak self] badge in
  guard let self else { return }
  print("Badge tapped on: \(String(describing: badge.targetView))")
}
```

## API Reference

### Core Types

- `FKBadgeController`
- `FKBadgeConfiguration`
- `FKBadgeAnimation`
- `FKBadgeAnchor`
- `FKBadgeVisibilityPolicy`
- `FKBadgeManager`

### Main APIs

- `UIView.fk_badge`
- `UIView.fk_showBadgeDot(...)`
- `UIView.fk_showBadgeCount(...)`
- `UIView.fk_showBadgeText(...)`
- `UIView.fk_hideBadge(...)`

- `UIBarButtonItem.fk_badge`
- `UIBarButtonItem.fk_showBadgeDot(...)`
- `UIBarButtonItem.fk_showBadgeCount(...)`
- `UIBarButtonItem.fk_showBadgeText(...)`
- `UIBarButtonItem.fk_hideBadge(...)`

- `UITabBarItem.fk_badge`
- `UITabBarItem.fk_setBadgeCount(...)`
- `UITabBarItem.fk_showBadgeDot(...)`
- `UITabBarItem.fk_showBadgeCount(...)`
- `UITabBarItem.fk_showBadgeText(...)`
- `UITabBarItem.fk_hideBadge(...)`

### `FKBadgeController` Highlights

- Content:
  - `showDot(animated:animation:)`
  - `showCount(_:animated:animation:)`
  - `showText(_:animated:animation:)`
  - `showCountString(_:animated:animation:)`
  - `clear(animated:)`
- Visibility:
  - `visibilityPolicy`
  - `setHidden(_:animated:)`
  - `isEffectivelyHidden`
- Layout:
  - `anchor`
  - `offset`
  - `setAnchor(_:offset:)`
  - `reattachIfNeeded()`
- Update/Lifecycle:
  - `updateCount(_:animated:animation:)`
  - `clearCount(animated:)`
  - `removeFromTarget()`
- Interaction/Animation:
  - `onTap`
  - `playAnimation(_:)`

## Best Practices

- Access badge APIs on the main actor when updating UIKit.
- Configure global style at app launch, then apply per-view overrides only when needed.
- Prefer one-line extension APIs for common flows and `fk_badge` for advanced control.
- Use `maxDisplayCount` and `overflowSuffix` for server-driven large counts.
- Keep `onTap` closures weak-captured to avoid retain cycles.
- Use `fk_setBadgeCount` for native TabBar badge style; use overlay APIs for advanced custom UI.

## Notes

- `FKBadge` is attached as a sibling view of the target view, not as a subview of the target.
- Existing constraints/layout of the target view are preserved.
- Empty text is treated as a dot badge.
- Numeric values `<= 0` are hidden under automatic visibility policy.
- `UIBarButtonItem` and `UITabBarItem` overlay badges rely on UIKit host view availability.
- RTL-safe anchors are supported through leading/trailing semantics.

## License

`FKBadge` is part of the FKKit project and is distributed under the same license as this repository.
