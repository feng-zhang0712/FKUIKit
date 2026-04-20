# Changelog

This file follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Planned
- Unit test target and `Tests/` directory
- Optional: Example app under `Examples/` (depending on this package locally)

## [0.13.0] - 2026-04-20

### Added (FKCoreKit FKStorage)
- **`FKStorage`**: native persistence under `Sources/FKCoreKit/Storage/` — protocol-oriented API (`FKStorageBackend`, `FKCodableStorage`), **UserDefaults** (prefixed keys), **Keychain** (generic password), **file** storage under Application Support with `index.json` + hashed filenames, and **in-memory** cache; JSON **`Codable`** values with optional TTL via internal **`ExpiringRecord`**; unified **`FKStorageError`**; **`FKStorageKey`** / **`FKStorageStringKey`**; **`StorageAsync`** `async`/`await` overloads; English module **`Storage/README.md`**; full Swift documentation comments across the module.

### Added (Package)
- **`Package.swift`**: **`macOS(.v10_15)`** platform so `swift build` on macOS satisfies CryptoKit and Swift concurrency availability for `FKCoreKit`.

### Added (Examples)
- **`FKStorageExampleViewController`** and **`FKStorageExampleModels`** under `Examples/FKKitExamples/.../FKCoreKit/Storage/` (UserDefaults, Keychain, file, memory, TTL, purge, async).
- **Example menu**: **FKStorage** entry under **FKCoreKit**.

### Fixed (FKStorage)
- **`StorageAsync`**: use **`await Task.yield()`** and explicit **`return`** where required so Swift 6 does not report redundant-`await` warnings when calling async storage APIs.

### Notes
- **`FKCoreKit.swift`**: module namespace marker documents **FKNetwork** and **FKStorage**.

## [0.12.0] - 2026-04-20

### Added (FKCoreKit FKNetwork)
- **`FKNetwork`**: native **`URLSession`** networking stack under `Sources/FKCoreKit/Network/` — protocol-oriented API (`Requestable`, `Networkable`, `Cacheable`, interceptors, signing, token refresh), closure + **async/await**, environment config, two-level cache, upload/download with progress, request deduplication, reachability hook, and English module **README**.
- Full Swift documentation comments across the networking module.

### Added (Examples)
- **`FKNetworkExampleViewController`** and **`FKNetworkExampleModels`** under `Examples/FKKitExamples/.../FKCoreKit/Network/` (GET/POST, headers, caching, cancellation, upload/download, resume data).
- Example sources reorganized by product (**`FKUIKit`**, **`FKCoreKit`**, **`FKCompositeKit`**) for clearer navigation.

### Changed
- **Example menu**: **FKCoreKit** section includes **FKNetwork** entry.

### Removed
- **Breaking**: Legacy networking stubs removed from **`FKCompositeKit`** (`Sources/FKCompositeKit/Network/*`). Use **`FKCoreKit`** **`FKNetwork`** instead.

## [0.11.0] - 2026-04-19

### Added (FKCompositeKit FKListKit)
- **`FKListPlugin`**: composition-first list coordinator for `UITableView` / `UICollectionView` without base controller inheritance.
- **Pagination + state orchestration** via **`FKPageManager`** and **`FKListStateManager`**: initial skeleton (optional), pull-to-refresh, load-more, empty/error overlays, and load-more failure UX.
- **List state drivers** (`FKListStateUIDrivers`) for decoupled UI integration (empty state, skeleton host, primary surface, and refresh controls).

### Added (Examples)
- **`FKListKitTableExampleViewController`**: end-to-end mock demo (random data, empty, failures, 3-page paging, skeleton, empty/error overlays).

### Changed
- **Breaking**: Renamed SwiftPM product and target **`FKBusinessKit`** → **`FKCompositeKit`**. Update `Package.swift` / Xcode package dependencies, `import FKCompositeKit`, and the on-disk module path to `Sources/FKCompositeKit`.
- **Breaking**: Moved Filters sources to `FKCompositeKit` (from the legacy `FKBusinessKit` path) to align with product naming.

## [0.10.0] - 2026-04-19

### Added (FKUIKit FKRefresh)
- **Pull-to-refresh & load-more** for any `UIScrollView`: `UIScrollView.fk_addPullToRefresh` / `fk_addLoadMore`, `fk_beginPullToRefresh`, `fk_beginLoadMore`, `fk_resetLoadMoreAfterPullToRefresh`.
- **`FKRefreshControl`** / **`FKRefreshKind`**: state machine (`FKRefreshState` including `listEmpty`), weak scroll view attachment, main-queue `begin*` / `end*` APIs, duplicate-request guards, footer auto-hide when content is shorter than the viewport, baseline `contentInset` / `verticalScrollIndicatorInsets` sync, optional silent refresh and minimum loading visibility duration.
- **`FKRefreshConfiguration`** & **`FKRefreshText`**: thresholds, timing, tint, localized copy, footer safe-area padding.
- **`FKRefreshSettings`**: app-wide default configurations when `configuration` is omitted (assign on the main thread).
- **`FKRefreshPagination`**: simple page index helper (`resetForNewRequest`, `advance`).
- **`FKRefreshControlDelegate`**: optional state callbacks.
- **Indicators**: **`FKDefaultRefreshContentView`** (arrow + spinner + label; arrow hosted above label to avoid overlap), **`FKGIFRefreshContentView`**, **`FKHostedRefreshContentView`** (host e.g. Lottie without a dependency).

