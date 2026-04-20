# FKRefresh

FKRefresh is a pure-native Swift pull-to-refresh + pull-up load-more component for UIKit scroll containers.  
It is designed for production iOS apps and open-source usage, with zero third-party dependencies and protocol-oriented extensibility.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Supported Components](#supported-components)
- [Core Capabilities](#core-capabilities)
  - [Pull Down to Refresh](#pull-down-to-refresh)
  - [Pull Up to Load More](#pull-up-to-load-more)
  - [State Management](#state-management)
  - [Global & Custom Style](#global--custom-style)
- [Requirements](#requirements)
- [Installation](#installation)
- [Basic Usage](#basic-usage)
  - [Add Pull-to-Refresh](#add-pull-to-refresh)
  - [Add Pull-up Load More](#add-pull-up-load-more)
  - [Manual Refresh/Load Control](#manual-refreshload-control)
- [Advanced Usage](#advanced-usage)
  - [Custom Text & Color](#custom-text--color)
  - [Custom Animation/View](#custom-animationview)
  - [Global Style Configuration](#global-style-configuration)
  - [State Handling (No More Data/Load Failed)](#state-handling-no-more-dataload-failed)
  - [Auto Refresh & Silent Refresh](#auto-refresh--silent-refresh)
- [API Reference](#api-reference)
- [Best Practices](#best-practices)
- [Performance Optimization](#performance-optimization)
- [Notes](#notes)
- [License](#license)

## Overview

FKRefresh provides one-line integration for:

- pull-to-refresh (header)
- load-more (footer)
- sync closure callbacks and async/await callbacks
- default UI or fully custom content views

It works directly with `UIScrollView`, `UITableView`, and `UICollectionView` without modifying your existing Auto Layout constraints or data flow.

## Features

- Pure Swift implementation using only UIKit/Foundation APIs.
- No Objective-C bridge requirement and no third-party runtime dependency.
- Supports both closure and async/await callbacks.
- Built-in default refresh UI (indicator + text) for header/footer.
- Custom content view support (`FKRefreshContentView`) for any UI layout.
- Pull-to-refresh state transitions with pull progress callback.
- Load-more states: idle, loading, no-more-data, failed.
- Global defaults + per-control override configuration.
- Main-thread-safe refresh state operations.
- Footer auto-hide support when content is not scrollable.
- Safe-area aware footer layout.
- Retry-on-failure interaction in default footer.

## Supported Components

FKRefresh can be attached to any UIKit scroll container:

- `UIScrollView`
- `UITableView`
- `UICollectionView`

## Core Capabilities

### Pull Down to Refresh

- Default pull-to-refresh UI (`FKDefaultRefreshContentView`).
- Pull progress updates (`didUpdatePullProgress`) for custom animations.
- Trigger threshold + expanded height configuration.
- Programmatic refresh trigger with optional animation.
- Silent refresh mode (execute callback without showing header UI).

### Pull Up to Load More

- Default load-more UI with text + activity indicator.
- Supports terminal states: finished / no more data / failed.
- Automatic trigger mode and manual trigger mode.
- Footer visibility control and reset to idle.
- Tap-to-retry behavior in the default footer on failure.

### State Management

`FKRefreshControl` supports these states:

- `idle`
- `pulling(progress:)`
- `triggered`
- `refreshing`
- `finished`
- `listEmpty`
- `noMoreData`
- `failed(Error?)`

State changes are exposed through:

- `onStateChanged` closure
- `FKRefreshControlDelegate`

### Global & Custom Style

- Global style defaults via `FKRefreshManager.shared` + `FKRefreshSettings`.
- Per-instance config override through `FKRefreshConfiguration`.
- Custom text copy through `FKRefreshText`.
- Custom colors, fonts, thresholds, animation timing, and behavior flags.
- Custom content view implementations through `FKRefreshContentView`.

## Requirements

- iOS 13.0+
- Swift 5.9+
- UIKit/Foundation project

## Installation

FKRefresh is part of `FKUIKit` in this repository.

1. Add the `FKKit` package to your project (SPM or internal dependency workflow).
2. Add `FKUIKit` to your target.
3. Import:

```swift
import FKUIKit
```

## Basic Usage

### Add Pull-to-Refresh

```swift
import FKUIKit

final class FeedViewController: UIViewController {
  private let tableView = UITableView()

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.fk_addPullToRefresh { [weak self] in
      self?.reloadFirstPage()
    }
  }

  private func reloadFirstPage() {
    // Request data...
    tableView.fk_pullToRefresh?.endRefreshing()
  }
}
```

Async/await variant:

```swift
tableView.fk_addPullToRefresh(asyncAction: { [weak self] in
  try await self?.fetchFirstPage()
})
```

### Add Pull-up Load More

```swift
collectionView.fk_addLoadMore { [weak self] in
  self?.loadNextPage()
}

func loadNextPage() {
  // Request next page...
  collectionView.fk_loadMore?.endLoadingMore()
}
```

Async/await variant:

```swift
collectionView.fk_addLoadMore(asyncAction: { [weak self] in
  try await self?.fetchNextPage()
})
```

### Manual Refresh/Load Control

```swift
// Programmatically trigger header refresh
scrollView.fk_beginPullToRefresh(animated: true)

// Programmatically trigger footer load
scrollView.fk_beginLoadMore()

// End states
scrollView.fk_pullToRefresh?.endRefreshing()
scrollView.fk_loadMore?.endLoadingMore()

// Remove controls
scrollView.fk_removeRefreshComponents()
```

## Advanced Usage

### Custom Text & Color

```swift
var text = FKRefreshText.default
text.pullToRefresh = "Pull down to sync"
text.releaseToRefresh = "Release to sync"
text.footerNoMoreData = "You reached the end"

let config = FKRefreshConfiguration(
  tintColor: .systemBlue,
  backgroundColor: .clear,
  messageFontSize: 13,
  messageFontWeight: .medium,
  texts: text
)

tableView.fk_addPullToRefresh(configuration: config) { [weak tableView] in
  tableView?.fk_pullToRefresh?.endRefreshing()
}
```

### Custom Animation/View

Using built-in GIF content view:

```swift
let gifView = FKGIFRefreshContentView()
gifView.image = UIImage.animatedImageNamed("refresh_frame_", duration: 0.8)

scrollView.fk_addPullToRefresh(contentView: gifView) {
  // Refresh logic...
}
```

Using hosted custom view:

```swift
let customIndicator = UIActivityIndicatorView(style: .large)
let hosted = FKHostedRefreshContentView(hostedView: customIndicator)

scrollView.fk_addLoadMore(contentView: hosted) {
  // Load logic...
}
```

### Global Style Configuration

```swift
FKRefreshManager.shared.updatePullToRefreshConfiguration { config in
  config.tintColor = .systemIndigo
  config.expandedHeight = 72
  config.triggerThreshold = 72
}

FKRefreshManager.shared.updateLoadMoreConfiguration { config in
  config.tintColor = .systemTeal
  config.autohidesFooterWhenNotScrollable = true
  config.loadMoreTriggerMode = .automatic
}
```

Apply global defaults in one call:

```swift
FKRefreshManager.shared.applyGlobalConfiguration(
  pullToRefresh: FKRefreshConfiguration(tintColor: .label),
  loadMore: FKRefreshConfiguration(tintColor: .secondaryLabel)
)
```

### State Handling (No More Data/Load Failed)

```swift
// No more data
tableView.fk_loadMore?.endRefreshingWithNoMoreData()

// Load failed
tableView.fk_loadMore?.endRefreshingWithError(MyError.network)

// Reset footer state after retry strategy changes
tableView.fk_resetLoadMoreState()

// Temporarily hide footer
tableView.fk_setLoadMoreHidden(true)
```

### Auto Refresh & Silent Refresh

Auto trigger when page appears:

```swift
override func viewDidAppear(_ animated: Bool) {
  super.viewDidAppear(animated)
  tableView.fk_beginPullToRefresh(animated: true)
}
```

Silent refresh (no visual header expansion):

```swift
let silent = FKRefreshConfiguration(
  isSilentRefresh: true,
  automaticallyEndsRefreshingOnAsyncCompletion: true
)

tableView.fk_addPullToRefresh(configuration: silent, asyncAction: {
  try await fetchLatestData()
})
```

Async auto-end with delay:

```swift
let autoEnd = FKRefreshConfiguration(
  automaticallyEndsRefreshingOnAsyncCompletion: true,
  automaticEndDelay: 0.25
)
```

## API Reference

Primary types:

- `FKRefreshControl`
- `FKRefreshConfiguration`
- `FKRefreshState`
- `FKRefreshText`
- `FKRefreshPagination`
- `FKRefreshManager`
- `FKRefreshSettings`
- `FKRefreshContentView`
- `FKDefaultRefreshContentView`
- `FKGIFRefreshContentView`
- `FKHostedRefreshContentView`

`UIScrollView` extension entry points:

- `fk_addPullToRefresh(configuration:action:)`
- `fk_addPullToRefresh(configuration:asyncAction:)`
- `fk_addPullToRefresh(configuration:contentView:action:)`
- `fk_addPullToRefresh(configuration:contentView:asyncAction:)`
- `fk_addLoadMore(configuration:action:)`
- `fk_addLoadMore(configuration:asyncAction:)`
- `fk_addLoadMore(configuration:contentView:action:)`
- `fk_addLoadMore(configuration:contentView:asyncAction:)`
- `fk_beginPullToRefresh(animated:)`
- `fk_beginLoadMore()`
- `fk_setLoadMoreHidden(_:)`
- `fk_resetLoadMoreState()`
- `fk_removePullToRefresh()`
- `fk_removeLoadMore()`
- `fk_removeRefreshComponents()`

Control terminal APIs:

- `endRefreshing()`
- `endLoadingMore()`
- `endRefreshingWithEmptyList()`
- `endRefreshingWithNoMoreData()`
- `endRefreshingWithError(_:)`
- `resetToIdle()`
- `retryAfterFailure()`

## Best Practices

- Keep header/footer callbacks focused on data requests and state finishing.
- Prefer `asyncAction` + auto-end configuration for modern async data flow.
- Use per-screen configuration overrides for business-specific UX copy and thresholds.
- Always call proper terminal APIs for each request path (success/empty/no-more/failure).
- Reset footer state when a new first-page refresh starts.

## Performance Optimization

- Keep custom refresh/load-more views lightweight and reuse subviews.
- Avoid heavy layout recalculation in `didUpdatePullProgress`.
- Minimize complex animations for large list screens.
- Use `autohidesFooterWhenNotScrollable` to reduce unnecessary footer work.
- Prefer state-driven updates over repeated add/remove cycles.

## Notes

- FKRefresh is non-invasive: it attaches as subviews and does not require cell subclassing.
- All public state mutation APIs are main-thread safe.
- Footer layout includes safe-area handling (`footerSafeAreaPadding` + system inset).
- The component supports both automatic and manual load-more trigger modes.
- This README reflects current implementation under `Sources/FKUIKit/Components/Refresh`.

## License

This project is licensed under the repository license.  
See the root [`LICENSE`](../../../LICENSE) file for details.
