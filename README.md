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
| FKUIKit | `import FKUIKit` | core reusable UIKit components |
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

## Recent updates (0.6.0)

- Introduced `FKBusinessKit` as a dedicated business component layer.
- Added a full filter module (filter bar host/presentation, panel/list/chips/course generic views, and example app demos).
- Refactored examples from `FKUIKitDemo` to `FKKitExamples`.
- Polished component APIs in `FKButton` and `FKBarPresentation`.

## Versioning

This project follows SemVer. See `CHANGELOG.md` and git tags for releases.

## License

[MIT License](LICENSE)
