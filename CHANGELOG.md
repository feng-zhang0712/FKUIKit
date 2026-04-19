# Changelog

This file follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Planned
- Unit test target and `Tests/` directory
- Optional: Example app under `Examples/` (depending on this package locally)

## [0.6.3] - 2026-04-19

### Added (FKButton)
- `FKButton.GlobalStyle` for app-wide defaults (`minimumTapInterval`, long-press timing, disabled dimming, optional `defaultAppearances`, `applyPerNewButton`).
- `LoadingPresentationStyle` (`.overlay` / `.replacesContent`) with `ReplacedContentLoadingOptions`, `loadingActivityIndicatorColor`, and `performWhileLoading` for async work while showing the built-in spinner.
- `FKButton+Chaining.swift` fluent helpers (appearance, content, interaction, loading, alignment).
- `FKButton+Storyboard.swift` `@IBInspectable` properties for common knobs in Interface Builder.
- Throttled primary actions via `minimumTapInterval` (applied in `sendAction(_:to:for:)`), plus `hitTestEdgeInsets` for a larger tap target without changing layout.
- `contentHorizontalAlignment` / `contentVerticalAlignment` drive Auto Layout between `contentContainerView` and the content stack (reapplied on layout-direction changes).

### Changed (FKButton)
- Renamed per-state title/image value types to `LabelAttributes` and `ImageAttributes` for clarity; `FKButton.Text` and `FKButton.Image` remain as `public typealias` aliases.
- Default `contentHorizontalAlignment` / `contentVerticalAlignment` are `.center` / `.center` so icon+title groups center like a typical `UIButton` (use `.fill` when the stack should span the padded area).
- Expanded documentation across `FKButton`, `Appearance`, `Content`, and `Elements`.

### Changed (Examples)
- Replaced the monolithic `FKButtonExampleViewController` with `FKButtonExamplesHubViewController` and topic screens (basics, layout, interaction, appearance, loading, advanced/IB), with shared demo builders in `FKButtonExampleDemoContentBuilders.swift`.
- Root example menu now opens the FKButton hub with an updated subtitle.

## [0.6.2] - 2026-04-17

### Added (FKBusinessKit Filters)
- Added subtitle support for filter bar items via `FKFilterBarPresentation.BarItemModel.subtitle`.
- Added rich text support for filter bar and filter options using `AttributedString` (`attributedTitle` / `attributedSubtitle`).
- Added optional cell customization hooks in filter panels so integrators can fully control table/grid cell rendering.

### Changed (FKBusinessKit Filters)
- Extended `FKFilterBarPresentation.BarItemAppearance` with subtitle styling and layout controls (`subtitle` colors/fonts, title/subtitle alignment, and title-subtitle spacing).
- Updated default cell rendering in list-based panels to support title + subtitle content while preserving existing fallback behavior.
- Changed custom cell hook semantics to explicit override mode: when a custom closure is provided, default cell configuration is skipped.

### Changed (Examples)
- Updated filter example bar items to demonstrate subtitle and attributed title/subtitle usage.

### Docs (FKUIKit Presentation)
- Added inline documentation to `FKPresentationRepositionProbeView` and `FKPresentationRepositionCoordinator` for host-observation and reposition scheduling behavior.

## [0.6.1] - 2026-04-17

### Added (FKBusinessKit Filters)
- Added configurable panel height behavior via `FKFilterPanelHeightBehavior` (`automatic` / `capped` / `fixed` / `screenFraction`) and integrated it across list/chips/two-column panels.
- Added `FKFilterPanelFactory` to centralize panel construction and state wiring from lightweight data closures.
- Added `FKFilterTwoColumnGridViewController` for left-list + right-grid course-like layouts with section header support.
- Added richer filter bar lifecycle callbacks, including should-present and will-dismiss delegation.

### Changed (FKBusinessKit Filters)
- Refactored and split filter panel controllers into focused files (`SingleList`, `TwoColumnList`, `TwoColumnGrid`) with clearer naming and responsibilities.
- Generalized panel kind semantics and factory source naming (`twoColumnList` / `twoColumnGrid`) to reduce business-coupled terminology.
- Unified reusable option-item styling with `FKFilterPillStyle` and kept backward compatibility through a deprecated `FKFilterChipStyle` typealias.
- Expanded documentation comments across key filter models/configurations/controllers to improve component usability.

### Changed (Examples)
- Updated filter examples to use the new panel factory source names and two-column grid presentation for the "All Courses" panel.
- Expanded mock filter data options and tuned demo panel typography/behavior for better parity with real business layouts.

## [0.6.0] - 2026-04-16

### Breaking changes
- Package and repository direction has been unified under `FKKit`, replacing the previous `FKUIKit`-named repository layout.
- SwiftPM products were consolidated to `FKUIKit` and `FKBusinessKit` as top-level deliverables.
- Example project structure migrated from `FKUIKitDemo` to `FKKitExamples` with new app/bootstrap wiring and resource layout.

### Added (FKBusinessKit)
- New `FKBusinessKit` product and target with filter-focused business UI components.
- Added filter module infrastructure including bar host/presentation, panel support, list/chips/course views, and demo data provider.
- Added end-to-end filter demo entry points and host demo view controllers for practical integration reference.

