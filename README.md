# FKKit

A modular UIKit component library for iOS.

- `FKUIKit`: foundational UI components and presentation infrastructure
- `FKCoreKit`: foundational non-UI capabilities (networking, storage, logging, permissions, utilities, etc.)
- `FKCompositeKit`: composed UI modules built on top of `FKUIKit` and `FKCoreKit`

## Requirements

- iOS 15.0+
- Swift 6.0+
- Xcode (build with an iOS destination; `swift build` on macOS won’t work because of UIKit)

## Swift Package Manager

Repository URL:

`git@github.com:feng-zhang0712/FKKit.git`

In Xcode:

1. **File → Add Package Dependencies…**
2. Paste the repository URL and pick a version rule (e.g. *Up to Next Major*).
3. Select the products you need.

### Products and imports

| Product | Import | Notes |
|---|---|---|
| FKUIKit | `import FKUIKit` | core reusable UIKit components (`FKBar`, `FKButton`, `FKPresentation`, `FKBadge`, `FKSkeleton`, `FKEmptyState`, `FKRefresh`, …) |
| FKCoreKit | `import FKCoreKit` | core non-UI modules and shared infrastructure utilities (includes **FKNetwork** — `Sources/FKCoreKit/Network/README.md`; **FKStorage** — `Sources/FKCoreKit/Storage/README.md`; **FKAsync** — `Sources/FKCoreKit/Async/README.md`; **FKLogger** — `Sources/FKCoreKit/Logger/README.md`) |
| FKCompositeKit | `import FKCompositeKit` | composite UI modules and higher-level integrations, depends on `FKUIKit` and `FKCoreKit` |

Dependency graph:

```text
FKUIKit
FKCoreKit
FKCompositeKit   → FKUIKit + FKCoreKit
```

### Local package (development)

Use **Add Local…** and select the repository root (the folder that contains `Package.swift`).

## Quick start

### FKUIKit

```swift
import UIKit
import FKUIKit

let bar = FKBar()
var config = FKBar.Configuration.default
config.itemSpacing = 8
bar.setConfiguration(config)
```

### FKBadge (UIView)

```swift
import FKUIKit

badgeHostView.fk_badge.setAnchor(.topTrailing)
badgeHostView.fk_badge.showCount(12)
```

### FKSkeleton (loading placeholders)

```swift
import FKUIKit

contentView.fk_showSkeleton()
// …load data…
contentView.fk_hideSkeleton()
```

### FKRefresh (pull to refresh & load more)

```swift
import FKUIKit

tableView.fk_addPullToRefresh { /* reload */ }
tableView.fk_addLoadMore { /* next page */ }
// When done: tableView.fk_pullToRefresh?.endRefreshing()
```

### FKCompositeKit

```swift
import FKCompositeKit

let filterBar = FKFilterBarPresentation()
let filterHost = FKFilterBarHost(filterBar: filterBar)
```

## Migration notes (from FKUIKit repo)

- Repository has been renamed from `FKUIKit` to `FKKit`.
- SwiftPM package name is now `FKKit`.
- Products are consolidated to `FKUIKit`, `FKCoreKit`, and `FKCompositeKit`.
- Example app structure has been refactored to the new `FKKitExamples` layout.

## Recent updates (0.15.0)

- **`FKLogger`** (in `FKCoreKit`): native logging and debugging module with 5 levels, build-aware defaults (`DEBUG`/`RELEASE`), protocol-oriented formatting/output/file manager abstractions, ANSI color + emoji console output, asynchronous thread-safe pipeline, file persistence (daily + size rotation), storage cap cleanup, clear/export APIs, and model/collection pretty-print helpers. Documentation: `Sources/FKCoreKit/Logger/README.md`.
- **Crash diagnostics**: uncaught exception handler, common fatal signal capture, custom exception logging, and network diagnostic capture APIs.
- **Examples**: **FKLogger** demo at `Examples/FKKitExamples/.../FKCoreKit/Logger/`; menu entry under **FKCoreKit**.

## Recent updates (0.14.0)

- **`FKAsync`** (in `FKCoreKit`): native GCD scheduling — safe main-thread execution, global/serial/concurrent queues, cancelable delay tasks, debounce/throttle helpers, dispatch group wrapper, and executors. Documentation: `Sources/FKCoreKit/Async/README.md`.
- **Examples**: **FKAsync** demo at `Examples/FKKitExamples/.../FKCoreKit/Async/`; menu entry under **FKCoreKit**.

