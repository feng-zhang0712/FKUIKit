# FKUIKit

A lightweight UIKit component library for iOS:

- `FKButton`: a state-driven UIControl button
- `FKBar`: a horizontally scrolling item bar (tabs/chips/segmented-like)
- `FKPresentation`: an anchored overlay/panel (not `UIPresentationController`)
- `FKBarPresentation`: `FKBar` + `FKPresentation` as a single component
- `FKUIKitCore`: shared utilities

## Requirements

- iOS 15.0+
- Swift 6.0+
- Xcode (build with an iOS destination; `swift build` on macOS won’t work because of UIKit)

## Swift Package Manager

In Xcode:

1. **File → Add Package Dependencies…**
2. Paste the repository URL and pick a version rule (e.g. *Up to Next Major*).
3. Select the products you need.

### Products and imports

| Product | Import | Notes |
|---|---|---|
| FKUIKitCore | `import FKUIKitCore` | shared types/utilities |
| FKButton | `import FKButton` | button component |
| FKBar | `import FKBar` | depends on `FKButton`, `FKUIKitCore` |
| FKPresentation | `import FKPresentation` | anchored overlay/panel |
| FKBarPresentation | `import FKBarPresentation` | depends on `FKBar`, `FKPresentation`, `FKUIKitCore` |

Dependency graph:

```text
FKUIKitCore
FKButton            → FKUIKitCore
FKBar               → FKButton, FKUIKitCore
FKPresentation      → FKUIKitCore
FKBarPresentation   → FKBar, FKPresentation, FKUIKitCore
```

### Local package (development)

Use **Add Local…** and select the repository root (the folder that contains `Package.swift`).

## Quick start

### FKButton

```swift
import UIKit
import FKButton

let button = FKButton()
button.content = .textAndImage(.leading)
button.setTitles(
  normal: .init(text: "OK"),
  selected: .init(text: "Selected")
)
button.setAppearances(
  .init(
    normal: .filled(backgroundColor: .systemBlue),
    selected: .outlined(borderColor: .systemBlue)
  )
)
```

### FKBarPresentation

```swift
import FKBarPresentation

let barPresentation = FKBarPresentation(frame: .zero)
barPresentation.reloadBarItems([/* FKBar.Item */])
```

## Versioning

This project follows SemVer. See `CHANGELOG.md` and git tags for releases.

## License

[MIT License](LICENSE)
