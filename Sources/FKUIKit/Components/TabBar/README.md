# FKTabBar

`FKTabBar` is a high-performance, UIKit-native tab header component. It is UI-only and focuses on **rendering**, **selection state**, **indicator animation**, and **badge integration** (via `FKBadge`), while keeping controller/pager responsibilities outside of the component.

It is designed to serve two common product needs:

- A **paging switch bar** for external paging containers (drive it with `setSelectionProgress(from:to:progress:)`).
- A **custom bar surface** to replace `UITabBar` (UIView only, no `TabBarController` abstraction).

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
  - [Swift Package Manager](#swift-package-manager)
- [Basic Usage](#basic-usage)
  - [Create Tabs](#create-tabs)
  - [Selection Callbacks (Closure + Delegate)](#selection-callbacks-closure--delegate)
  - [Programmatic Selection (notify)](#programmatic-selection-notify)
  - [Controlled Selection Mode](#controlled-selection-mode)
- [Badges](#badges)
  - [Per-item Badges](#per-item-badges)
  - [Local Badge Updates (no full reload)](#local-badge-updates-no-full-reload)
- [Indicator & Paging Progress](#indicator--paging-progress)
- [Layout & Appearance](#layout--appearance)
  - [`FKTabBarConfiguration`](#fktabbarconfiguration)
  - [Scrollable vs. Fixed Equal](#scrollable-vs-fixed-equal)
  - [RTL + Dynamic Type](#rtl--dynamic-type)
- [Data Source Mode](#data-source-mode)
- [SwiftUI](#swiftui)
- [API Reference](#api-reference)
  - [Core Types](#core-types)
  - [Main APIs](#main-apis)
  - [Delegate & DataSource](#delegate--datasource)
- [Best Practices](#best-practices)
- [Notes](#notes)
- [License](#license)

## Overview

`FKTabBar` is a `UIView` backed by `UICollectionView` for smooth scrolling and efficient partial updates.

**Responsibility boundaries**

- `FKTabBar` does **not** manage pages, navigation, or controller containment.
- It does **not** provide a `TabBarController` wrapper.
- Hosts coordinate selection and paging progress externally.

**Threading**

- All public APIs are `@MainActor` and must be used on the main thread.

## Features

- UIKit-native, `UICollectionView`-based rendering
- Supports **scrollable** and **fixed-equal** layouts
- Multiple indicator styles (`line`, `pill`, background highlights, custom)
- Deterministic selection reducer (stable behavior under rapid updates)
- Interactive paging linkage via `setSelectionProgress(from:to:progress:)`
- Per-item badges backed by `FKBadge` (`dot`, `count`, `text`, custom)
- Accessibility: selection traits, badge value in `accessibilityValue`, Dynamic Type relayout
- RTL-aware content direction + scroll alignment
- Extensibility:
  - custom item content view (`itemViewProvider`)
  - indicator view provider / renderer (`indicatorViewProvider`, `indicatorRenderer`)
  - per-item button customization (`itemButtonConfigurator`)
  - custom interaction animations (`itemInteractionAnimator`)

## Requirements

- Swift 5.9+
- UIKit / Foundation
- iOS 15+ in the current `FKUIKit` package setup

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

### Create Tabs

```swift
import UIKit
import FKUIKit

final class DemoViewController: UIViewController {
  private lazy var tabBar: FKTabBar = {
    let items: [FKTabBarItem] = [
      FKTabBarItem(
        id: "home",
        title: .init(normal: .init(text: "Home")),
        image: .init(normal: .init(source: .systemSymbol(name: "house")))
      ),
      FKTabBarItem(
        id: "inbox",
        title: .init(normal: .init(text: "Inbox")),
        image: .init(normal: .init(source: .systemSymbol(name: "tray")))
      )
    ]
    return FKTabBar(items: items, selectedIndex: 0)
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    tabBar.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tabBar)
    NSLayoutConstraint.activate([
      tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tabBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tabBar.heightAnchor.constraint(equalToConstant: 56)
    ])
  }
}
```

### Selection Callbacks (Closure + Delegate)

`FKTabBar` supports both closure callbacks and delegate callbacks. They are both fired in a **single predictable pipeline**.

Closure:

```swift
tabBar.onSelectionChanged = { item, index, reason in
  print("didSelect \(item.id) at \(index), reason=\(reason)")
}
```

Delegate:

```swift
final class DemoViewController: UIViewController, FKTabBarDelegate {
  func tabBar(_ tabBar: FKTabBar, didSelect item: FKTabBarItem, at index: Int, reason: FKTabBar.SelectionReason) {
    print("delegate.didSelect \(item.id) at \(index)")
  }
}
```

### Programmatic Selection (notify)

Use `notify: false` to update visuals without emitting external callbacks and VoiceOver announcement.

```swift
tabBar.setSelectedIndex(1, animated: true, notify: false, reason: .programmatic)
```

### Controlled Selection Mode

In controlled mode, a user tap triggers a **selection request** and the host decides whether/when to commit by calling `setSelectedIndex`.

```swift
tabBar.selectionControlMode = .controlled

tabBar.onSelectionRequest = { item, index in
  // Validate, then commit when ready.
  tabBar.setSelectedIndex(index, animated: true, reason: .programmatic)
}
```

## Badges

### Per-item Badges

Badges are configured per item via `FKTabBarItem.badge` and rendered via `FKBadge`.

```swift
var items = tabBar.items
items[0].badge.state.normal = .dot
items[1].badge.state.normal = .count(12)
items[1].badge.accessibilityValue = "12 unread messages"
tabBar.reload(items: items)
```

### Local Badge Updates (no full reload)

For frequent updates, use `setBadge(_:at:)` to avoid a full `reloadData()`.

```swift
tabBar.setBadge(.count(128), at: 1, animated: true)
tabBar.setBadge(.none, at: 0, animated: true)
```

## Indicator & Paging Progress

Use this when `FKTabBar` is integrated with an external pager. Progress is normalized in `[0, 1]`.

```swift
tabBar.setSelectionProgress(from: 0, to: 1, progress: 0.35)
```

To commit the final index:

```swift
tabBar.setSelectedIndex(1, animated: true, reason: .interaction)
```

## Layout & Appearance

### `FKTabBarConfiguration`

`FKTabBarConfiguration` is the single configuration entry point:

```swift
var config = FKTabBarDefaults.defaultConfiguration
config.layout.isScrollable = true
config.layout.widthMode = .intrinsic
config.layout.contentInsets = .init(top: 0, leading: 16, bottom: 0, trailing: 16)
config.appearance.indicatorStyle = .line(.init())

let tabBar = FKTabBar(items: items, selectedIndex: 0, configuration: config)
```

### Scrollable vs. Fixed Equal

- Scrollable: `layout.isScrollable = true`, `layout.widthMode = .intrinsic`
- Fixed equal: `layout.isScrollable = false`, `layout.widthMode = .fillEqually`

### RTL + Dynamic Type

`FKTabBar` reacts to:

- `traitCollection.layoutDirection` changes (RTL)
- `preferredContentSizeCategory` changes (Dynamic Type)

Use `layout.rtlBehavior` to override mirroring and `layout.largeTextLayoutStrategy` to tune accessibility-category behavior.

## Data Source Mode

`FKTabBar` can be driven by a data source. This is useful when items are computed on demand.

```swift
final class TabsSource: FKTabBarDataSource {
  private var models: [FKTabBarItem] = []

  func numberOfItems(in tabBar: FKTabBar) -> Int { models.count }
  func tabBar(_ tabBar: FKTabBar, itemAt index: Int) -> FKTabBarItem { models[index] }
}

let source = TabsSource()
tabBar.dataSource = source
tabBar.reloadData()
```

Coexistence with manual `reload(items:)`:

- `reload(items:)` applies that list immediately (and caches it).
- `reloadData()` pulls from `dataSource` when non-`nil`, otherwise reloads from the manual cache.

## SwiftUI

Use `FKTabBarRepresentable` as a lightweight bridge.

```swift
#if canImport(SwiftUI)
import SwiftUI
import FKUIKit

struct TabsView: View {
  @State private var selected: Int = 0

  var body: some View {
    FKTabBarRepresentable(
      items: [
        FKTabBarItem(id: "a", title: .init(normal: .init(text: "A"))),
        FKTabBarItem(id: "b", title: .init(normal: .init(text: "B")))
      ],
      selectedIndex: $selected
    )
  }
}
#endif
```

## API Reference

### Core Types

- `FKTabBar`
- `FKTabBarItem`
- `FKTabBarConfiguration`
  - `FKTabBarLayoutConfiguration`
  - `FKTabBarAppearance`
  - `FKTabBarAnimationConfiguration`
- `FKTabBarBadgeConfiguration`
- `FKTabBarIndicatorStyle`

### Main APIs

- `FKTabBar.reload(items:updatePolicy:)`
- `FKTabBar.reloadData(updatePolicy:)`
- `FKTabBar.setSelectedIndex(_:animated:notify:reason:)`
- `FKTabBar.setSelectionProgress(from:to:progress:)`
- `FKTabBar.setBadge(_:at:animated:accessibilityValue:)`
- `FKTabBar.visibleItemButton(at:)`

### Delegate & DataSource

- `FKTabBarDelegate`
- `FKTabBarDataSource`

## Best Practices

- Keep `FKTabBarItem.id` stable across updates.
- Prefer `setBadge(_:at:)` for frequent badge changes to avoid full reloads.
- Use `notify: false` when syncing from external state to avoid feedback loops.
- Keep provider closures lightweight to avoid scroll/progress hitches.
- When integrating with pagers, call `setSelectionProgress(from:to:progress:)` frequently, but commit final index via `setSelectedIndex`.

## Notes

- `FKTabBar` is UI-only by design; it intentionally avoids controller/pager ownership.
- Badges are rendered via `FKBadge` and anchored to the icon element when available; otherwise anchored to the title label.
- Under rotation / Dynamic Type / RTL, `FKTabBar` invalidates layout and realigns selection + indicator to keep geometry stable.

## License

`FKTabBar` is part of the FKKit project and is distributed under the same license as this repository.