# FKKit

A modular UIKit component library for iOS.

- `FKUIKit`: foundational UI components and presentation infrastructure
- `FKBusinessKit`: business-oriented UI compositions built on top of `FKUIKit`

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
| FKUIKit | `import FKUIKit` | core reusable UIKit components (`FKBar`, `FKButton`, `FKPresentation`, `FKBadge`, `FKSkeleton`, `FKEmptyState`, …) |
| FKBusinessKit | `import FKBusinessKit` | business-layer components, depends on `FKUIKit` |

Dependency graph:

```text
FKUIKit
FKBusinessKit   → FKUIKit
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

### FKBusinessKit

```swift
import FKBusinessKit

let filterBar = FKFilterBarPresentation()
let filterHost = FKFilterBarHost(filterBar: filterBar)
```

## Migration notes (from FKUIKit repo)

- Repository has been renamed from `FKUIKit` to `FKKit`.
- SwiftPM package name is now `FKKit`.
- Products are consolidated to `FKUIKit` and `FKBusinessKit`.
- Example app structure has been refactored to the new `FKKitExamples` layout.

## Recent updates (0.9.0)

- **`FKEmptyState`**: unified placeholders for **loading**, **empty**, and **error** (plus **content** to hide the overlay) on `UIView` / `UIScrollView`. Includes `FKEmptyStateModel`, `FKEmptyStatePhase`, preset **`FKEmptyStateScenario`**, optional custom middle view, keyboard-safe layout, and refresh-control-aware loading skip. See `Sources/FKUIKit/Components/FKEmptyState/`.
- **Examples**: `FKEmptyStateExamplesHubViewController` and related screens under `Examples/FKKitExamples/.../EmptyState/`.
- **Example app menu**: grouped by **FKUIKit** / **FKBusinessKit**, sorted A→Z within each section.

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