## Recent updates (0.13.0)

- **`FKStorage`** (in `FKCoreKit`): protocol-based persistence — **UserDefaults**, **Keychain**, **file** (Application Support), and **memory** cache; **`Codable`** + optional TTL; **`FKStorageError`**; async helpers. Documentation: `Sources/FKCoreKit/Storage/README.md`.
- **Examples**: **FKStorage** demo at `Examples/FKKitExamples/.../FKCoreKit/Storage/`; menu entry under **FKCoreKit**.
- **SwiftPM**: **`macOS 10.15+`** declared alongside iOS so `swift build` works for `FKCoreKit` on macOS.

## Recent updates (0.12.0)

- **`FKNetwork`** (in `FKCoreKit`): production-oriented **`URLSession`** layer — environments, **`Requestable`** / **`FKNetworkClient`**, interceptors, signing, token refresh retry, memory+disk cache, upload/download, and async/await. Documentation: `Sources/FKCoreKit/Network/README.md`.
- **Examples**: sample screens grouped under **`FKUIKit`**, **`FKCoreKit`**, and **`FKCompositeKit`**; **FKNetwork** demo at `Examples/FKKitExamples/.../FKCoreKit/Network/`.
- **Breaking**: removed legacy **`FKCompositeKit/Network`** stubs; migrate to **`FKCoreKit`** **FKNetwork**.

## Recent updates (0.11.0)

- **`FKListKit`** (in `FKCompositeKit`): composition-based list plugin (**`FKListPlugin`**) that coordinates pagination (**`FKPageManager`**), list states (**`FKListStateManager`**), refresh/load-more, skeleton, and empty/error overlays for table/collection views.
- **Examples**: `FKListKitTableExampleViewController` under `Examples/FKKitExamples/.../ListKit/` demonstrates initial skeleton, random mock data, empty/error scenarios, and a 3-page paging flow.

## Recent updates (0.9.1)

- **Shared types**: closure aliases in `Types.swift` are now prefixed (**`FKVoidHandler`**, **`FKValueHandler`**, …); **`FKBar`** / **`FKBarPresentation`** completion parameters use them.
- **`FKBar.Item.FKButtonSpec`**: title/subtitle maps use **`FKButton.LabelAttributes`**; images use **`FKButton.ImageAttributes`**.
- **Examples**: Bar, BarPresentation, and Presentation sample screens updated (English copy; bar specs aligned with the types above). See `CHANGELOG.md` for migration notes.

## Recent updates (0.9.0)

- **`FKEmptyState`**: unified placeholders for **loading**, **empty**, and **error** (plus **content** to hide the overlay) on `UIView` / `UIScrollView`. Includes `FKEmptyStateModel`, `FKEmptyStatePhase`, preset **`FKEmptyStateScenario`**, optional custom middle view, keyboard-safe layout, and refresh-control-aware loading skip. See `Sources/FKUIKit/Components/FKEmptyState/`.
- **Examples**: `FKEmptyStateExamplesHubViewController` and related screens under `Examples/FKKitExamples/.../EmptyState/`.
- **Example app menu**: grouped by **FKUIKit** / **FKCompositeKit**, sorted A→Z within each section.

## Branching & Collaboration (Recommended)

This repo follows a lightweight workflow to keep `main` stable while you iterate on new APIs/structure.

Branch roles:

- `main`: stable history. It only receives changes after they have been validated and merged from `develop`.
- `develop`: the integration branch for ongoing development. All new work should start from here.
- `feature/*`: short-lived branches for a specific feature/refactor. Create from `develop` and open a PR back to `develop`.
- `bugfix/*`: short-lived branches for targeted bug fixes (no new features). Create from `develop` and open a PR back to `develop`.
- `hotfix/*` (optional): very short-lived fixes that must be applied to `main` immediately. After the fix lands on `main`, also merge it back to `develop`.

Collaboration tips:

- Prefer small PRs focused on one goal (one feature or one refactor).
- Keep your `feature/*` / `bugfix/*` branch up to date with `develop` before requesting a review.
- Use clear PR titles (for example: `feat: add FKFilter chips view`, `fix: correct FKBar selection alignment`).

## Versioning

This project follows SemVer. See `CHANGELOG.md` and git tags for releases.

## License

[MIT License](LICENSE)
