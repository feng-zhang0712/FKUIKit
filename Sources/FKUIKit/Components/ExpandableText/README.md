# FKExpandableText

`FKExpandableText` is a pure UIKit expandable/collapsible long-text component for production iOS apps.
It is designed for social feeds, comments, news cards, and any high-reuse list scene that needs smooth "Read more" behavior.

The component is implemented with `Swift 5.9+` and native `UIKit`/`Foundation` APIs only.
No Objective-C bridge and no third-party dependency are required.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Supported Scenarios](#supported-scenarios)
  - [Normal Text Expand/Collapse](#normal-text-expandcollapse)
  - [Attributed Text Support](#attributed-text-support)
  - [UITableViewCell & UICollectionViewCell Adaptation](#uitableviewcell--uicollectionviewcell-adaptation)
  - [Auto Hide Button For Short Text](#auto-hide-button-for-short-text)
- [Requirements](#requirements)
- [Installation](#installation)
- [Basic Usage](#basic-usage)
  - [Create Expandable Text with Code](#create-expandable-text-with-code)
  - [Create Expandable Text with XIB](#create-expandable-text-with-xib)
  - [Set Max Collapsed Lines](#set-max-collapsed-lines)
  - [Expand/Collapse Animation](#expandcollapse-animation)
- [Advanced Usage](#advanced-usage)
  - [Custom Text Style (Font/Color/Line Spacing)](#custom-text-style-fontcolorline-spacing)
  - [Custom Expand/Collapse Button Text & Style](#custom-expandcollapse-button-text--style)
  - [Global Style Configuration](#global-style-configuration)
  - [State Cache for List Reuse](#state-cache-for-list-reuse)
  - [Expand/Collapse Callback Events](#expandcollapse-callback-events)
  - [Manual Control Expand State](#manual-control-expand-state)
- [API Reference](#api-reference)
- [Performance Optimization](#performance-optimization)
- [Best Practices](#best-practices)
- [Notes](#notes)
- [License](#license)

## Overview

`FKExpandableText` wraps a `UILabel` and provides:

- Automatic collapsed/expanded presentation for long text
- Configurable collapsed line count
- Built-in "Read more / Collapse" button behavior
- Rich text (`NSAttributedString`) rendering
- Reuse-safe state management for table/collection cells
- Height pre-calculation for smooth scrolling performance

The API is intentionally lightweight and suitable for both standalone usage and large-scale component libraries.

## Features

- Pure native Swift implementation (`UIKit` + `Foundation` only)
- iOS `13.0+` compatibility
- Supports plain text and attributed text
- Configurable collapsed line count (`3`, `5`, or any custom value)
- Auto hide action button when content does not exceed collapsed lines
- Smooth animated expand/collapse transition
- Flexible button style:
  - custom title text
  - custom color / highlighted color / font
  - optional icon + text combination
- Flexible button layout:
  - `.tailFollow`
  - `.bottomTrailing`
- Configurable text style:
  - font, color, alignment
  - line spacing and kern
- Trigger control:
  - button tap
  - text tap
  - both
- Reuse-friendly state cache with stable identifier
- Height pre-calculation API with optional cache key
- Works with code, XIB, and Storyboard initialization

## Supported Scenarios

### Normal Text Expand/Collapse

Use regular string content and let the component handle truncation, expand/collapse, and animation automatically.

### Attributed Text Support

Use `NSAttributedString` while still applying component-level typography and layout behavior.

### UITableViewCell & UICollectionViewCell Adaptation

Bind a stable model identifier in reusable cells to restore expand/collapse state and avoid reuse mismatch.

### Auto Hide Button For Short Text

When text does not exceed the collapsed line limit, the expand/collapse button is hidden automatically.

## Requirements

- Swift `5.9+`
- iOS `13.0+`
- `UIKit`
- `Foundation`

## Installation

### Option 1: Swift Package Manager (Recommended)

Add FKKit to your project, then import:

```swift
import FKUIKit
```

### Option 2: Source Integration

Copy `Sources/FKUIKit/Components/ExpandableText` into your project and include it in your app target.

## Basic Usage

### Create Expandable Text with Code

```swift
import UIKit
import FKUIKit

let expandableText = FKExpandableText()
expandableText.setText(
  "This is a very long content string used for expandable text demo...",
  stateIdentifier: "post_1001"
)
```

### Create Expandable Text with XIB

```swift
import UIKit
import FKUIKit

final class DemoViewController: UIViewController {
  @IBOutlet private weak var expandableText: FKExpandableText!

  override func viewDidLoad() {
    super.viewDidLoad()
    expandableText.setText(
      "Long content loaded from server...",
      stateIdentifier: "news_2001"
    )
  }
}
```

### Set Max Collapsed Lines

```swift
expandableText.configure {
  $0.behavior.collapsedNumberOfLines = 5
}
```

### Expand/Collapse Animation

```swift
expandableText.configure {
  $0.layoutStyle.animationDuration = 0.3
}

expandableText.setExpanded(true, animated: true)
expandableText.setExpanded(false, animated: true)
```

## Advanced Usage

### Custom Text Style (Font/Color/Line Spacing)

```swift
expandableText.configure {
  $0.textStyle.font = .systemFont(ofSize: 16, weight: .regular)
  $0.textStyle.color = .label
  $0.textStyle.alignment = .left
  $0.textStyle.lineSpacing = 6
  $0.textStyle.kern = 0.2
}
```

### Custom Expand/Collapse Button Text & Style

```swift
expandableText.configure {
  $0.buttonStyle.expandTitle = "Read more"
  $0.buttonStyle.collapseTitle = "Show less"
  $0.buttonStyle.titleColor = .systemBlue
  $0.buttonStyle.highlightedTitleColor = .systemGray
  $0.buttonStyle.font = .systemFont(ofSize: 14, weight: .semibold)
  $0.buttonStyle.image = UIImage(systemName: "chevron.down")
  $0.buttonStyle.imageTintColor = .systemBlue
  $0.buttonStyle.imageTitleSpacing = 6
  $0.layoutStyle.buttonPosition = .bottomTrailing
}
```

### Global Style Configuration

```swift
FKExpandableText.defaultConfiguration = .build {
  $0.behavior.collapsedNumberOfLines = 3
  $0.textStyle.font = .systemFont(ofSize: 15)
  $0.textStyle.lineSpacing = 5
  $0.buttonStyle.expandTitle = "See more"
  $0.buttonStyle.collapseTitle = "Collapse"
  $0.layoutStyle.textButtonSpacing = 8
}
```

### State Cache for List Reuse

```swift
// UITableViewCell
cell.fk_bindExpandableText(expandableText, key: model.id, defaultExpanded: false)
expandableText.setText(model.content, stateIdentifier: model.id)

// UICollectionViewCell
cell.fk_bindExpandableText(expandableText, key: model.id, defaultExpanded: false)
expandableText.setText(model.content, stateIdentifier: model.id)
```

You can also clear one key manually:

```swift
expandableText.clearCachedState()
```

### Expand/Collapse Callback Events

```swift
expandableText.onStateChange = { context in
  print("state:", context.state)
  print("isTruncated:", context.isTruncated)
  print("identifier:", context.identifier ?? "nil")
}
```

### Manual Control Expand State

```swift
expandableText.setExpanded(true, animated: true)
expandableText.setExpanded(false, animated: false)
expandableText.toggle(animated: true)
```

You can lock display state via configuration:

```swift
expandableText.configure {
  $0.behavior.fixedState = .expanded
}
```

## API Reference

Primary types:

- `FKExpandableText`
- `FKExpandableTextConfiguration`
- `FKExpandableTextTextStyle`
- `FKExpandableTextButtonStyle`
- `FKExpandableTextLayoutStyle`
- `FKExpandableTextBehavior`
- `FKExpandableTextDisplayState`
- `FKExpandableTextStateContext`
- `FKExpandableTextManager`

Core APIs:

- `configure(_:)`
- `setText(_:stateIdentifier:)`
- `setAttributedText(_:stateIdentifier:)`
- `setExpanded(_:animated:notify:)`
- `toggle(animated:)`
- `clearCachedState()`
- `onStateChange`
- `stateIdentifier`

List helpers:

- `UITableViewCell.fk_bindExpandableText(_:key:defaultExpanded:)`
- `UICollectionViewCell.fk_bindExpandableText(_:key:defaultExpanded:)`

Height pre-calculation:

- `FKExpandableText.preferredHeight(text:attributedText:width:state:configuration:cacheKey:)`
- `measuredHeight(for:state:)`

## Performance Optimization

`FKExpandableText` is designed for large list workloads:

- Uses lightweight native view hierarchy (`UILabel` + button)
- Supports state cache to avoid reuse-state mismatch
- Provides static pre-measure API for off-path height planning
- Includes optional height cache via `cacheKey`
- Avoids heavy rendering paths and third-party layout dependencies
- Main-thread oriented API to keep UI updates predictable

## Best Practices

- Use stable model IDs for `stateIdentifier` in reusable cells
- Pre-calculate heights in your data source/layout layer when possible
- Update table/collection layout after state change for dynamic cell heights
- Keep callback logic light; dispatch heavy work asynchronously
- Configure global defaults once, then override per-instance only when needed

## Notes

- UI operations should be performed on the main thread.
- Button visibility depends on measured truncation result.
- If you set `fixedState`, user interaction toggling is disabled by design.
- For dynamic height lists, call layout updates in `onStateChange`.

## License

`FKExpandableText` is part of FKKit and is available under the [MIT License](../../../../LICENSE).
