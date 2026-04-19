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

## Recent updates (0.6.3)

- **FKButton**: global defaults (`FKButton.GlobalStyle`), loading styles (`LoadingPresentationStyle` / `performWhileLoading`), tap throttling, expanded hit testing, IB inspectables, and alignment-aware stack layout (defaults center icon+title as a group).
- **FKButton**: clearer type names `LabelAttributes` / `ImageAttributes` with `Text` / `Image` kept as compatibility typealiases.
- **Examples**: FKButton samples split into a hub plus focused screens (basics, layout, interaction, appearance, loading, advanced).

## Recent updates (0.6.2)

- Added subtitle + attributed text support for filter bar items and filter options to cover richer business display requirements.
- Added opt-in cell customization hooks for list and grid panels, with explicit "custom overrides default" behavior.
- Extended filter bar appearance configuration with subtitle alignment and title/subtitle spacing controls.
- Improved FKPresentation internals documentation for reposition probe/coordinator responsibilities and scheduling semantics.

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
