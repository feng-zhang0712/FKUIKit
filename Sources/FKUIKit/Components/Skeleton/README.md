# FKSkeleton

FKSkeleton is a lightweight, pure-native Swift skeleton loading component for UIKit apps.  
It is designed for production iOS projects and open-source distribution, with zero third-party dependencies and a clean API for both quick integration and advanced customization.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Supported Views & Components](#supported-views--components)
- [Skeleton Animation Types](#skeleton-animation-types)
- [Requirements](#requirements)
- [Installation](#installation)
- [Basic Usage](#basic-usage)
  - [Show/Hide Skeleton on UIView](#showhide-skeleton-on-uiview)
  - [Skeleton for UILabel/UIImageView/UIButton](#skeleton-for-uilabeluiimageviewuibutton)
  - [Skeleton for UITableViewCell/UICollectionViewCell](#skeleton-for-uitableviewcelluicollectionviewcell)
  - [Skeleton for UIStackView](#skeleton-for-uistackview)
- [Advanced Usage](#advanced-usage)
  - [Custom Colors & Animations](#custom-colors--animations)
  - [Global Style Configuration](#global-style-configuration)
  - [Adjust Corner Radius & Shape](#adjust-corner-radius--shape)
  - [Exclude Specific Views from Skeleton](#exclude-specific-views-from-skeleton)
  - [Manual Control Skeleton State](#manual-control-skeleton-state)
- [API Reference](#api-reference)
- [Best Practices](#best-practices)
- [Performance Optimization](#performance-optimization)
- [Notes](#notes)
- [License](#license)

## Overview

FKSkeleton provides two complementary rendering modes:

1. **Overlay mode** (`fk_showSkeleton`) for fast, non-intrusive placeholders on any `UIView`.
2. **Auto-generation mode** (`fk_showAutoSkeleton`) that scans the view hierarchy and generates skeleton placeholders for supported UIKit views.

It also includes composable building blocks (`FKSkeletonView`, `FKSkeletonContainerView`, presets, and reusable list cells) to support complex UI designs in large-scale iOS applications.

## Features

- Pure Swift 5.9+ implementation based on UIKit/Foundation.
- iOS 13+ support.
- No Objective-C dependency and no third-party dependency.
- One-line APIs to show/hide skeleton loading states.
- Automatic skeleton generation for common UIKit controls.
- Fill, shimmer, and pulse animation styles.
- Global style defaults and per-view overrides.
- Shape customization (rectangle, rounded, circle, custom radius).
- Exclusion support for specific subviews.
- Reuse-friendly table/collection integrations.
- Main-thread-safe show/hide operations.

## Supported Views & Components

FKSkeleton currently supports:

- **Base views:** `UIView`, `UILabel`, `UIImageView`, `UIButton`, `UITextField`
- **Containers:** `UIStackView` (arranged subviews are recursively processed)
- **List contexts:** `UITableViewCell`, `UICollectionViewCell` (via `contentView`)
- **Reusable skeleton cells:** `FKSkeletonTableViewCell`, `FKSkeletonCollectionViewCell`
- **Composable skeleton layout:** `FKSkeletonContainerView` + `FKSkeletonView`
- **Preset layouts:** `FKSkeletonPresets` (list row, card, text block, grid cell)

## Skeleton Animation Types

FKSkeleton exposes `FKSkeletonAnimationMode`:

- `.none` — static fill skeleton
- `.shimmer` — moving gradient shimmer
- `.pulse` — opacity pulse animation
- `.breathing` — compatibility alias to pulse-style behavior

You can also use semantic style mapping through `FKSkeletonStyle`:

- `.solid` -> `.none`
- `.gradient` -> `.shimmer`
- `.pulse` -> `.pulse`

## Requirements

- iOS 13.0+
- Swift 5.9+
- UIKit/Foundation based project

## Installation

FKSkeleton is part of `FKUIKit` in this repository.

1. Add this package/repository to your project (Swift Package Manager or your internal dependency workflow).
2. Import FKUIKit where needed:

```swift
import FKUIKit
```

## Basic Usage

### Show/Hide Skeleton on UIView

Use overlay mode for quick integration without changing your view hierarchy:

```swift
import FKUIKit

final class DemoViewController: UIViewController {
  @IBOutlet private weak var cardView: UIView!

  func startLoading() {
    cardView.fk_showSkeleton(animated: true)
  }

  func finishLoading() {
    cardView.fk_hideSkeleton(animated: true)
  }
}
```

### Skeleton for UILabel/UIImageView/UIButton

Use auto-generation mode for supported UIKit controls:

```swift
titleLabel.fk_showAutoSkeleton()
avatarImageView.fk_showAutoSkeleton()
actionButton.fk_showAutoSkeleton()

// hide later
titleLabel.fk_hideAutoSkeleton()
avatarImageView.fk_hideAutoSkeleton()
actionButton.fk_hideAutoSkeleton()
```

Convenience helpers are also available:

```swift
titleLabel.fk_showSkeletonLabel()
avatarImageView.fk_showSkeletonImage()
actionButton.fk_showSkeletonButton()
```

### Skeleton for UITableViewCell/UICollectionViewCell

#### Option A: Skeleton on visible real cells

```swift
tableView.fk_showAutoSkeletonOnVisibleCells()
// ... data arrives
tableView.fk_hideAutoSkeletonOnVisibleCells()
```

```swift
collectionView.fk_showAutoSkeletonOnVisibleCells()
// ... data arrives
collectionView.fk_hideAutoSkeletonOnVisibleCells()
```

#### Option B: Dedicated skeleton reusable cells

```swift
tableView.register(FKSkeletonTableViewCell.self, forCellReuseIdentifier: "skeleton.cell")
collectionView.register(FKSkeletonCollectionViewCell.self, forCellWithReuseIdentifier: "skeleton.item")
```

Then configure placeholders in each skeleton cell via `skeletonContainer`.

### Skeleton for UIStackView

Auto mode supports stack views and traverses arranged subviews:

```swift
let options = FKSkeletonDisplayOptions(blocksInteraction: true, hidesTargetView: true)
stackView.fk_showAutoSkeleton(options: options)

// hide when loading finishes
stackView.fk_hideAutoSkeleton()
```

## Advanced Usage

### Custom Colors & Animations

Customize color palette, gradient, duration, and animation style:

```swift
let custom = FKSkeletonConfiguration(
  baseColor: UIColor.systemGray5,
  highlightColor: UIColor.white.withAlphaComponent(0.75),
  gradientColors: [
    UIColor.systemGray5,
    UIColor.white.withAlphaComponent(0.85),
    UIColor.systemGray5
  ],
  animationDuration: 1.1,
  animationMode: .shimmer
)

contentView.fk_showAutoSkeleton(configuration: custom)
```

### Global Style Configuration

Set global defaults once:

```swift
FKSkeleton.defaultConfiguration = FKSkeletonConfiguration(
  cornerRadius: 8,
  borderWidth: 0.5,
  animationDuration: 1.2,
  animationMode: .pulse
)
```

All skeleton APIs use this configuration unless overridden per call/view.

### Adjust Corner Radius & Shape

Use per-view shape override:

```swift
avatarImageView.fk_skeletonShape = .circle
titleLabel.fk_skeletonShape = .custom(6)
separatorView.fk_skeletonShape = .rectangle
```

Use global radius behavior through configuration:

```swift
FKSkeleton.defaultConfiguration = FKSkeletonConfiguration(
  cornerRadius: 10,
  inheritsCornerRadius: false
)
```

### Exclude Specific Views from Skeleton

Exclude by view flag:

```swift
badgeView.fk_isSkeletonExcluded = true
```

Or exclude via show options:

```swift
rootView.fk_showAutoSkeleton(
  options: FKSkeletonDisplayOptions(excludedViews: [badgeView, iconView])
)
```

### Manual Control Skeleton State

One-line state switching:

```swift
rootView.fk_setSkeletonLoading(true)
// ...
rootView.fk_setSkeletonLoading(false)
```

Wrap asynchronous loading:

```swift
rootView.fk_withSkeletonLoading { done in
  api.fetchData { _ in
    done() // hides skeleton only for the latest request token
  }
}
```

## API Reference

Core entry points:

- `FKSkeleton.defaultConfiguration`
- `FKSkeletonConfiguration`
- `FKSkeletonAnimationMode`
- `FKSkeletonStyle`
- `FKSkeletonShape`
- `FKSkeletonDisplayOptions`

UIView extension:

- `fk_showSkeleton(...)`
- `fk_hideSkeleton(...)`
- `fk_showAutoSkeleton(...)`
- `fk_hideAutoSkeleton(...)`
- `fk_setSkeletonLoading(...)`
- `fk_withSkeletonLoading(...)`

Per-view customization:

- `fk_skeletonConfigurationOverride`
- `fk_skeletonShape`
- `fk_isSkeletonExcluded`

List helpers:

- `UITableView.fk_showSkeletonOnVisibleCells(...)`
- `UITableView.fk_hideSkeletonOnVisibleCells(...)`
- `UITableView.fk_showAutoSkeletonOnVisibleCells(...)`
- `UITableView.fk_hideAutoSkeletonOnVisibleCells(...)`
- `UICollectionView.fk_showSkeletonOnVisibleCells(...)`
- `UICollectionView.fk_hideSkeletonOnVisibleCells(...)`
- `UICollectionView.fk_showAutoSkeletonOnVisibleCells(...)`
- `UICollectionView.fk_hideAutoSkeletonOnVisibleCells(...)`

Composable UI:

- `FKSkeletonView`
- `FKSkeletonContainerView`
- `FKSkeletonPresets`
- `FKSkeletonTableViewCell`
- `FKSkeletonCollectionViewCell`

## Best Practices

- Prefer **auto mode** for rapid integration on existing screens.
- Prefer **container + presets** for deterministic skeleton layouts in design-critical pages.
- Keep skeleton structure close to real UI structure to reduce layout jumps.
- Use per-view exclusion for badges/icons that should remain visible.
- Hide skeleton before heavy data-driven animation transitions.

## Performance Optimization

- Use `FKSkeletonContainerView` with `usesUnifiedShimmer = true` for complex cards/lists.
- Avoid showing skeletons on deeply nested off-screen view trees.
- For table/collection loading, use visible cell helpers or dedicated skeleton cells.
- Reuse prebuilt preset layouts where possible.
- Keep animation duration in a reasonable range (typically 1.0–1.6s).

## Notes

- All public show/hide APIs are main-thread safe.
- Overlay mode and auto-generation mode can coexist, but avoid stacking both on the same target view.
- On full-screen roots, use `respectsSafeArea: true` in overlay mode to avoid covering system areas.
- This README reflects the current implementation in `Sources/FKUIKit/Components/Skeleton`.

## License

This project is licensed under the repository license.  
See the root [`LICENSE`](../../../LICENSE) file for details.