### Added (Examples)
- **`FKRefreshExamplesHubViewController`** and demos under **`Examples/FKKitExamples/.../Refresh/`** (default, dots, GIF, hosted, configuration, global settings, delegate, pagination, collection view, plain scroll view).
- **`ExampleMenuViewController`**: **FKRefresh** menu entry.

## [0.9.1] - 2026-04-19

### Changed (FKUIKit)
- **`Types.swift`**: shared closure typealiases renamed with an `FK` prefix — **`FKVoidHandler`**, **`FKValueHandler`**, **`FKOptionalValueHandler`**, **`FKErrorHandler`**, **`FKResultHandler`** (replaces `VoidHandler`, `ValueHandler`, etc.).
- **`FKBar`**: selection APIs (`selectItem`, `selectIndex`, `deselectItem`, `deselectIndex`) now take `completion: FKVoidHandler?` instead of `VoidHandler?`.
- **`FKBar.Item.FKButtonSpec`**: `titleByState` / `subtitleByState` use **`FKButton.LabelAttributes`**; per-slot images use **`FKButton.ImageAttributes`** (aligned with `FKButton` naming).
- **`FKBarPresentation`**: `applyConfiguration` and `dismissPresentation` completion parameters use **`FKVoidHandler`**.

### Changed (Examples)
- **`FKBarExampleViewController`**, **`FKBarPresentationExampleViewController`**, **`FKPresentationExampleViewController`**: English copy/comments; bar item specs updated for **`LabelAttributes`**.

### Migration (0.9.1)
- Replace any direct use of `VoidHandler`, `ValueHandler`, `OptionalValueHandler`, `ErrorHandler`, or `ResultHandler` with the **`FK*Handler`** names above.
- In **`FKBar.Item.FKButtonSpec`**, replace **`FKButton.Text`** / **`FKButton.Image`** with **`FKButton.LabelAttributes`** / **`FKButton.ImageAttributes`**.

## [0.9.0] - 2026-04-19

### Added (FKUIKit FKEmptyState)
- **`FKEmptyStatePhase`**: `content` (hide overlay), `loading`, `empty`, `error` (retry button enforced in the view).
- **`FKEmptyStateModel`** / **`FKEmptyStateButtonStyle`**: configurable copy, fonts, colors, image, gradient, `blockingOverlayAlpha`, loading spinner style, keyboard avoidance (`adjustsPositionForKeyboard` + `keyboardLayoutGuide`), pull-to-refresh skip (`skipsLoadingWhileRefreshing`), optional `customAccessoryView` + **`FKEmptyStateCustomPlacement`** (e.g. Lottie host).
- **`FKEmptyStateScenario`**: `CaseIterable` presets (`noNetwork`, `noSearchResult`, `loadFailed`, `noPermission`, `notLoggedIn`, …) via **`FKEmptyStateModel.scenario(_:)`**; fluent **`withTitle` / `withDescription` / `withImage` / `withButtonTitle` / `withPhase`**.
- **`FKEmptyStateView`**: full-bleed overlay, safe-area–centered stack, tap-to-dismiss keyboard (gesture does not steal `UIControl` taps), default opaque **`systemBackground`** so underlying lists do not show through in landscape.
- **`UIView` extensions**: `fk_applyEmptyState`, `fk_hideEmptyState`, `fk_emptyStateView` / `fk_emptyStateModel` (associated overlay; `UIScrollView` pins to **`frameLayoutGuide`**).
- **`UIScrollView` extensions**: `fk_showEmptyState`, `fk_updateEmptyState(_:)`, `fk_updateEmptyStateVisibility`, `fk_refreshEmptyStateAutomatically`, **`fk_updateEmptyState(itemCount:…)`**; **`UITableView.fk_totalRowCount`** / **`fk_updateEmptyStateForTable`**; **`UICollectionView.fk_totalItemCount`**.
- **`FKEmptyStateGlobalDefaults.template`** for app-wide baseline styling.
- **`fk_emptyStateAssertMainThread()`** guard on public entry points.

### Changed (Examples)
- **`ExampleMenuViewController`**: table grouped by **FKUIKit** then **FKCompositeKit**; rows sorted alphabetically by title; **`insetGrouped`** style; navigation title **FKKit Examples**.
- **`FKKitExamples`**: **`FKEmptyStateExamplesHubViewController`** and demos under **`Examples/EmptyState/`** (scenario gallery, phase switcher, interactive sandbox, retry→still-fails).

## [0.8.0] - 2026-04-19

