# Changelog

This file follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Planned
- Unit test target and `Tests/` directory
- Optional: Example app under `Examples/` (depending on this package locally)

## [0.3.0] - 2026-04-13

### Breaking changes (FKButton)
- `FKButton.Appearance` now uses `cornerStyle` and `border` instead of direct `corner` / `borderWidth` / `borderColor` initializer parameters.
- `FKButton.Text` now uses `textTransform` (`none` / `uppercase` / `lowercase`) instead of `uppercased` / `lowercased`.

### Added (FKButton)
- Added batch update and convenience APIs: `performBatchUpdates`, `setTitles`, `setSubtitles`, `setImages`, `setLeadingImages`, `setTrailingImages`, and `setCustomContents`.
- Added configurable state resolution with `stateResolutionProvider`.
- Added rendered image padding cache for image content insets.

### Changed (FKButton)
- Improved internal refresh flow to avoid redundant content-layout rebuilds during state-only updates.
- Unified accessibility behavior by keeping the main `FKButton` as the primary accessibility element.
- Expanded and aligned API documentation across `FKButton`, `Appearance`, `Content`, and `Elements`.

### Changed (Demo)
- Updated `Examples/FKUIKitDemo` button, bar, and bar-presentation demos to the new `FKButton.Appearance` API.

## [0.2.3] - 2026-04-11

### Breaking changes (FKBar)
- `FKBar.Configuration`: renamed `stackViewAlignment` → **`alignment`** and `stackViewDistribution` → **`distribution`**.
- Added **`arrangement`** (`FKBar.Configuration.Arrangement`: `leading`, `center`, `trailing`, `between`, `around`, `evenlyDistributed`) to control horizontal item-row layout vs. the visible bar (scroll vs. centered group vs. distributed fill, with overflow fallback).

### Added (FKBar)
- Configuration-driven horizontal constraints between the scroll view and stack, recomputed when non-leading arrangements cross the overflow threshold (`layoutSubviews`).
- Selection auto-scroll skips repositioning when content fits; resets horizontal offset when appropriate.

### Fixed (FKPresentation)
- More robust embedded view-controller **content height** when computing panel size: avoid collapsed heights during ~1pt-tall layout probes, with expanded fitting, optional first-`UIScrollView` content height measurement, and a 220pt fallback before clamping.

## [0.2.2] - 2026-04-07

### Changed
- Localized all source files, core types, and demos to **English-only** (comments, assertion messages, and demo UI strings).
- Updated `README.md` and `CHANGELOG.md` to English to better support international usage.

## [0.2.1] - 2026-04-07

### Fixed
- `FKBarPresentation` demo: replace the log area `UILabel` with a scrollable `UITextView`, and cap the maximum text length to avoid slowdowns caused by unbounded log growth.
- `FKBarPresentation.dismissPresentation(animated:completion:)`: forward `completion` directly to `FKPresentation.dismiss` (remove redundant wrapping).

## [0.2.0] - 2026-04-05

### Breaking changes
- SwiftPM **product/target**: `FKPopover` was renamed to **`FKBarPresentation`**, and sources moved to `Sources/FKBarPresentation/`.
- Types and protocols: `FKPopover` → `FKBarPresentation`; `FKPopoverDelegate` → `FKBarPresentationDelegate`; `FKPopoverDataSource` → `FKBarPresentationDataSource`.
- Delegate method labels: `popover(_:…)` → **`barPresentation(_:…)`** (`shouldPresentFor` / `willPresentFor` / `didPresentFor` / sizing & content APIs).
- Closure types: `presentationContent` / `presentationViewController` now take `FKBarPresentation` instead of `FKPopover` as the first argument.
- Nested types: e.g. `PresentationDismissReason` is now under the **`FKBarPresentation`** namespace.

### Migration
- Replace `import FKPopover` with **`import FKBarPresentation`**, and update the selected product in Xcode.
- Update public type names and delegate/data source method signatures. Property names `delegate` / `dataSource` remain unchanged.

## [0.1.0] - 2026-04-04

### Added
- Multiple SwiftPM products: `FKUIKitCore`, `FKButton`, `FKBar`, `FKPresentation`, `FKPopover`
- `Package.swift`: `platforms: [.iOS(.v15)]`, `swiftLanguageModes: [.v6]`
- `README.md`, `LICENSE` (MIT), `CHANGELOG.md`, and an extended `.gitignore`

### Changed (for SwiftPM / Swift 6 compatibility)
- Use `nonisolated(unsafe)` on `static let default` for config types to satisfy Swift concurrency checks.
- Use `nonisolated(unsafe)` for `FKBarConfigurationAssociatedKeys` (associated object keys).
- Add missing module imports (e.g. `FKUIKitCore`, `FKButton`, `FKPresentation`, `FKBar`) across targets.
- Mark `FKPresentation` as `@MainActor`; `FKBarDelegate`, `FKPresentationDelegate`, `FKPresentationDataSource` are `@MainActor`.
- Mark `FKBar.Item.FKButtonSpec.apply(to:)` as `@MainActor`.
- Make `FKPopover.PresentationDismissReason` conform to `Sendable`.

<!-- Replace the links below with your repository URL when published -->
[Unreleased]: #
[0.3.0]: #
[0.2.3]: #
[0.2.2]: #
[0.2.1]: #
[0.2.0]: #
[0.1.0]: #
