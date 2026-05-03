# FKRefresh

`FKRefresh` is a UIKit pull-to-refresh and load-more implementation for `UIScrollView` (including `UITableView` and `UICollectionView`). It favors small call sites (`fk_addPullToRefresh`, `fk_addLoadMore`), shared configuration, explicit completion APIs, and optional token-aware handlers for async work.

## Table of contents

- [Overview](#overview)
- [Repository layout](#repository-layout)
- [Features](#features)
- [Supported containers](#supported-containers)
- [Requirements](#requirements)
- [Installation](#installation)
- [Basic usage](#basic-usage)
- [Async and completion](#async-and-completion)
- [Customization](#customization)
- [Coordination and policy](#coordination-and-policy)
- [Global configuration](#global-configuration)
- [SwiftUI bridge](#swiftui-bridge)
- [Example app layout](#example-app-layout)
- [API reference](#api-reference)
- [Best practices](#best-practices)
- [Notes](#notes)
- [License](#license)

## Overview

- Pure UIKit and Foundation; no third-party runtime dependencies.
- One implementation (`FKRefreshControl`) for both header and footer; behavior is driven by `FKRefreshKind` and `FKRefreshConfiguration`.
- Pair-level coordination (mutually exclusive refresh vs load-more, optional queueing, optional auto-fill for short lists).
- Optional `FKRefreshSwiftUIBridge` when SwiftUI hosts a UIKit scroll view.

## Repository layout

Sources under `Sources/FKUIKit/Components/Refresh/`:

| Area | Role |
|------|------|
| `Public/Control/` | `FKRefreshControl`, `FKRefreshKind` |
| `Public/Models/` | `FKRefreshState`, `FKRefreshConfiguration`, `FKLoadMoreTriggerMode`, `FKRefreshText`, `FKRefreshPagination`, `FKRefreshActionContext`, `FKRefreshClock` |
| `Public/Policy/` | `FKRefreshPolicy`, concurrency and auto-fill types |
| `Public/Callbacks/` | Async and context handler type aliases |
| `Public/Protocols/` | `FKRefreshContentView`, `FKRefreshControlDelegate` |
| `Public/Views/` | `FKDefaultRefreshContentView`, `FKHostedRefreshContentView`, `FKGIFRefreshContentView` |
| `Public/Services/` | `FKRefreshManager`, `FKRefreshSettings` |
| `Public/Bridge/` | `FKRefreshSwiftUIBridge` (SwiftUI) |
| `Internal/` | `FKRefreshCoordinator` (header/footer coordination; not public API) |
| `Extension/` | `UIScrollView` attachment helpers |

## Features

- Pull-to-refresh header (`fk_addPullToRefresh`)
- Load-more footer (`fk_addLoadMore`)
- Default indicator (arrow, spinner, localized strings)
- Custom indicators via `FKRefreshContentView`
- Closures, `async`/`await`, and context handlers with monotonic tokens
- Global defaults via `FKRefreshSettings` / `FKRefreshManager`

## Supported containers

Any `UIScrollView` subclass, including `UITableView` and `UICollectionView`.

## Requirements

- Swift 6 language mode (see the `FKKit` package manifest).
- iOS 15+ for the current `FKUIKit` product.
- UIKit.

## Installation

Add the `FKUIKit` product from this repository, then:

```swift
import FKUIKit
```

## Basic usage

### Pull-to-refresh

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

### Load-more

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

### Programmatic triggers

```swift
tableView.fk_beginPullToRefresh(animated: true)
tableView.fk_beginLoadMore()
```

## Async and completion

### Async handler

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

If `automaticallyEndsRefreshingOnAsyncCompletion` is `false`, call `endRefreshing()` (or the error/empty variants) yourself.

### Context handler (token-safe, synchronous)

Use `FKRefreshActionContext` when completion may race with a new pull or view teardown:

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

### Context async handler

Same token semantics with `async`/`await`:

```swift
tableView.fk_addPullToRefresh(contextAsyncAction: { [weak self] context in
  guard let self else { return }
  try await api.refresh()
  self.tableView.fk_pullToRefresh?.endRefreshing(token: context.token)
})

tableView.fk_addLoadMore(contextAsyncAction: { [weak tableView] context in
  try await api.loadNextPage()
  tableView?.fk_loadMore?.endRefreshing(token: context.token)
})
```

The same overloads exist with a custom `contentView:` parameter when you implement `FKRefreshContentView`.

## Customization

### Texts and localization

`FKDefaultRefreshContentView` reads copy from `FKRefreshText`. Override `FKRefreshConfiguration.texts` per screen or assign localized defaults in `FKRefreshSettings`.

### Custom indicator

Implement `FKRefreshContentView` and pass the view to `fk_addPullToRefresh(contentView:action:)` (or the async/context variants).

### Hosted subtree

Use `FKHostedRefreshContentView` to wrap an existing `UIView` (for example a Lottie animation view).

## Coordination and policy

`fk_refreshPolicy` on the scroll view configures the attached pair:

- **Concurrency:** `.mutuallyExclusive`, `.queueing`, or `.parallel` between header and footer.
- **Auto-fill:** optional automatic `loadMore` when the first page is shorter than the viewport (`FKAutoFillPolicy`).

## Global configuration

```swift
@MainActor
func configureRefreshTheme() {
  var global = FKRefreshConfiguration()
  global.tintColor = .systemOrange

  FKRefreshManager.shared.applyGlobalConfiguration(
    pullToRefresh: global,
    loadMore: global,
    policy: .default
  )
}
```

`FKRefreshSettings` holds process-wide defaults (`nonisolated(unsafe)`). Configure on the main actor, typically once at launch, before attaching controls from multiple threads.

## SwiftUI bridge

When a `UIScrollView` is embedded via `UIViewRepresentable`, keep a single `FKRefreshSwiftUIBridge`:

1. `bridge.bind(scrollView:)`
2. `installPullToRefresh` / `installLoadMore` with `action`, `asyncAction`, or `contextAsyncAction`
3. `setPolicy(_:)` if needed

## Example app layout

FKKitExamples `Examples/FKUIKit/Refresh/`:

| Folder | Contents |
|--------|----------|
| `Hub/` | Navigation hub listing all demos |
| `Scenarios/` | Individual view controllers (table, collection, scroll view, policy, pagination, GIF, dots, hosted, configuration, environment, localization, …) |
| `SwiftUI/` | `FKRefreshSwiftUIBridge` hosting demo |
| `Shared/` | `FKRefreshExampleCommon` helpers (simulated delays, state strings) |
| `Support/` | Example-only views such as `FKDotsRefreshContentView` |

## API reference

### Core types

- `FKRefreshControl`, `FKRefreshKind`, `FKRefreshState`
- `FKRefreshConfiguration`, `FKLoadMoreTriggerMode`, `FKRefreshText`
- `FKRefreshPolicy`, `FKAutoFillPolicy`, `FKRefreshConcurrencyPolicy`, `FKRefreshTriggerSource`
- `FKRefreshActionContext`
- `FKRefreshContentView`, `FKRefreshControlDelegate`
- `FKHostedRefreshContentView`, `FKDefaultRefreshContentView`, `FKGIFRefreshContentView`
- `FKRefreshPagination`
- `FKRefreshClock`, `FKSystemRefreshClock`
- `FKRefreshManager`, `FKRefreshSettings`
- `FKRefreshSwiftUIBridge` (when SwiftUI is available)

### Main `UIScrollView` APIs

- `fk_addPullToRefresh(...)` — overloads for `action`, `asyncAction`, `FKRefreshActionHandler` (`(FKRefreshActionContext) -> Void`), `contextAsyncAction`, and custom `contentView` combinations
- `fk_addLoadMore(...)` — same overload matrix for the footer
- `fk_pullToRefresh`, `fk_loadMore`
- `fk_beginPullToRefresh(animated:)`, `fk_beginLoadMore()`
- `fk_resetLoadMoreState()`, `fk_setLoadMoreHidden(_:)`, `fk_resetLoadMoreAfterPullToRefresh()`
- `fk_removePullToRefresh()`, `fk_removeLoadMore()`, `fk_removeRefreshComponents()`
- `fk_refreshPolicy`

## Best practices

- Perform UI mutations on the main actor.
- Use context handlers when completions can arrive after a newer refresh has started.
- Call an appropriate `end*` method on every path (success, empty, no more data, error, cancel).
- After a successful pull-to-refresh that resets pagination, call `fk_resetLoadMoreState()` when appropriate.

## Notes

- `loadMoreTriggerMode == .manual` disables automatic bottom triggering; use `fk_beginLoadMore()` or `beginLoadingMore()`. The footer may sit below the visible rect until you scroll near the bottom.
- `isSilentRefresh` runs the header action without expanding the visible header; still call `endRefreshing` when work completes.
- `fk_setLoadMoreHidden` is stored on the control: it is not overwritten on the next scroll (unlike assigning `fk_loadMore?.isHidden` directly).
- Automatic load-more arms once per “approach the bottom”; after a run (success, failure, or no-more), the user must scroll slightly upward before the next automatic trigger — this avoids repeated fires while a finger rests at the end of the list.

## License

`FKRefresh` is part of FKKit and follows the same license as this repository.