### Added (FKUIKit FKSkeleton)
- Skeleton loading UI for placeholders: `FKSkeletonView`, `FKSkeletonContainerView`, `FKSkeletonConfiguration` (base/highlight colors, corner radius, shimmer / breathing / static modes, animation duration, shimmer direction), and thread-safe `FKSkeleton.defaultConfiguration`.
- `UIView.fk_showSkeleton` / `fk_hideSkeleton` overlays (optional safe-area pinning, interaction blocking); helpers on `UITableView` / `UICollectionView` for visible cells.
- Unified shimmer for containers (`usesUnifiedShimmer`): one masked gradient over all blocks for smoother scrolling; per-block mode when disabled.
- `FKSkeletonPresets` for list rows, cards, text blocks (including per-line width ratios), and grid cells; `FKSkeletonAvatarStyle` for circular or rounded avatars.
- `FKSkeletonTableViewCell` and `FKSkeletonCollectionViewCell` for skeleton-only reuse identifiers, plus `removeAllSkeletonSubviews()` on containers.

### Changed (Examples)
- `FKKitExamples`: added `FKSkeletonExampleViewController` (single-scroll catalog of APIs) and main-menu entry under `Examples/.../Skeleton/`.

## [0.7.0] - 2026-04-19

### Added (FKUIKit FKBadge)
- `FKBadge` overlay system for `UIView`, `UIBarButtonItem`, and `UITabBarItem`: dot, numeric (with overflow formatting), and text badges; configurable anchor (corners), offset, appearance (`FKBadgeConfiguration`), entrance animations, and visibility policy (including global hide/restore).
- `UIView+FKBadge`, `UIBarButtonItem+FKBadge`, `UITabBarItem+FKBadge` convenience APIs; optional swizzling so bar items update when system images change.

### Changed (Examples)
- `FKKitExamples`: added `FKBadgeExamplesHubViewController.swift` (hub, categorized demo screens, and shared helpers in one file) and main-menu entry; scene uses programmatic root only (`Info.plist` no longer loads unused `Main` storyboard); removed invalid `ViewController` class from `Main.storyboard` placeholder.

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

### Added (FKCompositeKit Filters)
- Added subtitle support for filter bar items via `FKFilterBarPresentation.BarItemModel.subtitle`.
- Added rich text support for filter bar and filter options using `AttributedString` (`attributedTitle` / `attributedSubtitle`).
- Added optional cell customization hooks in filter panels so integrators can fully control table/grid cell rendering.

### Changed (FKCompositeKit Filters)
- Extended `FKFilterBarPresentation.BarItemAppearance` with subtitle styling and layout controls (`subtitle` colors/fonts, title/subtitle alignment, and title-subtitle spacing).
- Updated default cell rendering in list-based panels to support title + subtitle content while preserving existing fallback behavior.
- Changed custom cell hook semantics to explicit override mode: when a custom closure is provided, default cell configuration is skipped.

### Changed (Examples)
- Updated filter example bar items to demonstrate subtitle and attributed title/subtitle usage.

### Docs (FKUIKit Presentation)
- Added inline documentation to `FKPresentationRepositionProbeView` and `FKPresentationRepositionCoordinator` for host-observation and reposition scheduling behavior.

## [0.6.1] - 2026-04-17

### Added (FKCompositeKit Filters)
- Added configurable panel height behavior via `FKFilterPanelHeightBehavior` (`automatic` / `capped` / `fixed` / `screenFraction`) and integrated it across list/chips/two-column panels.
- Added `FKFilterPanelFactory` to centralize panel construction and state wiring from lightweight data closures.
- Added `FKFilterTwoColumnGridViewController` for left-list + right-grid course-like layouts with section header support.
- Added richer filter bar lifecycle callbacks, including should-present and will-dismiss delegation.

### Changed (FKCompositeKit Filters)
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
- SwiftPM products were consolidated to `FKUIKit` and `FKCompositeKit` as top-level deliverables.
- Example project structure migrated from `FKUIKitDemo` to `FKKitExamples` with new app/bootstrap wiring and resource layout.

### Added (FKCompositeKit)
- New `FKCompositeKit` product and target with filter-focused business UI components.
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

[Unreleased]: https://github.com/feng-zhang0712/FKKit/compare/0.13.0...HEAD
[0.13.0]: https://github.com/feng-zhang0712/FKKit/compare/0.12.0...0.13.0
[0.12.0]: https://github.com/feng-zhang0712/FKKit/compare/0.11.0...0.12.0
[0.11.0]: https://github.com/feng-zhang0712/FKKit/compare/0.10.0...0.11.0
[0.10.0]: https://github.com/feng-zhang0712/FKKit/compare/0.9.1...0.10.0
[0.9.1]: https://github.com/feng-zhang0712/FKKit/compare/0.9.0...0.9.1
[0.9.0]: https://github.com/feng-zhang0712/FKKit/compare/0.8.0...0.9.0
[0.8.0]: https://github.com/feng-zhang0712/FKKit/compare/0.7.0...0.8.0
[0.7.0]: https://github.com/feng-zhang0712/FKKit/compare/0.6.4...0.7.0
[0.6.4]: https://github.com/feng-zhang0712/FKKit/compare/0.6.3...0.6.4
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