### Changed (Examples)
- Reorganized demo app files and naming from "Demo" to "Examples" terminology across project and source structure.
- Updated example menu flow and application entry composition for the new module layout.

### Changed (FKUIKit)
- Updated `FKBarPresentation` configuration path for the refactored package structure.
- Refined `FKButton` appearance/content implementation details for better consistency with the new package organization.

## [0.5.1] - 2026-04-14

### Fixed (FKBar)
- Preserve selected-item alignment after bounds changes (for example, device rotation) by reapplying selection scroll positioning during layout updates.
- Hardened horizontal offset clamping to avoid invalid scroll ranges when content becomes narrower than the viewport.

### Fixed (FKPresentation)
- Removed mask alpha double-application so dimming strength remains stable after show/reposition and rotation.
- Reposition flow now updates mask geometry/color through a dedicated frame-refresh path instead of resetting mask visibility state.
- Increased layout probe height during content measurement to avoid transient Auto Layout warnings when content uses stacked constraints with container insets.

## [0.5.0] - 2026-04-13

### Added (FKBarPresentation)
- `FKBarPresentation.Configuration.Behavior` now conforms to `Equatable` and `Sendable`.
- Added behavior presets: `.default`, `.keepPanelOnSelectionChange`, `.selectionDrivenDismiss`.

### Changed (FKBarPresentation)
- `applyConfiguration` now updates `FKPresentation` via `updateConfiguration` when already presented, so runtime config changes are applied immediately.
- Refactored panel content resolution into a dedicated helper to centralize priority and reduce duplicated logic.

### Changed (FKPresentation)
- Added defensive value normalization in configuration initializers (alpha, durations, sizes, radius, min/max bounds).
- Reposition pass now reapplies appearance to keep chrome style and content inset wrapper state consistent after frame updates.
- `content.containerInsets` updates now propagate to existing wrapper constraints and correctly handle RTL leading/trailing mapping.

### Fixed (FKPresentation)
- `animation.show` end state now respects `appearance.alpha` instead of forcing content chrome alpha to `1`.
- `reposition.listenTraitCollectionChanges` now has effective runtime behavior by observing trait changes in host container.
- Dismiss cleanup now releases transient overlay references more completely to avoid stale state on reuse.

## [0.4.0] - 2026-04-13

### Breaking changes (FKBar)
- `FKBar.Configuration.Appearance` now exposes `cornerStyle` and `border` as first-class models.
- Removed legacy direct accessors from `FKBar.Configuration.Appearance` (`cornerRadius`, `cornerCurve`, `maskedCorners`, `borderWidth`, `borderColor`); migrate to `appearance.cornerStyle.*` and `appearance.border.*`.

### Added (FKBar)
- Added `FKBar.Configuration.Appearance.ShadowPathStrategy` with automatic rounded `shadowPath` updates on layout.
- Added internal configuration storage API used by `setConfiguration` to avoid duplicate apply passes.
- Added `FKBar.Item.FKButtonSpec.setAppearances(_:)` for one-call normal/selected/highlighted/disabled setup.

### Changed (FKBar)
- `FKBar.Configuration` now clamps invalid values for spacing, alpha, shadow, and corner/border inputs.
- `FKBar` now applies default selection fallback visuals consistently across `UIButton`, `FKButton`, and custom wrapper items.
- `FKBar.Item.Layout` now normalizes invalid min/max constraints and clamps negative dimensions.
- `FKBar.Item.FKButtonSpec.apply(to:)` now batches updates through `FKButton.performBatchUpdates` to reduce redundant refreshes.
- Replaced recursive descendant lookup in configuration apply path with direct internal references to improve reliability and performance.

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

[Unreleased]: https://github.com/feng-zhang0712/FKKit/compare/0.6.3...HEAD
[0.6.3]: https://github.com/feng-zhang0712/FKKit/compare/0.6.2...0.6.3
[0.6.2]: https://github.com/feng-zhang0712/FKKit/compare/0.6.1...0.6.2
[0.6.1]: https://github.com/feng-zhang0712/FKKit/compare/0.6.0...0.6.1
[0.6.0]: https://github.com/feng-zhang0712/FKKit/compare/0.5.1...0.6.0
[0.5.1]: https://github.com/feng-zhang0712/FKKit/compare/0.5.0...0.5.1
[0.5.0]: https://github.com/feng-zhang0712/FKKit/compare/0.4.0...0.5.0
[0.4.0]: https://github.com/feng-zhang0712/FKKit/compare/0.3.0...0.4.0
[0.3.0]: https://github.com/feng-zhang0712/FKKit/compare/0.2.3...0.3.0
[0.2.3]: https://github.com/feng-zhang0712/FKKit/compare/0.2.2...0.2.3
[0.2.2]: https://github.com/feng-zhang0712/FKKit/compare/0.2.1...0.2.2
[0.2.1]: https://github.com/feng-zhang0712/FKKit/compare/0.2.0...0.2.1
[0.2.0]: https://github.com/feng-zhang0712/FKKit/compare/0.1.0...0.2.0
[0.1.0]: https://github.com/feng-zhang0712/FKKit/releases/tag/0.1.0
