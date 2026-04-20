# FKStarRating

`FKStarRating` is a pure native Swift star rating component built with `UIKit` and `Foundation` only.
It is designed for production iOS apps, reusable list cells, and open-source UI libraries where performance and API simplicity both matter.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Supported Rating Modes](#supported-rating-modes)
  - [Full Star Rating](#full-star-rating)
  - [Half Star Rating](#half-star-rating)
  - [Precise Decimal Rating](#precise-decimal-rating)
- [Supported Styles](#supported-styles)
  - [Custom Image Mode (Selected/Unselected/Half)](#custom-image-mode-selectedunselectedhalf)
  - [Solid Color Rendering Mode](#solid-color-rendering-mode)
- [Requirements](#requirements)
- [Installation](#installation)
- [Basic Usage](#basic-usage)
  - [Create Star Rating with Code](#create-star-rating-with-code)
  - [Create Star Rating with XIB/Storyboard](#create-star-rating-with-xibstoryboard)
  - [Full Star Editable Rating](#full-star-editable-rating)
  - [Half Star Display Only Mode](#half-star-display-only-mode)
- [Advanced Usage](#advanced-usage)
  - [Custom Star Count/Size/Spacing](#custom-star-countsizespacing)
  - [Custom Images & Tint Colors](#custom-images--tint-colors)
  - [Slide & Tap Gesture Rating](#slide--tap-gesture-rating)
  - [Global Style Configuration](#global-style-configuration)
  - [Rating Callback Events](#rating-callback-events)
  - [Manual Set Rating Value](#manual-set-rating-value)
  - [List Cell Adaptation (TableView/CollectionView)](#list-cell-adaptation-tableviewcollectionview)
- [API Reference](#api-reference)
- [Performance Optimization](#performance-optimization)
- [Best Practices](#best-practices)
- [Notes](#notes)
- [License](#license)

## Overview

`FKStarRating` provides:

- 3 rating input modes: full, half, and precise decimal
- Interactive and display-only usage
- Tap and pan (slide) gestures for fast score input
- Dual rendering styles (image mode + solid color mode)
- Global defaults + per-instance overrides
- Reuse-safe API for `UITableViewCell` and `UICollectionViewCell`

It is implemented with lightweight view composition and no third-party dependencies.

## Features

- Pure native implementation (`Swift 5.9+`, `UIKit`, `Foundation`)
- iOS `13.0+` compatible component APIs
- Full star / half star / precise decimal rating
- Configurable star count (`1...10`)
- Configurable min/max rating clamp
- Read-only mode and editable mode
- Tap gesture rating and continuous slide rating
- Real-time callback (`onRatingChanged`) and final callback (`onRatingCommit`)
- Image rendering mode:
  - selected image
  - unselected image
  - optional half image
- Solid color rendering mode:
  - selected color
  - unselected color
- Custom star slot style:
  - corner radius
  - border width and color
  - shadow color/opacity/radius/offset
- Supports code, XIB, and Storyboard usage
- Built-in reset and reuse helpers

## Supported Rating Modes

### Full Star Rating

Use `.full` for integer-only ratings such as `1`, `2`, `3`, `4`, `5`.

```swift
ratingView.configure {
  $0.mode = .full
}
```

### Half Star Rating

Use `.half` for ratings like `3.5`.

```swift
ratingView.configure {
  $0.mode = .half
}
```

### Precise Decimal Rating

Use `.precise(step:)` for decimal scores with custom granularity (for example `0.1` step).

```swift
ratingView.configure {
  $0.mode = .precise(step: 0.1)
}
```

## Supported Styles

### Custom Image Mode (Selected/Unselected/Half)

Use your own local image assets for selected, unselected, and optional half stars.

```swift
ratingView.withImages(
  selected: UIImage(named: "star_selected"),
  unselected: UIImage(named: "star_unselected"),
  half: UIImage(named: "star_half")
)
```

### Solid Color Rendering Mode

Use template symbols or provided images with tint colors.

```swift
ratingView.withColors(
  selected: .systemYellow,
  unselected: .systemGray3
)
```

## Requirements

- Swift `5.9+`
- iOS `13.0+`
- `UIKit`
- `Foundation`
- No Objective-C dependency
- No third-party library dependency

## Installation

### Option 1: Swift Package Manager (Recommended)

Add FKKit to your project and import:

```swift
import FKUIKit
```

### Option 2: Source Integration

Copy `Sources/FKUIKit/Components/StarRating` into your project and include it in your app target.

## Basic Usage

### Create Star Rating with Code

```swift
import UIKit
import FKUIKit

let ratingView = FKStarRating()
ratingView.configure {
  $0.mode = .half
  $0.starCount = 5
  $0.starSpacing = 8
  $0.isEditable = true
}
ratingView.setRating(3.5)
```

### Create Star Rating with XIB/Storyboard

1. Drag a `UIView` into your layout.
2. Set custom class to `FKStarRating`.
3. Configure IB properties:
   - `fk_starCount`
   - `fk_starSpacing`
   - `fk_isEditable`
   - `fk_rating`

```swift
import UIKit
import FKUIKit

final class RatingDemoViewController: UIViewController {
  @IBOutlet private weak var ratingView: FKStarRating!

  override func viewDidLoad() {
    super.viewDidLoad()
    ratingView.configure {
      $0.mode = .half
    }
    ratingView.setRating(4.5)
  }
}
```

### Full Star Editable Rating

```swift
let ratingView = FKStarRating()
  .withMode(.full)
  .withEditable(true)
  .withRange(min: 1, max: 5)

ratingView.setRating(4)
```

### Half Star Display Only Mode

```swift
let ratingView = FKStarRating()
  .withMode(.half)
  .withEditable(false)

ratingView.setRating(3.5)
```

## Advanced Usage

### Custom Star Count/Size/Spacing

```swift
ratingView.configure {
  $0.starCount = 7
  $0.starSize = CGSize(width: 20, height: 20)
  $0.starSpacing = 6
  $0.minimumRating = 0
  $0.maximumRating = 7
}
```

### Custom Images & Tint Colors

```swift
// Image mode
ratingView.configure {
  $0.renderMode = .image
  $0.selectedImage = UIImage(named: "rating_selected")
  $0.unselectedImage = UIImage(named: "rating_unselected")
  $0.halfImage = UIImage(named: "rating_half")
}

// Color mode
ratingView.configure {
  $0.renderMode = .color
  $0.selectedColor = .systemOrange
  $0.unselectedColor = .systemGray4
}
```

### Slide & Tap Gesture Rating

`FKStarRating` supports:

- tap to set a score immediately
- pan (slide) to update score continuously

```swift
ratingView.configure {
  $0.isEditable = true
  $0.allowsContinuousPan = true
}
```

### Global Style Configuration

```swift
FKStarRating.defaultConfiguration = .build {
  $0.mode = .half
  $0.starCount = 5
  $0.starSize = CGSize(width: 22, height: 22)
  $0.starSpacing = 6
  $0.selectedColor = .systemYellow
  $0.unselectedColor = .systemGray4
}

// New instances now use this configuration by default.
let ratingView = FKStarRating()
```

### Rating Callback Events

```swift
ratingView.onRatingChanged = { value in
  print("Real-time rating:", value)
}

ratingView.onRatingCommit = { value in
  print("Final rating:", value)
}

ratingView.addTarget(self, action: #selector(ratingDidChange(_:)), for: .valueChanged)

@objc
private func ratingDidChange(_ sender: FKStarRating) {
  print("UIControl valueChanged:", sender.rating)
}
```

### Manual Set Rating Value

```swift
ratingView.setRating(2.7)              // snapped by current mode
ratingView.setRating(4.5, animated: true)
ratingView.resetRating()               // reset to minimumRating
ratingView.resetStyle()                // reset to global default configuration
```

### List Cell Adaptation (TableView/CollectionView)

Use `prepareForReuse()` in reusable cells to avoid stale callbacks/state.

```swift
final class ProductRatingCell: UITableViewCell {
  @IBOutlet private weak var ratingView: FKStarRating!

  override func prepareForReuse() {
    super.prepareForReuse()
    ratingView.prepareForReuse()
  }

  func bind(score: CGFloat, editable: Bool) {
    ratingView.configure {
      $0.isEditable = editable
      $0.mode = .half
    }
    ratingView.setRating(score, animated: false, notify: false)
  }
}
```

The same pattern applies to `UICollectionViewCell`.

## API Reference

Primary types:

- `FKStarRating`
- `FKStarRatingConfiguration`
- `FKStarRatingMode`
- `FKStarRatingRenderMode`
- `FKStarRatingStarStyle`
- `FKStarRatingManager`

Core APIs:

- `configure(_:)`
- `setRating(_:animated:notify:)`
- `resetRating()`
- `resetStyle()`
- `prepareForReuse()`
- `onRatingChanged`
- `onRatingCommit`
- `defaultConfiguration`

Fluent APIs:

- `withMode(_:)`
- `withStarCount(_:)`
- `withRange(min:max:)`
- `withEditable(_:)`
- `withColors(selected:unselected:)`
- `withImages(selected:unselected:half:)`

Interface Builder APIs:

- `fk_starCount`
- `fk_starSpacing`
- `fk_isEditable`
- `fk_rating`

## Performance Optimization

`FKStarRating` is optimized for commercial iOS workloads:

- Reuses lightweight star subviews
- Uses layer masking for decimal fill instead of heavy custom drawing
- Supports efficient list reuse with `prepareForReuse()`
- Uses direct gesture-to-value mapping for responsive interaction
- Avoids third-party rendering and gesture abstraction overhead
- Designed for main-thread-safe UI updates

## Best Practices

- Set global defaults once (app launch), then override only where needed.
- Keep `onRatingChanged` logic lightweight; offload heavy work asynchronously.
- In reusable cells, always reset callbacks/state in `prepareForReuse()`.
- For display-only scenes (feeds/detail headers), set `isEditable = false`.
- For product/business rules, define explicit `minimumRating` and `maximumRating`.
- Prefer `.half` for typical review systems; use `.precise(step:)` only when needed.

## Notes

- `FKStarRating` is a UI component and should be used on the main thread.
- In `.color` mode, default SF Symbol stars are used if custom images are not provided.
- `onRatingCommit` is emitted at gesture end (tap end or pan end).
- If `minimumRating` is greater than `0`, reset behavior returns that minimum value.
- The component is UIKit-native and safe for both iPhone and iPad layouts.

## License

`FKStarRating` is part of FKKit and is available under the [MIT License](../../../../LICENSE).
