# FKEmptyState

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Supported States](#supported-states)
- [Supported Views](#supported-views)
- [Requirements](#requirements)
- [Installation](#installation)
- [Basic Usage](#basic-usage)
  - [Show Empty Data View](#show-empty-data-view)
  - [Show Load Failed View](#show-load-failed-view)
  - [Show No Network View](#show-no-network-view)
  - [Hide Empty View](#hide-empty-view)
  - [Integrate with UITableView/UICollectionView](#integrate-with-uitableviewuicollectionview)
- [Advanced Usage](#advanced-usage)
  - [Custom Image/Title/Desc/Button](#custom-imagetitledescbutton)
  - [Custom Colors & Fonts & Layout](#custom-colors--fonts--layout)
  - [Global Style Configuration](#global-style-configuration)
  - [Button Action Callback](#button-action-callback)
  - [Custom Business State](#custom-business-state)
  - [Auto Layout & Safe Area Adaptation](#auto-layout--safe-area-adaptation)
- [API Reference](#api-reference)
- [Best Practices](#best-practices)
- [Performance Optimization](#performance-optimization)
- [Notes](#notes)
- [License](#license)

## Overview
`FKEmptyState` is the README entry name for the `FKEmptyState` component in `FKUIKit`.

`FKEmptyState` is a pure UIKit empty/loading/error placeholder system designed for large iOS projects and open-source reuse.  
It supports one-line state switching, global style configuration, and per-screen overrides without third-party dependencies.

The component provides a unified overlay for:
- empty data pages
- loading pages
- request failure pages
- no-network pages
- custom business states

## Features
- Pure native Swift + UIKit/Foundation implementation.
- No third-party runtime dependency.
- Protocol-oriented design (`FKEmptyStatePresentable`) for testability and extensibility.
- One-line show/hide APIs for any `UIView` and scroll container.
- Built-in support for `UIScrollView`, `UITableView`, and `UICollectionView`.
- Full UI customization: image, title, description, button, colors, fonts, spacing, corner radius.
- Flexible content layout: centered or top-aligned with offset.
- Global template (`FKEmptyStateManager`) plus screen-level overrides.
- Built-in callbacks for both action button taps and placeholder background taps.
- Main-thread safety guard for all public UI entry points.
- Keyboard-aware positioning and safe-area-aware layout.
- Scroll interaction control while placeholder is visible.

## Supported States
`FKEmptyStatePhase` supports:
- `.content` (hide overlay)
- `.loading`
- `.empty`
- `.error`
- `.custom(String)` (business-defined state key)

Use presets from `FKEmptyStateScenario` when needed:
- `noNetwork`
- `loadFailed`
- `noSearchResult`
- `noFavorites`
- `noOrders`
- `noMessages`
- `noPermission`
- `notLoggedIn`

## Supported Views
`FKEmptyState` can be attached to:
- `UIView`
- `UIScrollView`
- `UITableView`
- `UICollectionView`

It works for both full-screen and subview-level overlays, and it does not require replacing `backgroundView`.

## Requirements
- Swift 5.9+ for component-level usage goals.
- UIKit/Foundation.
- iOS 13+ API compatibility in `FKEmptyState` implementation.
- Package-level note: this repository currently declares `iOS 15+` in `Package.swift`. If you consume via this package directly, follow package platform settings.

## Installation
Add `FKUIKit` using Swift Package Manager.

### Xcode
1. Open `File` -> `Add Package Dependencies...`
2. Enter:
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
```swift
import UIKit
import FKUIKit
```

### Show Empty Data View
```swift
var model = FKEmptyStateModel.scenario(.noSearchResult)
model.phase = .empty
view.fk_applyEmptyState(model)
```

### Show Load Failed View
```swift
let model = FKEmptyStateModel.scenario(.loadFailed)
view.fk_applyEmptyState(model, actionHandler: { [weak self] in
  self?.reloadData()
})
```

### Show No Network View
```swift
let model = FKEmptyStateModel.scenario(.noNetwork)
view.fk_applyEmptyState(model, actionHandler: { [weak self] in
  self?.retryNetworkRequest()
})
```

### Hide Empty View
```swift
view.fk_hideEmptyState()
// or
view.fk_setEmptyState(phase: .content)
```

### Integrate with UITableView/UICollectionView
```swift
// UITableView
var tableModel = FKEmptyStateModel.scenario(.noOrders)
tableModel.phase = .empty
tableView.fk_updateEmptyStateForTable(model: tableModel, actionHandler: { [weak self] in
  self?.reloadData()
})

// UICollectionView
var gridModel = FKEmptyStateModel.scenario(.noFavorites)
gridModel.phase = .empty
collectionView.fk_updateEmptyState(
  itemCount: collectionView.fk_totalItemCount(),
  model: gridModel,
  actionHandler: { [weak self] in
    self?.reloadData()
  }
)
```

## Advanced Usage
### Custom Image/Title/Desc/Button
```swift
var model = FKEmptyStateModel(
  phase: .empty,
  image: UIImage(systemName: "tray"),
  title: "No Data",
  description: "There is nothing to display right now.",
  buttonStyle: FKEmptyStateButtonStyle(title: "Refresh"),
  isButtonHidden: false
)
view.fk_applyEmptyState(model, actionHandler: { [weak self] in
  self?.reloadData()
})
```

### Custom Colors & Fonts & Layout
```swift
var model = FKEmptyStateModel.scenario(.loadFailed)
model.titleColor = .label
model.descriptionColor = .secondaryLabel
model.titleFont = .systemFont(ofSize: 20, weight: .bold)
model.descriptionFont = .systemFont(ofSize: 14, weight: .regular)
model.buttonStyle.backgroundColor = .systemRed
model.buttonStyle.cornerRadius = 12
model.verticalSpacing = 14
model.maxContentWidth = 360
model = model.withLayout(alignment: .top, verticalOffset: 48)

view.fk_applyEmptyState(model)
```

### Global Style Configuration
```swift
FKEmptyStateManager.shared.configureTemplate { model in
  model.titleColor = .label
  model.descriptionColor = .secondaryLabel
  model.backgroundColor = .systemBackground
  model.buttonStyle = FKEmptyStateButtonStyle(
    title: nil,
    titleColor: .white,
    font: .systemFont(ofSize: 15, weight: .semibold),
    backgroundColor: .systemBlue,
    cornerRadius: 10
  )
}

// One-line usage with global template
view.fk_setEmptyState(phase: .loading)
```

### Button Action Callback
```swift
var model = FKEmptyStateModel.scenario(.loadFailed)
model.phase = .error

view.fk_applyEmptyState(
  model,
  actionHandler: { [weak self] in
    self?.reloadData()
  },
  viewTapHandler: { [weak self] in
    self?.view.endEditing(true)
  }
)
```

### Custom Business State
```swift
let maintenance = FKEmptyStateModel.customState(
  identifier: "maintenance",
  title: "Service Unavailable",
  description: "We are performing scheduled maintenance.",
  buttonTitle: "Try Again"
)

view.fk_applyEmptyState(maintenance, actionHandler: { [weak self] in
  self?.checkServiceStatus()
})
```

### Auto Layout & Safe Area Adaptation
`FKEmptyState` is pinned with Auto Layout and respects safe areas automatically.

Key built-in behaviors:
- Overlay fills host view bounds (or `frameLayoutGuide` for scroll views).
- Content width is controlled by `maxContentWidth`.
- Keyboard-aware position is enabled by default (`adjustsPositionForKeyboard = true`).
- Inset and placement are configurable via `contentInsets`, `contentAlignment`, and `verticalOffset`.

```swift
var model = FKEmptyStateModel.scenario(.notLoggedIn)
model.contentInsets = UIEdgeInsets(top: 32, left: 20, bottom: 32, right: 20)
model.contentAlignment = .center
model.adjustsPositionForKeyboard = true
view.fk_applyEmptyState(model)
```

## API Reference
Core types:
- `FKEmptyStateView`
- `FKEmptyStateModel`
- `FKEmptyStatePhase`
- `FKEmptyStateScenario`
- `FKEmptyStateButtonStyle`
- `FKEmptyStateManager`
- `FKEmptyStatePresentable`

Main APIs:
- `UIView.fk_applyEmptyState(_:animated:actionHandler:viewTapHandler:)`
- `UIView.fk_hideEmptyState(animated:)`
- `UIView.fk_setEmptyState(phase:animated:actionHandler:viewTapHandler:)`
- `UIView.fk_setEmptyState(animated:actionHandler:viewTapHandler:configure:)`
- `UIScrollView.fk_showEmptyState(_:animated:actionHandler:viewTapHandler:)`
- `UIScrollView.fk_updateEmptyState(_:animated:)`
- `UIScrollView.fk_updateEmptyState(itemCount:model:animated:actionHandler:viewTapHandler:)`
- `UIScrollView.fk_updateEmptyStateVisibility(isEmpty:model:animated:actionHandler:viewTapHandler:)`
- `UIScrollView.fk_refreshEmptyStateAutomatically(actionHandler:viewTapHandler:)`
- `UITableView.fk_totalRowCount()`
- `UITableView.fk_updateEmptyStateForTable(model:animated:actionHandler:viewTapHandler:)`
- `UICollectionView.fk_totalItemCount()`

## Best Practices
- Attach overlays to `viewController.view` or scroll views, not `tableView.backgroundView`.
- Use `.content` to hide overlay without removing it, reducing flicker.
- Keep retry logic in `actionHandler` and always capture `self` weakly.
- Use global template for consistency, then override per screen only when necessary.
- Prefer `fk_updateEmptyState(itemCount:model:...)` after data reload for list pages.
- Keep messages concise and localize strings in app-level resources.

## Performance Optimization
- Reuse a single overlay per host view (`fk_applyEmptyState` already does this).
- Avoid creating large custom accessory views repeatedly.
- Keep images reasonably sized and prefer vector/system images when possible.
- Use `skipsLoadingWhileRefreshing` to avoid duplicate loading UI during pull-to-refresh.
- Disable heavy gradient usage on frequently changing states if not required.

## Notes
- All UI APIs are main-thread only (guarded internally).
- Error state enforces a retry button title when missing (`Retry` by default).
- Scroll behavior can be controlled with `keepScrollEnabled`.
- Background tap can dismiss keyboard when `supportsTapToDismissKeyboard = true`.
- `customAccessoryView` supports any `UIView` (including animation views managed by your app).

## License
This module is part of the FKKit project and is released under the MIT License.  
See the root [LICENSE](../../../../LICENSE) file for details.

