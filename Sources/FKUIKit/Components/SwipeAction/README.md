# FKSwipeAction

`FKSwipeAction` is a pure native Swift swipe-action component for high-volume iOS list scenarios.
It is built only with `UIKit` / `Foundation` APIs, supports both left and right swipe directions, and is optimized for reusable cells in production table/collection views.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Supported Components](#supported-components)
  - [UITableView Swipe Action](#uitableview-swipe-action)
  - [UICollectionView Swipe Action](#uicollectionview-swipe-action)
  - [Left/Right Double Direction Swipe](#leftright-double-direction-swipe)
- [Core Capabilities](#core-capabilities)
  - [Multiple Custom Buttons](#multiple-custom-buttons)
  - [Image/Text/Image+Text Button Style](#imagetextimagetext-button-style)
  - [Elastic Swipe Animation](#elastic-swipe-animation)
  - [State Mutex & Auto Close](#state-mutex--auto-close)
- [Requirements](#requirements)
- [Installation](#installation)
- [Basic Usage](#basic-usage)
  - [Setup Swipe Buttons for UITableViewCell](#setup-swipe-buttons-for-uitableviewcell)
  - [Setup Swipe Buttons for UICollectionViewCell](#setup-swipe-buttons-for-uicollectionviewcell)
  - [Left Swipe & Right Swipe](#left-swipe--right-swipe)
  - [Button Click Event Callback](#button-click-event-callback)
- [Advanced Usage](#advanced-usage)
  - [Custom Button Style (Color/Font/Size/Width)](#custom-button-style-colorfontsizewidth)
  - [Global Swipe Style Configuration](#global-swipe-style-configuration)
  - [Disable Swipe for Specific Cell](#disable-swipe-for-specific-cell)
  - [Dangerous Action Confirmation (Delete)](#dangerous-action-confirmation-delete)
  - [Dynamic Update Swipe Buttons](#dynamic-update-swipe-buttons)
  - [Auto Close Swipe State](#auto-close-swipe-state)
- [API Reference](#api-reference)
- [Performance Optimization](#performance-optimization)
- [Best Practices](#best-practices)
- [Notes](#notes)
- [License](#license)

## Overview

`FKSwipeAction` provides a lightweight, protocol-friendly swipe action layer for list cells without replacing your existing `UITableView` / `UICollectionView` architecture.

Design goals:

- Zero third-party dependency
- Minimal integration cost (one-line setup per cell)
- High-performance interaction for large reusable lists
- Extensible API for business-specific actions and styling

## Features

- Pure native implementation (`Swift 5.9+`, `UIKit`, `Foundation`)
- Left and right swipe directions on the same cell
- Unlimited action buttons on each side
- Text-only, image-only, or image + text action content
- Adaptive or fixed button width
- Per-button style customization (color/font/insets/corner radius/icon size)
- Built-in action presets (`delete`, `edit`, `pin`, `mark`, `favorite`, `more`)
- Optional dangerous-action confirmation alert
- Open-state mutex: opening one cell closes others
- Supports auto-close when list scrolling starts
- Non-invasive extension APIs for existing cells

## Supported Components

### UITableView Swipe Action

Use `UITableViewCell` extension APIs to configure, open, close, or disable swipe actions.

### UICollectionView Swipe Action

Use `UICollectionViewCell` extension APIs with the same configuration model and behavior controls.

### Left/Right Double Direction Swipe

Each cell can define both:

- `leftActions` (reveal when swiping right)
- `rightActions` (reveal when swiping left)

## Core Capabilities

### Multiple Custom Buttons

Configure any number of actions on each side using `FKSwipeActionItem`.

### Image/Text/Image+Text Button Style

Each action button supports:

- Title-only
- Image-only
- Title + image

### Elastic Swipe Animation

Built-in spring animation for open/close transitions and overscroll elasticity for natural gestures.

### State Mutex & Auto Close

- Optional exclusive open state (`allowsOnlyOneOpenCell`)
- Auto-close all opened cells when list scroll begins (`closesOnScroll`)

## Requirements

- Swift `5.9+`
- iOS `13.0+` for `FKSwipeAction` APIs
- `UIKit` + `Foundation` only
- No Objective-C dependency and no third-party library dependency

## Installation

### Option 1: Use FKKit via Swift Package Manager

Add FKKit dependency and import `FKUIKit`:

```swift
import FKUIKit
```

### Option 2: Source Integration

Copy the `Sources/FKUIKit/Components/SwipeAction` folder into your project and compile with your app target.

## Basic Usage

### Setup Swipe Buttons for UITableViewCell

```swift
import UIKit
import FKUIKit

func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
  let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

  cell.fk_configureSwipeActions(
    left: [
      .pin { _ in
        print("Pin tapped")
      }
    ],
    right: [
      .more { _ in
        print("More tapped")
      },
      .delete(requiresConfirmation: true) { _ in
        print("Delete confirmed")
      }
    ]
  )

  return cell
}
```

### Setup Swipe Buttons for UICollectionViewCell

```swift
import UIKit
import FKUIKit

func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
  let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)

  cell.fk_configureSwipeActions(
    left: [.mark { _ in print("Mark tapped") }],
    right: [.favorite { _ in print("Favorite tapped") }]
  )

  return cell
}
```

### Left Swipe & Right Swipe

```swift
var config = FKSwipeActionConfiguration(
  leftActions: [.edit { _ in print("left side action") }],
  rightActions: [.delete { _ in print("right side action") }]
)

cell.fk_configureSwipeAction(config)
```

### Button Click Event Callback

```swift
let customStyle = FKSwipeActionItemStyle(backgroundColor: .systemBlue)
let archive = FKSwipeActionItem(
  kind: .custom,
  title: "Archive",
  style: customStyle
) { context in
  print("Tapped item:", context.item.identifier)
  print("Action side:", context.side)
}
```

## Advanced Usage

### Custom Button Style (Color/Font/Size/Width)

```swift
let style = FKSwipeActionItemStyle(
  fixedWidth: 92,
  cornerRadius: 12,
  contentInsets: UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10),
  imageTitleSpacing: 6,
  backgroundColor: .black,
  highlightedBackgroundColor: .darkGray,
  titleColor: .white,
  titleFont: .systemFont(ofSize: 13, weight: .bold),
  imageTintColor: .white,
  imageSize: CGSize(width: 18, height: 18)
)

let item = FKSwipeActionItem(
  kind: .custom,
  title: "Custom",
  image: UIImage(systemName: "star.fill"),
  style: style
) { _ in
  print("Custom tapped")
}
```

### Global Swipe Style Configuration

```swift
FKSwipeAction.defaultConfiguration = FKSwipeActionConfiguration(
  behavior: FKSwipeActionBehaviorConfiguration(
    triggerMode: .edgeOnly(edgeWidth: 24),
    allowsOnlyOneOpenCell: true,
    closesOnScroll: true
  ),
  appearance: FKSwipeActionAppearance(
    actionAreaBackgroundColor: .clear,
    maskColor: UIColor.black.withAlphaComponent(0.04),
    itemSpacing: 8,
    actionInsets: UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
  )
)
```

### Disable Swipe for Specific Cell

```swift
cell.fk_setSwipeActionEnabled(false)
```

### Dangerous Action Confirmation (Delete)

```swift
let deleteAction = FKSwipeActionItem.delete(
  requiresConfirmation: true
) { _ in
  print("Run delete request")
}
```

### Dynamic Update Swipe Buttons

```swift
func applyState(isRead: Bool, to cell: UITableViewCell) {
  let right: [FKSwipeActionItem] = isRead
    ? [.mark(title: "Unread") { _ in print("mark unread") }]
    : [.mark(title: "Read") { _ in print("mark read") }]

  cell.fk_configureSwipeActions(right: right)
}
```

### Auto Close Swipe State

```swift
// Enabled automatically when configuration.behavior.closesOnScroll is true.
tableView.fk_enableSwipeActionAutoCloseOnScroll()

// Manual close, for example after network completion.
tableView.fk_closeAllSwipeActions(animated: true)
```

## API Reference

Primary types:

- `FKSwipeAction`
- `FKSwipeActionConfiguration`
- `FKSwipeActionBehaviorConfiguration`
- `FKSwipeActionAppearance`
- `FKSwipeActionItem`
- `FKSwipeActionItemStyle`
- `FKSwipeActionSide`
- `FKSwipeActionContext`

Cell APIs:

- `fk_configureSwipeAction(_:)`
- `fk_configureSwipeActions(left:right:update:)`
- `fk_setSwipeActionEnabled(_:)`
- `fk_openSwipeAction(side:animated:)`
- `fk_closeSwipeAction(animated:)`

Global / list APIs:

- `FKSwipeAction.defaultConfiguration`
- `FKSwipeAction.setGloballyEnabled(_:)`
- `FKSwipeAction.closeAll(animated:)`
- `UIScrollView.fk_enableSwipeActionAutoCloseOnScroll()`
- `UIScrollView.fk_closeAllSwipeActions(animated:)`
- `UIScrollView.fk_setSwipeActionEnabledForVisibleCells(_:)`

## Performance Optimization

`FKSwipeAction` is designed for large lists and frequent cell reuse:

- Uses lightweight view hierarchy and transform-based horizontal motion
- Keeps actions inside the cell host without replacing list container logic
- Uses weak controller registry for state coordination to avoid retain cycles
- Supports explicit close/reset behavior to prevent reused-cell state mismatch
- Avoids third-party gesture/animation abstractions to reduce overhead

## Best Practices

- Configure swipe actions in `cellForRowAt` / `cellForItemAt`
- Keep action handlers short and dispatch heavy work asynchronously
- Rebuild actions based on current model state during cell reuse
- Prefer concise labels and consistent action ordering for better UX
- Use confirmation for destructive actions (`delete`) to reduce accidental taps
- Use exclusive open mode (`allowsOnlyOneOpenCell`) in dense lists

## Notes

- `FKSwipeAction` is main-thread oriented; configure and update it on the main thread.
- Confirmation alerts rely on locating the nearest parent `UIViewController` from the cell view.
- Trigger mode supports full-width pan or edge-only pan.
- If your product uses custom cell subview layering, verify that content subviews are inside the default cell view hierarchy so transform-based motion can apply correctly.

## License

This component is part of FKKit and is available under the [MIT License](../../../../LICENSE).
