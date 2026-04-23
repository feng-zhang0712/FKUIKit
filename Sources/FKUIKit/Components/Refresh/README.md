# FKRefresh

`FKRefresh` is a UIKit pull-to-refresh + load-more component for `UIScrollView` (including `UITableView` / `UICollectionView`). It provides one-line attachment APIs, configurable UI/behavior, and safe completion patterns for async work.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Supported Containers](#supported-containers)
- [Requirements](#requirements)
- [Installation](#installation)
  - [Swift Package Manager](#swift-package-manager)
- [Basic Usage](#basic-usage)
  - [Pull-to-refresh (Closure)](#pull-to-refresh-closure)
  - [Load-more (Closure)](#load-more-closure)
  - [Programmatic Triggers](#programmatic-triggers)
- [Async & Completion](#async--completion)
  - [Async/Await Handler](#asyncawait-handler)
  - [Context Handler (Token-Safe)](#context-handler-token-safe)
- [Customization](#customization)
  - [Texts & Localization](#texts--localization)
  - [Custom Indicator View (`FKRefreshContentView`)](#custom-indicator-view-fkrefreshcontentview)
  - [Hosted UIKit View](#hosted-uikit-view)
- [Coordination & Policy](#coordination--policy)
  - [Concurrency Policy](#concurrency-policy)
  - [Auto-Fill Policy](#auto-fill-policy)
- [Global Configuration](#global-configuration)
- [SwiftUI Bridge](#swiftui-bridge)
- [API Reference](#api-reference)
  - [Core Types](#core-types)
  - [Main APIs](#main-apis)
- [Best Practices](#best-practices)
- [Notes](#notes)
- [License](#license)

## Overview

The component is designed for production UIKit apps:

- Pure UIKit/Foundation implementation
- No third-party dependencies
- Pull-to-refresh and load-more share the same configuration model
- Supports closure, async/await, and context-aware handlers
- Pair-level policy coordination (concurrency + auto-fill)
- Global defaults for consistent styling across screens

## Features

- Pull-to-refresh header (`fk_addPullToRefresh`)
- Load-more footer (`fk_addLoadMore`)
- Default indicator view (arrow/spinner + text)
- Custom indicator view via `FKRefreshContentView` (GIF, Lottie host, etc.)
- Async/await handlers with optional automatic end
- Token-safe “context handler” to avoid stale completion/races
- Pair coordination policy:
  - Concurrency: mutually exclusive / queueing / parallel
  - Auto-fill: trigger load-more automatically when content doesn’t fill viewport
- Global defaults via `FKRefreshSettings` / `FKRefreshManager`
- Optional SwiftUI bridge for hosting UIKit scroll views

## Supported Containers

`FKRefresh` attaches to:

- `UIScrollView` and any subclass
- `UITableView`
- `UICollectionView`

## Requirements

- Swift 5.9+
- UIKit / Foundation
- iOS 15+ in the current `FKUIKit` package setup

## Installation

### Swift Package Manager

Add `FKKit` as a dependency and use the `FKUIKit` product.

```swift
dependencies: [
  .package(url: "https://github.com/feng-zhang0712/FKKit.git", from: "0.40.2")
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

### Pull-to-refresh (Closure)

```swift
tableView.fk_addPullToRefresh { [weak self] in
  guard let self else { return }
  fetchLatest {
    self.tableView.reloadData()
    self.tableView.fk_pullToRefresh?.endRefreshing()
    self.tableView.fk_resetLoadMoreState()
  }
}
```

### Load-more (Closure)

```swift
tableView.fk_addLoadMore { [weak self] in
  guard let self else { return }
  fetchNextPage { result in
    switch result {
    case .success(let newItems):
      self.items.append(contentsOf: newItems)
      self.tableView.reloadData()
      self.tableView.fk_loadMore?.endRefreshing()
    case .noMoreData:
      self.tableView.fk_loadMore?.endRefreshingWithNoMoreData()
    case .failure(let error):
      self.tableView.fk_loadMore?.endRefreshingWithError(error)
    }
  }
}
```

### Programmatic Triggers

```swift
tableView.fk_beginPullToRefresh(animated: true)
tableView.fk_beginLoadMore()
```

## Async & Completion

### Async/Await Handler

```swift
var config = FKRefreshConfiguration()
config.automaticallyEndsRefreshingOnAsyncCompletion = true
config.automaticEndDelay = 0.2

tableView.fk_addPullToRefresh(configuration: config, asyncAction: { [weak self] in
  guard let self else { return }
  try await api.refresh()
  self.items = try await api.loadFirstPage()
  self.tableView.reloadData()
  self.tableView.fk_resetLoadMoreState()
})
```

If you prefer manual control, keep `automaticallyEndsRefreshingOnAsyncCompletion = false` and call `endRefreshing()` yourself.

### Context Handler (Token-Safe)

Use the context handler to guard against stale callbacks (e.g. overlapping triggers, fast re-attachments, screen dismissal):

```swift
tableView.fk_addPullToRefresh { [weak self] context in
  guard let self else { return }
  api.refresh { result in
    switch result {
    case .success:
      self.tableView.reloadData()
      self.tableView.fk_pullToRefresh?.endRefreshing(token: context.token)
    case .failure(let error):
      self.tableView.fk_pullToRefresh?.endRefreshingWithError(error, token: context.token)
    }
  }
}
```

> Note: The context includes a monotonic token, kind, source, and start timestamp (`FKRefreshActionContext`).

## Customization

### Texts & Localization

`FKDefaultRefreshContentView` uses `FKRefreshText` for user-facing strings:

```swift
var config = FKRefreshConfiguration()
config.texts = FKRefreshText(
  pullToRefresh: NSLocalizedString("pull_to_refresh", comment: ""),
  releaseToRefresh: NSLocalizedString("release_to_refresh", comment: ""),
  headerLoading: NSLocalizedString("refreshing", comment: ""),
  headerFinished: NSLocalizedString("refresh_done", comment: ""),
  headerListEmpty: NSLocalizedString("list_empty", comment: ""),
  headerFailed: NSLocalizedString("refresh_failed", comment: ""),
  footerLoading: NSLocalizedString("loading_more", comment: ""),
  footerFinished: NSLocalizedString("load_done", comment: ""),
  footerNoMoreData: NSLocalizedString("no_more", comment: ""),
  footerFailed: NSLocalizedString("load_failed", comment: ""),
  footerTapToRetry: NSLocalizedString("tap_to_retry", comment: "")
)
```

### Custom Indicator View (`FKRefreshContentView`)

Provide any view implementing `FKRefreshContentView`:

```swift
final class MyRefreshIndicatorView: UIView, FKRefreshContentView {
  func refreshControl(_ control: FKRefreshControl, didTransitionTo state: FKRefreshState, from previous: FKRefreshState) {
    // Drive animations based on state
  }

  func refreshControl(_ control: FKRefreshControl, didUpdatePullProgress progress: CGFloat) {
    // Optional: update for interactive pull progress
  }
}

let indicator = MyRefreshIndicatorView()
tableView.fk_addPullToRefresh(contentView: indicator) { /* ... */ }
```

### Hosted UIKit View

If you already have a `UIView` (e.g. Lottie `AnimationView`), wrap it with `FKHostedRefreshContentView`:

```swift
let hosted = FKHostedRefreshContentView(hostedView: myAnimationView)
tableView.fk_addPullToRefresh(contentView: hosted) { /* ... */ }
```

## Coordination & Policy

`FKRefreshPolicy` is stored on the scroll view as `fk_refreshPolicy` and applies to the attached header+footer pair.

### Concurrency Policy

```swift
tableView.fk_refreshPolicy = FKRefreshPolicy(concurrency: .queueing, autoFill: .disabled)
```

- `.mutuallyExclusive`: ignore new triggers while another is running
- `.queueing`: queue the next trigger and run after current finishes
- `.parallel`: allow pull-to-refresh and load-more concurrently

### Auto-Fill Policy

Auto-fill is useful for “short lists” where the first page doesn’t fill the screen:

```swift
tableView.fk_refreshPolicy = FKRefreshPolicy(
  concurrency: .mutuallyExclusive,
  autoFill: FKAutoFillPolicy(isEnabled: true, maxTriggerCount: 3)
)
```

## Global Configuration

Use global defaults to keep a consistent theme. These defaults are used when `configuration: nil` is passed.

```swift
@MainActor
func configureRefreshTheme() {
  var global = FKRefreshConfiguration()
  global.tintColor = .systemOrange
  global.texts.pullToRefresh = NSLocalizedString("pull_to_refresh", comment: "")

  FKRefreshManager.shared.applyGlobalConfiguration(
    pullToRefresh: global,
    loadMore: global,
    policy: .default
  )
}
```

> Note: `FKRefreshSettings` stores process-wide mutable globals (`nonisolated(unsafe)`). Prefer configuring once at app launch (or on the main actor) before attaching controls from multiple threads.

## SwiftUI Bridge

If you host a UIKit scroll view inside SwiftUI (`UIViewRepresentable`), keep a single `FKRefreshSwiftUIBridge` to bind and install handlers.

```swift
@MainActor
final class Model: ObservableObject {
  let refresh = FKRefreshSwiftUIBridge()
}

// In your UIViewRepresentable:
// 1) bridge.bind(scrollView:)
// 2) bridge.installPullToRefresh / bridge.installLoadMore
```

## API Reference

### Core Types

- `FKRefreshControl`
- `FKRefreshConfiguration`
- `FKRefreshState`
- `FKRefreshText`
- `FKRefreshPolicy`
- `FKAutoFillPolicy`
- `FKRefreshActionContext`
- `FKRefreshContentView`
- `FKHostedRefreshContentView`
- `FKRefreshManager` / `FKRefreshSettings`
- `FKRefreshSwiftUIBridge` (when `canImport(SwiftUI)`)

### Main APIs

- `UIScrollView.fk_addPullToRefresh(...)`
- `UIScrollView.fk_addLoadMore(...)`
- `UIScrollView.fk_pullToRefresh`
- `UIScrollView.fk_loadMore`
- `UIScrollView.fk_beginPullToRefresh(animated:)`
- `UIScrollView.fk_beginLoadMore()`
- `UIScrollView.fk_resetLoadMoreState()`
- `UIScrollView.fk_removePullToRefresh()`
- `UIScrollView.fk_removeLoadMore()`
- `UIScrollView.fk_removeRefreshComponents()`
- `UIScrollView.fk_refreshPolicy`

## Best Practices

- Access UIKit mutations on the main actor / main queue.
- Prefer the context handler (`FKRefreshActionContext`) when your completion may arrive late or out-of-order.
- Always end refreshing on all code paths (success / error / cancellation).
- Reset footer state after a successful pull-to-refresh when you restart pagination (`fk_resetLoadMoreState()`).
- Localize `FKRefreshText` with `NSLocalizedString` (or inject from your i18n layer) for international apps.

## Notes

- `FKRefreshPolicy` lives on the scroll view and affects the header+footer pair together.
- `loadMoreTriggerMode = .manual` is useful when you want “tap to load more” or explicit triggers.
- For “first screen is empty” UX, consider combining silent refresh (`isSilentRefresh`) with an initial data request.

## License

`FKRefresh` is part of the FKKit project and is distributed under the same license as this repository.