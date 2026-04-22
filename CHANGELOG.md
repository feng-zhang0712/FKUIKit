# Changelog

This file follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Planned
- Unit test target and `Tests/` directory
- Optional: Example app under `Examples/` (depending on this package locally)

## [0.37.1] - 2026-04-22

### Added (FKUIKit FKStickyHeader)
- Added `FKStickyHeader` module under `Sources/FKUIKit/Components/StickyHeader/`:
  - `FKStickyEngine` (sticky computation and lifecycle dispatch)
  - `FKStickyConfiguration` (type-safe configuration: sticky offset, transition curve/distance, enable toggles)
  - `FKStickyTarget` (target model with progress/state/style callbacks)
  - `UIScrollView+FKStickyView` (one-line enable APIs for `UITableView` / `UICollectionView`, global defaults integration)
  - `FKStickyHeaderSwiftUIView` (SwiftUI bridge)
- Supported sticky behavior coverage:
  - multi-section push-off interaction (next header pushes current sticky header)
  - custom sticky reference offset to avoid navigation bars/top overlays
  - progress-driven transition animation callback (alpha/scale/background, etc.)
  - lifecycle callbacks (`willSticky` / `didSticky` / `didUnsticky`)
  - runtime controls (enable/disable, force active sticky target)

### Changed (FKUIKit FKStickyHeader)
- Improved integration stability for lazy header creation and reuse in table/collection lists.
- Optimized scrolling performance by avoiding per-frame target rebuild while keeping layout updates stable at 60fps.

### Added (Examples)
- Added a full `FKStickyHeader` scenario hub under:
  - `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/StickyHeader/`
- Added coverage including:
  - UITableView single/multi-section sticky
  - UICollectionView multi-section sticky
  - waterfall layout sticky
  - custom offset, animations, state callbacks, runtime toggle
  - dark mode, rotation, and performance (FPS indicator)

### Changed (Examples)
- Replaced legacy `Sticky` examples with `StickyHeader` examples and updated navigation entry.

## [0.37.0] - 2026-04-22

### Added (FKUIKit FKBlurView)
- Added a new high-performance blur module under `Sources/FKUIKit/Components/BlurView/`:
  - `FKBlurView` (UIKit blur view with system/custom backends)
  - `FKBlurConfiguration` (type-safe blur model with system styles, custom parameters, mode/backend selection)
  - `FKBlurGlobalDefaults` (global baseline configuration)
  - `FKSwiftUIBlurView` (SwiftUI adapter)
- Added full blur capability coverage:
  - system material styles (`light` / `dark` / `extraLight` / `systemMaterial` family, etc.)
  - custom blur parameters (`blurRadius`, `saturation`, `brightness`, `tintColor`, `tintOpacity`)
  - static and dynamic blur modes
  - mask support (`maskPath`, rounded mask convenience)
  - opacity control and Interface Builder bridges (`@IBDesignable`, `@IBInspectable`)
- Added image and view blur extensions:
  - `UIImage.fk_blurred(...)`
  - `UIView.fk_blurredSnapshot(...)`
  - `UIView.fk_blurredSnapshotAsync(...)`
- Added shared processing core `FKBlurImageProcessor` to reuse Core Image/Metal blur pipeline across `UIImage+Blur` and `UIView+Blur`.

### Changed (FKUIKit FKBlurView)
- Added complete English API documentation comments for public APIs and key internal flows across blur sources.
- Optimized custom image blur memory behavior by removing expensive pixel upsampling after downsample processing and restoring logical display size via `UIImage.scale`.

### Added (Examples)
- Added full FKBlurView example hub at:
  - `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/BlurView/FKBlurViewExamplesHubViewController.swift`
- Added scenario coverage including:
  - basic/system/custom blur demos
  - static vs dynamic blur
  - image blur and UIView snapshot blur (sync/async)
  - rounded/circle/custom-mask blur
  - opacity, global defaults, dark mode, rotation, and scroll performance
  - SwiftUI integration and XIB/Storyboard demo path
- Added `BlurView` entry to `Examples/.../Main/ExampleMenuViewController.swift`.
- Fixed XIB/Storyboard demo crash when nib resource is missing by adding safe nib existence guard and fallback path.

## [0.36.0] - 2026-04-22

### Added (FKUIKit FKTopNotification)
- Added a new lightweight global top floating notification module under `Sources/FKUIKit/Components/TopNotification/` with pure Swift UIKit implementation and SwiftUI interoperability:
  - `FKTopNotification`
  - `FKTopNotificationHandle`
  - `FKTopNotificationConfiguration`
  - `FKTopNotificationStyle` (`normal` / `success` / `error` / `warning` / `info`)
  - `FKTopNotificationPriority` with preemption support
  - `FKTopNotificationAction`
  - progress notification support with real-time updates
  - optional sound support on presentation
- Added serialized queue presentation to prevent stacked overlays, plus high-priority preemption (interrupt and present first).
- Added safe-area / notch / Dynamic Island aware top placement behavior:
  - when a navigation bar is visible, notification is pinned below the navigation bar
  - otherwise, notification is pinned below the top safe area inset

### Added (Examples)
- Added a complete FKTopNotification demo hub at:
  - `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/TopNotification/FKTopNotificationExamplesHubViewController.swift`
- Added full scenario coverage including:
  - five preset styles, subtitle, action button, custom color/icon
  - custom UIView and SwiftUI content hosting
  - progress notification with live updates
  - queueing behavior and priority preemption
  - swipe-to-dismiss, manual dismiss, custom duration, sound
  - global configuration, dark mode, rotation, notch/Dynamic Island safe area
- Added `TopNotification` entry in `ExampleMenuViewController` under `FKUIKit`.

### Added (Documentation)
- Added module-level documentation:
  - `Sources/FKUIKit/Components/TopNotification/README.md`

## [0.35.1] - 2026-04-22

### Fixed (FKUIKit FKTextField)
- Fixed emoji filtering regression that incorrectly removed ASCII digits (`0-9`) in formatted input flows.
- Updated emoji-sanitization logic to preserve ASCII text while still removing emoji scalars when emoji input is disabled.

### Changed (FKUIKit FKTextField)
- Added accessory icon presentation controls in `FKTextFieldAccessoryConfiguration`:
  - `iconSize`
  - `horizontalPadding`
  - `tintBehavior` (`.fixed` / `.followsBorderState`)
- Updated built-in clear/toggle accessory rendering to:
  - support configurable icon size and touch target sizing,
  - increase horizontal inset from field borders,
  - optionally follow border state color in normal/focused/error/disabled states.

### Changed (Examples)
- Refined `FKTextField` example hub with clearer character-allowance descriptions for each input type.
- Added an explicit "any-character" input demo field.
- Improved accessory icon demo spacing/sizing and added state-tint follow-up behavior showcase.
- Fixed `XIB / Storyboard` demo crash by removing invalid runtime `NSCoder()` instantiation path.

### Changed (Documentation)
- Updated root `README.md` package reference from `0.35.0` to `0.35.1`.
- Updated `Sources/FKUIKit/Components/TextField/README.md` with improved ToC transition copy and overview wording.

## [0.35.0] - 2026-04-21

### Added (FKUIKit FKDivider)
- Added a new lightweight divider module under `Sources/FKUIKit/Components/Divider/` with UIKit and SwiftUI support:
  - `FKDivider`
  - `FKDividerConfiguration`
  - `FKDividerManager`
  - `FKDividerView` (SwiftUI adapter)
  - `UIView.fk_addDivider(...)` convenience API
- Added support for horizontal/vertical directions, solid/dashed styles, dash pattern customization, gradient rendering, and 1-physical-pixel adaptation.
- Added Interface Builder support via `@IBDesignable` and `@IBInspectable` bridge properties for visual setup in XIB/Storyboard.
- Added global default configuration support through `FKDividerManager.shared.defaultConfiguration`.

### Added (Examples)
- Added complete FKDivider examples hub at:
  - `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/Divider/FKDividerExamplesHubViewController.swift`
- Added full scenario coverage including:
  - horizontal/vertical solid dividers
  - pixel-perfect rendering
  - insets, thickness, color, dashed and dash-pattern variants
  - gradient and auto-pinned edge dividers
  - global configuration, IB simulation, SwiftUI integration
  - dark mode and rotation adaptation demos
- Added `Divider` entry in `ExampleMenuViewController` under `FKUIKit`.

### Added (Documentation)
- Added module-level documentation:
  - `Sources/FKUIKit/Components/Divider/README.md`

### Changed (Documentation)
- Moved status badges from component READMEs to the root `README.md` for unified repository-level status display.
- Updated root `README.md` to include `Divider` in module structure, FKUIKit component list, and module docs navigation.
- Updated SPM reference version in root `README.md` from `0.34.0` to `0.35.0`.

## [0.34.0] - 2026-04-21

### Added (FKUIKit FKToast)
- Added a new lightweight global toast/snackbar module under `Sources/FKUIKit/Components/Toast/` with pure Swift UIKit implementation and SwiftUI interoperability.
- Added core toast architecture with queue-safe global presenter:
  - `FKToast`
  - `FKToastConfiguration`
  - `FKToastStyle`
  - `FKToastAnimator`
  - `FKToastView`
- Added built-in dual presentation modes:
  - classic floating toast
  - snackbar-style action hint
- Added five preset styles with default icon and adaptive color semantics:
  - `normal`
  - `success`
  - `error`
  - `warning`
  - `info`
- Added configurable placement (`top` / `center` / `bottom`), animation (`fade` / `slide`), interactions (tap/swipe dismiss), action button support, and custom UIView/SwiftUI content hosting.
- Added thread-safe invocation path with main-actor UI rendering, sequential queue presentation, and cancellable auto-dismiss scheduling.

### Added (Examples)
- Added comprehensive FKToast demo hub at:
  - `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/Toast/FKToastExamplesHubViewController.swift`
- Added full scenario coverage including:
  - presets, positions, animations, interaction controls, durations
  - custom style and custom content (UIKit + SwiftUI)
  - queue behavior and global configuration
  - dark/light appearance preview and standalone SwiftUI demo page
- Added `Toast` entry in `ExampleMenuViewController` under `FKUIKit`.

### Changed (FKUIKit FKToast)
- Refined top-position layout behavior:
  - when a navigation bar is visible, top toast appears below the navigation bar with configured spacing
  - otherwise, top toast appears below the safe-area top inset with configured spacing
- Aligned internal concurrency annotations and callback sendability for Swift 6 diagnostics in toast queue/animation paths.

### Added (Documentation)
- Added module-level documentation:
  - `Sources/FKUIKit/Components/Toast/README.md`

### Changed (Documentation)
- Updated root `README.md` to include `Toast` in FKUIKit component list, module docs navigation, and SPM reference version (`0.34.0`).

## [0.33.1] - 2026-04-21

### Changed (FKUIKit FKBadge)
- Added `FKBadgeAnchor.center` and corresponding layout handling in `FKBadgeController`, enabling center-pinned badge overlays in addition to corner anchors.
- Added `center` coverage in FKBadge examples (`FKBadgeExamplesHubViewController`) through interactive anchor switching.
- Completed professional Apple-style API and implementation comments across all FKBadge source files, covering public APIs, core private flows, layout, animation, and boundary behavior notes.

### Changed (Examples)
- Removed the legacy `FKBadgeCompleteExampleViewController.swift` from the FKBadge example set in favor of the focused hub-based demo structure.

### Changed (Documentation)
- Added a Table of Contents to `Sources/FKUIKit/Components/Badge/README.md`.
- Updated root `README.md` package reference from `0.33.0` to `0.33.1`.

## [0.33.0] - 2026-04-21

### Added (FKCompositeKit Base)
- Added a reusable, industrial-grade base foundation under `Sources/FKCompositeKit/Components/Base/`:
  - `Cell/FKBaseTableViewCell.swift`
  - `Cell/FKBaseCollectionViewCell.swift`
  - `Controller/FKBaseViewController.swift`
  - `Controller/FKBaseNavigationController.swift`
  - `Controller/FKBaseTabBarController.swift`
- Base cell features include:
  - unified init flow for code and XIB usage
  - container-based content layout and insets
  - override hooks: `setupUI()`, `setupStyle()`, `bindData(_:)`
  - surface helpers for corner/border/shadow/background
  - typed dequeue helpers with idempotent registration (`UITableView.fkDequeueCell`, `UICollectionView.fkDequeueCell`)
- Base controller features include:
  - standardized lifecycle entry points: `setupUI()`, `setupConstraints()`, `setupBindings()`
  - built-in loading / empty / error overlays and toast messages
  - keyboard observation and tap-to-dismiss keyboard support
  - navigation behavior hooks (non-invasive by default)
  - orientation and status bar style customization points

### Added (Examples)
- Added Base module demos under:
  - `Examples/FKKitExamples/FKKitExamples/Examples/FKCompositeKit/Base/`
- Added `Base` entry in `ExampleMenuViewController` under `FKCompositeKit`.

### Fixed (Swift Concurrency)
- Eliminated Swift 6 concurrency diagnostics from the new base modules by:
  - avoiding shared mutable global state for associated-object keys in base cell helpers
  - keeping base navigation-bar styling non-invasive by default
  - parsing keyboard notifications inside observer closures to avoid sendability diagnostics

## [0.32.0] - 2026-04-21

### Added (FKUIKit FKSticky)
- Added a new pure-native sticky module at `Sources/FKUIKit/Components/Sticky/` with layered source structure:
  - `Core`
  - `Protocol`
  - `Extension`
  - `Manager`
- Added `FKStickyEngine` with protocol-oriented sticky orchestration for `UIScrollView`-based containers.
- Added sticky models and state contracts:
  - `FKStickyTarget`
  - `FKStickyStyle`
  - `FKStickyState`
  - `FKStickyConfiguration`
- Added global defaults and manager entry:
  - `FKStickyManager.shared`
  - `FKStickyGlobalDefaults`
- Added one-line scroll integration APIs on `UIScrollView`:
  - `fk_stickyEngine`
  - `fk_handleStickyScroll()`
  - `fk_reloadStickyLayout()`
  - `fk_resetSticky()`
- Added module-level documentation at `Sources/FKUIKit/Components/Sticky/README.md`.

### Added (Examples)
- Added complete FKSticky demo suite under:
  - `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/Sticky/FKStickyExamplesHubViewController.swift`
  - `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/Sticky/FKStickyComprehensiveExampleViewController.swift`
  - `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/Sticky/FKStickyTableExampleViewController.swift`
  - `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/Sticky/FKStickyCollectionExampleViewController.swift`
- Added `Sticky` entry in `ExampleMenuViewController` under `FKUIKit`.
- Example coverage includes:
  - multi-target chained sticky transitions for generic views
  - sticky lifecycle callbacks (`willSticky`, `didSticky`, `didUnsticky`)
  - dynamic sticky enable/disable at runtime
  - `UITableView` grouped header sticky adaptation
  - `UICollectionView` section header sticky adaptation

### Fixed (FKUIKit FKSticky)
- Fixed Swift concurrency diagnostic in associated-object key storage by isolating sticky association keys on the main actor.

### Changed (Documentation)
- Updated root `README.md` to include `Sticky` in module structure, FKUIKit component list, and FKUIKit module docs navigation.
- Updated SPM version reference in root `README.md` from `0.31.0` to `0.32.0`.

## [0.31.0] - 2026-04-21

### Added (FKUIKit FKCarousel)
- Added a new native carousel module at `Sources/FKUIKit/Components/Carousel/` with layered source structure:
  - `Core`
  - `Cells`
  - `Manager`
  - `Extension`
- Added `FKCarousel` with reusable item modeling and configurable slide behavior:
  - `FKCarouselItem`
  - `FKCarouselDirection`
  - `FKCarouselConfiguration`
  - `FKCarouselPageControl`
- Added built-in reusable cell support:
  - `FKCarouselImageCell`
  - `FKCarouselCustomViewCell`
- Added protocol-based image loading abstraction:
  - `FKCarouselImageLoader`
- Added global style/template control:
  - `FKCarouselManager.shared`
  - `FKCarouselGlobalDefaults`
- Added one-line integration APIs on `UIView` via `UIView+FKCarousel`.
- Added module-level documentation at `Sources/FKUIKit/Components/Carousel/README.md`.

### Added (Examples)
- Added complete FKCarousel demo suite under:
  - `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/Carousel/FKCarouselExamplesHubViewController.swift`
  - `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/Carousel/FKCarouselComprehensiveExampleViewController.swift`
  - `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/Carousel/FKCarouselTableExampleViewController.swift`
  - `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/Carousel/FKCarouselCollectionExampleViewController.swift`
  - `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/Carousel/Core/FKCarouselDemoSupport.swift`
- Added `Carousel` entry in `ExampleMenuViewController` under `FKUIKit`.
- Example coverage includes:
  - automatic and manual paging with direction control
  - page indicator and looping behavior customization
  - local/remote image carousel presentation
  - custom hosted view carousel usage
  - `UITableViewCell` / `UICollectionViewCell` reuse-safe carousel patterns

### Changed (Documentation)
- Updated root `README.md` to include `Carousel` in module structure, FKUIKit component list, and FKUIKit module docs navigation.
- Updated SPM version reference in root `README.md` from `0.30.0` to `0.31.0`.

## [0.30.0] - 2026-04-21

### Added (FKUIKit FKLoadingAnimator)
- Added a new pure-native loading animation module at `Sources/FKUIKit/Components/LoadingAnimator/` with layered source structure:
  - `Core`
  - `Animations`
  - `Manager`
  - `Extension`
- Added `FKLoadingAnimatorView` with unified lifecycle control:
  - `start`
  - `stop`
  - `pause`
  - `resume`
  - `setProgress(_:)`
  - `switchStyle(_:autoRestart:)`
- Added style system and configuration models:
  - `FKLoadingAnimatorStyle`
  - `FKLoadingAnimatorStyleConfiguration`
  - `FKLoadingAnimatorConfiguration`
  - `FKLoadingAnimatorState`
  - `FKLoadingAnimatorPresentationMode`
- Added built-in loading styles:
  - ring / gradient ring / progress ring
  - wave / ripple wave
  - particles / flowing particles / twinkle particles
  - spinner / pulse circle / pulse square
  - rotating dots / gear
- Added protocol-oriented custom extension entry:
  - `FKLoadingAnimationProviding`
  - `.custom(FKLoadingAnimationProviding)` style injection
- Added global default manager:
  - `FKLoadingAnimatorManager.shared`
  - template mutation via `configureTemplate(_:)`
- Added one-line host APIs on `UIView`:
  - `fk_showLoadingAnimator(...)`
  - `fk_hideLoadingAnimator(animated:)`
  - `fk_switchLoadingStyle(_:autoRestart:)`
  - `fk_updateLoadingProgress(_:)`
  - `fk_startLoadingAnimation()`
  - `fk_stopLoadingAnimation()`
  - `fk_pauseLoadingAnimation()`
  - `fk_resumeLoadingAnimation()`
- Added module-level documentation at `Sources/FKUIKit/Components/LoadingAnimator/README.md`.

### Added (Examples)
- Added complete FKLoadingAnimator demo suite under:
  - `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/LoadingAnimator/FKLoadingAnimatorExamplesHubViewController.swift`
  - `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/LoadingAnimator/FKLoadingAnimatorComprehensiveExampleViewController.swift`
  - `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/LoadingAnimator/FKLoadingAnimatorTableExampleViewController.swift`
  - `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/LoadingAnimator/FKLoadingAnimatorCollectionExampleViewController.swift`
  - `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/LoadingAnimator/Core/FKLoadingAnimatorDemoSupport.swift`
- Added `LoadingAnimator` entry in `ExampleMenuViewController` under `FKUIKit`.
- Example coverage includes:
  - fullscreen loading masks across ring/wave/particle/spinner styles
  - embedded loading in `UIView`, `UIImageView`, and `UIButton`
  - determinate progress-ring updates
  - dynamic style switching at runtime
  - global style template updates
  - state callbacks and completion callbacks
  - `UITableViewCell` / `UICollectionViewCell` reuse-safe loading patterns

### Fixed (FKUIKit FKLoadingAnimator)
- Fixed Swift 6 concurrency diagnostics for spinner animator lifecycle by aligning animator protocol/base actor isolation with UIKit usage.
- Fixed layered rendering order in embedded/fullscreen presentation by ensuring loading hosts stay above host subviews.

### Changed (Documentation)
- Updated root `README.md` to include `LoadingAnimator` in module structure, FKUIKit component list, and FKUIKit module docs navigation.
- Updated SPM version reference in root `README.md` from `0.29.0` to `0.30.0`.

## [0.29.0] - 2026-04-21

### Added (FKUIKit FKStarRating)
- Added a new native star-rating module at `Sources/FKUIKit/Components/StarRating/` with layered source structure:
  - `Core`
  - `Star`
  - `Configuration`
  - `Manager`
  - `Model`
  - `Extension`
- Added `FKStarRating` (`UIControl`-based) with full rating interaction and display capabilities:
  - full-star rating mode
  - half-star rating mode
  - precise decimal rating mode (`.precise(step:)`)
  - editable and read-only display modes
  - tap and pan gesture rating
  - continuous slide updates with realtime callback and commit callback
  - configurable min/max rating range
  - manual rating updates with UI refresh
- Added dual rendering strategies:
  - image mode (selected/unselected/half images)
  - color mode (selected/unselected tint rendering)
- Added star appearance model `FKStarRatingStarStyle` for corner/border/shadow customization.
- Added global default configuration support via `FKStarRatingManager.shared` and `FKStarRating.defaultConfiguration`.
- Added fluent chaining APIs and Interface Builder support:
  - `withMode`, `withStarCount`, `withRange`, `withEditable`, `withColors`, `withImages`
  - `@IBDesignable` component with `@IBInspectable` bridge properties.
- Added module-level documentation at `Sources/FKUIKit/Components/StarRating/README.md`.

### Added (Examples)
- Added complete FKStarRating demo suite under:
  - `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/StarRating/FKStarRatingExamplesHubViewController.swift`
  - `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/StarRating/FKStarRatingBasicExampleViewController.swift`
  - `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/StarRating/FKStarRatingTableExampleViewController.swift`
- Added `StarRating` entry in `ExampleMenuViewController` under `FKUIKit`.
- Example coverage includes:
  - editable 5-star full rating
  - half-star display and edit modes
  - precise decimal continuous slide rating
  - read-only score presentation
  - custom star count (`3` and `10`)
  - custom star size/spacing/colors
  - image mode and color mode switching
  - realtime and final rating callbacks
  - `UITableViewCell` reuse-safe binding and reset flow
  - global default style configuration
  - manual set and reset rating operations

### Fixed (FKUIKit FKStarRating)
- Fixed configuration-update reentry crash (`EXC_BAD_ACCESS`) by removing recursive property mutation in `configuration.didSet`.
- Fixed Swift concurrency diagnostic on `FKStarRatingStarStyle.plain` by switching from static shared storage to computed value semantics.

### Changed (Documentation)
- Updated root `README.md` to include `StarRating` in module structure, FKUIKit component list, and FKUIKit module docs navigation.
- Updated SPM version reference in root `README.md` from `0.28.0` to `0.29.0`.

## [0.28.0] - 2026-04-21

### Added (FKUIKit FKExpandableText)
- Added a new expandable text module at `Sources/FKUIKit/Components/ExpandableText/` with layered source structure:
  - `Core`
  - `Configuration`
  - `Button`
  - `Text`
  - `Manager`
  - `Model`
  - `Protocol`
  - `Extension`
- Added `FKExpandableText` with configurable collapsed/expanded behavior for long text rendering.
- Added reuse-safe state cache support for list scenarios:
  - `FKExpandableTextManager.shared`
  - `FKExpandableText.stateCache`
  - `UITableViewCell.fk_bindExpandableText(...)`
  - `UICollectionViewCell.fk_bindExpandableText(...)`
- Added pre-measurement API for list height calculation:
  - `FKExpandableText.preferredHeight(...)`
- Added module-level documentation at `Sources/FKUIKit/Components/ExpandableText/README.md`.

### Added (Examples)
- Added full FKExpandableText demo suite under:
  - `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/ExpandableText/FKExpandableTextExamplesHubViewController.swift`
  - `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/ExpandableText/FKExpandableTextBasicExampleViewController.swift`
  - `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/ExpandableText/FKExpandableTextTableExampleViewController.swift`
  - `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/ExpandableText/FKExpandableTextCollectionExampleViewController.swift`
- Added `ExpandableText` entry in `ExampleMenuViewController` under `FKUIKit`.

### Fixed (FKUIKit FKExpandableText)
- Fixed early constraint-update crash (`Index out of range`) during initial configuration before Auto Layout constraint groups are built.
- Fixed truncation detection reliability by comparing measured expanded/collapsed heights, improving button visibility and interaction consistency in basic, table, and collection demos.

### Changed (Documentation)
- Updated root `README.md` to include `ExpandableText` in module structure, FKUIKit component list, and FKUIKit module docs navigation.
- Updated SPM version reference in root `README.md` from `0.27.0` to `0.28.0`.

## [0.27.0] - 2026-04-21

### Added (FKUIKit FKSwipeAction)
- Added a new native swipe-action module at `Sources/FKUIKit/Components/SwipeAction/` with layered source structure:
  - `Core`
  - `SwipeButton`
  - `Cell`
  - `Manager`
  - `Configuration`
  - `Animation`
  - `Extension`
  - `Protocol`
- Added `FKSwipeAction` and `FKSwipeActionController` to provide reusable, non-invasive list swipe behavior for:
  - `UITableViewCell`
  - `UICollectionViewCell`
- Added dual-direction swipe support:
  - left reveal actions
  - right reveal actions
- Added multi-button action configuration with built-in presets:
  - `delete`
  - `edit`
  - `pin`
  - `mark`
  - `favorite`
  - `more`
- Added per-action style model `FKSwipeActionItemStyle` with support for:
  - text-only / image-only / image+text actions
  - fixed-width and adaptive-width layouts
  - per-button color/font/insets/corner/icon settings
- Added behavior and appearance models:
  - `FKSwipeActionBehaviorConfiguration`
  - `FKSwipeActionAppearance`
  - `FKSwipeActionConfiguration`
- Added global manager and namespace controls:
  - `FKSwipeActionManager.shared`
  - `FKSwipeAction.defaultConfiguration`
  - `FKSwipeAction.closeAll(animated:)`
  - `FKSwipeAction.setGloballyEnabled(_:)`
- Added dangerous-action confirmation flow for destructive actions and automatic state mutex (open one closes others).
- Added module-level documentation at `Sources/FKUIKit/Components/SwipeAction/README.md`.

### Added (Examples)
- Added full FKSwipeAction demo suite under:
  - `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/SwipeAction/FKSwipeActionExamplesHubViewController.swift`
  - `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/SwipeAction/FKSwipeActionTableExampleViewController.swift`
  - `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/SwipeAction/FKSwipeActionCollectionExampleViewController.swift`
- Added `SwipeAction` entry in `ExampleMenuViewController` under `FKUIKit`.
- Example coverage includes:
  - table right-swipe multi-button actions
  - collection left-swipe multi-button actions
  - text/image/mixed action content
  - fixed and adaptive button widths
  - per-cell swipe enable/disable
  - auto-close on scroll
  - delete confirmation and callback handling
  - global style and behavior configuration

### Changed (FKUIKit FKSwipeAction)
- Completed professional English API and implementation comments across all SwipeAction source files for open-source readability and maintainability.
- Updated built-in action factories to accept optional titles (`String?`) for icon-only action scenarios while preserving default labels.
- Fixed delete confirmation action title fallback when custom title is `nil`.

### Changed (Documentation)
- Updated root `README.md` to include `SwipeAction` in module structure, FKUIKit component list, and FKUIKit module docs navigation.
- Updated SPM version reference in root `README.md` from `0.26.0` to `0.27.0`.

## [0.26.0] - 2026-04-21

### Added (FKUIKit FKMultiPicker)
- Added a new native cascading picker component module at `Sources/FKUIKit/Components/MultiPicker/` with layered structure:
  - `Core`
  - `Picker`
  - `Data`
  - `Model`
  - `Configuration`
  - `Animation`
  - `Protocol`
  - `Extension`
- Added `FKMultiPicker` with protocol-oriented, unlimited-depth linkage architecture:
  - configurable visible component count (`1...N`, recommended `1...5`)
  - smooth downstream refresh when upper-level selection changes
  - default selection restore by node `id` or `title`
  - closure and delegate callbacks for confirm/cancel/realtime change
- Added built-in region provider and sample data:
  - `FKMultiPickerBuiltInRegionDataProvider`
  - province -> city -> district -> street hierarchy data
- Added global configuration support via `FKMultiPickerManager.shared`.
- Added one-line presentation APIs:
  - `FKMultiPicker.present(...)`
  - `FKMultiPicker.presentRegionPicker(...)`
  - `UIViewController` convenience APIs (`fk_presentMultiPicker`, `fk_presentRegionPicker`)
- Added module-level documentation at `Sources/FKUIKit/Components/MultiPicker/README.md`.

### Changed (FKUIKit FKMultiPicker)
- Improved toolbar alignment and layout behavior:
  - centered title now pins to true toolbar center
  - cancel/confirm action areas use symmetric width constraints for stable alignment
- Improved sheet bottom docking to remove visual gap at the bottom edge.
- Completed professional English API documentation comments across all MultiPicker source files.

### Added (Examples)
- Added a comprehensive FKMultiPicker showcase page at:
  - `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/MultiPicker/FKMultiPickerExampleViewController.swift`
  - `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/MultiPicker/FKMultiPickerCustomDataProvider.swift`
- Added `MultiPicker` entry in `ExampleMenuViewController` under `FKUIKit`.
- Example coverage includes:
  - 3-level custom linkage picker
  - built-in 4-level region linkage picker
  - single-level picker mode
  - custom UI/popup style and default selection setup
  - global style setup
  - dynamic data refresh and manual dismiss flow
  - protocol-driven custom provider linkage demo

### Changed (Documentation)
- Updated root `README.md` to include FKMultiPicker in module structure, FKUIKit component list, and module docs navigation.

## [0.25.0] - 2026-04-20

### Added (FKUIKit FKTextField)
- Added a new one-stop formatted input component module at `Sources/FKUIKit/Components/TextField/` with layered structure:
  - `Core`
  - `Formatter`
  - `Validator`
  - `Configuration`
  - `Model`
  - `Protocol`
  - `Extension`
  - `Animation`
  - `CodeInput`
  - `CountInput`
- Added a protocol-oriented formatted input field `FKTextField` with pluggable formatter/validator architecture:
  - built-in formatting types for phone, ID card, bank card, verification code, password, amount, email, numeric/alphabetic/alphanumeric, and custom regex
  - realtime validation callbacks and structured result models
  - one-line setup APIs via `FKTextField.make(...)` and `FKTextFieldInputRule`
- Added dedicated OTP component `FKCodeTextField`:
  - 4/6-digit style support
  - box / underline slot rendering
  - iOS one-time-code AutoFill support
  - completion callback and error-state shake feedback
- Added multiline counter component `FKCountTextView`:
  - placeholder support
  - realtime character counting
  - max-length enforcement with overflow callback
- Added behavior configuration models:
  - `FKTextFieldLayoutConfiguration`
  - `FKTextFieldInlineMessageConfiguration`
  - `FKTextFieldCounterConfiguration`
  - `FKTextFieldValidationFeedbackConfiguration`
- Added shake animation helper at `Animation/UIView+FKTextFieldShake.swift`.
- Added module-level documentation at `Sources/FKUIKit/Components/TextField/README.md`.

### Changed (FKUIKit FKTextField)
- Integrated inline error message presentation and optional right-side counter display into `FKTextField`.
- Added password visibility toggle callback (`onPasswordVisibilityToggled`) for external interaction analytics/state sync.
- Improved text rect/inset handling for better cursor alignment and UIKit editing rect compatibility.
- Improved default formatter and validator documentation coverage and internal readability for open-source contribution workflows.

### Added (Examples)
- Added a comprehensive FKTextField showcase page at:
  - `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/TextField/FKTextFieldExampleViewController.swift`
- Added `TextField` entry in `ExampleMenuViewController` under `FKUIKit`.
- Example coverage includes:
  - phone / ID card / bank card formatted inputs
  - verification code input (`FKTextField` + `FKCodeTextField`)
  - password visibility toggle and validation callbacks
  - multiline count input (`FKCountTextView`)
  - custom regex formatting
  - custom left/right icon views
  - clear and dismiss actions
  - validation shake feedback
  - global style configuration usage

### Changed (Documentation)
- Updated root `README.md` to include FKTextField in module structure, FKUIKit component list, module docs navigation, and release version alignment (`0.25.0`).

## [0.24.0] - 2026-04-20

### Added (FKUIKit FKCornerShadow)
- Added a new high-performance visual component at `Sources/FKUIKit/Components/CornerShadow/` with layered source structure:
  - `Core`
  - `Model`
  - `Configuration`
  - `Protocol`
  - `Extension`
- Added one-line corner + shadow APIs on `UIView` and all UIKit subclasses through `UIView+FKCornerShadow`:
  - `fk_applyCornerShadow(_:)`
  - `fk_applyCornerShadow(corners:cornerRadius:fillColor:fillGradient:border:shadow:)`
  - `fk_applyCornerShadowFromGlobal(configure:)`
  - `fk_setCorners(_:radius:fillColor:)`
  - `fk_setShadow(color:opacity:offset:blur:spread:sides:)`
  - `fk_setBorder(_:)`
  - `fk_resetCornerShadow()`, `fk_resetCorners()`, `fk_resetShadow()`, `fk_resetBorder()`
- Added style models for reusable configuration:
  - `FKCornerShadowStyle`
  - `FKCornerShadowShadow`
  - `FKCornerShadowBorder`
  - `FKCornerShadowGradient`
  - `FKCornerShadowSide`
- Added global default style management via `FKCornerShadowManager.shared`.
- Added module-level documentation at `Sources/FKUIKit/Components/CornerShadow/README.md`.

### Changed (FKUIKit FKCornerShadow)
- Implemented rounded-corner rendering with `UIBezierPath` + `CAShapeLayer` masking and automatic layout-sync refresh.
- Implemented shadow rendering with explicit `shadowPath` (full-shadow mode) and side-selective shadow carriers (partial-shadow mode) to reduce implicit offscreen cost.
- Added gradient fill and gradient border composition while keeping border/fill paths aligned with corner geometry.
- Aligned component internals with Swift concurrency diagnostics:
  - main-actor isolation on view-facing APIs/protocol boundaries
  - sendability adjustments for side option set and static style template behavior
- Completed professional English API documentation comments across all FKCornerShadow source files.

### Added (Examples)
- Added copy-ready FKCornerShadow example suite under `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/CornerShadow/`:
  - `Core/FKCornerShadowExamplesHubViewController.swift`
  - `Core/FKCornerShadowDemoSupport.swift`
  - `UIView/FKCornerShadowUIViewExampleViewController.swift`
  - `Controls/FKCornerShadowControlsExampleViewController.swift`
  - `List/FKCornerShadowListExampleViewController.swift`
- Added `CornerShadow` entry in `ExampleMenuViewController` under `FKUIKit`.
- Example coverage includes:
  - single/multi/all corner radius
  - high-performance shadows with path optimization
  - corner + border + shadow combinations
  - custom shadow color/offset/blur/spread
  - gradient backgrounds and gradient borders
  - global style configuration and per-view overrides
  - UIButton/UILabel/UIImageView usage
  - UITableViewCell/UICollectionViewCell reuse-safe reset patterns
  - auto layout/frame-change adaptation and style reset flows

### Changed (Documentation)
- Updated root `README.md` to include FKCornerShadow in module structure, feature list, module docs navigation, and release version alignment (`0.24.0`).

## [0.23.0] - 2026-04-20

### Added (FKUIKit FKEmptyState)
- Added a production-ready module guide at `Sources/FKUIKit/Components/EmptyState/README.md` with complete usage, advanced customization, and API reference.
- Added protocol-oriented presentation contract `FKEmptyStatePresentable` with UIKit host support.
- Added global template manager `FKEmptyStateManager.shared` and one-line template-driven APIs:
  - `fk_setEmptyState(phase:animated:actionHandler:viewTapHandler:)`
  - `fk_setEmptyState(animated:actionHandler:viewTapHandler:configure:)`
- Added custom business-state capability in `FKEmptyStatePhase`:
  - `.custom(String)`
- Added helper factories in `FKEmptyStateModel`:
  - `customState(identifier:title:description:buttonTitle:)`
  - `withLayout(alignment:verticalOffset:)`
- Added placeholder background tap callback support (`viewTapHandler`) alongside primary button callbacks.

### Changed (FKUIKit FKEmptyState)
- Reorganized FKEmptyState sources into layered directories while preserving public behavior:
  - `Core`
  - `Model`
  - `State`
  - `Manager`
  - `Protocol`
  - `Extension`
- Improved iOS compatibility for action button styling by adding an iOS 13/14 fallback path while keeping iOS 15+ configuration support.
- Improved Swift concurrency diagnostics handling:
  - annotated empty-state manager/protocol boundaries with main-actor isolation
  - reduced shared mutable state warnings in singleton/protocol usage paths

### Changed (Examples)
- Refactored EmptyState examples into focused, copy-ready screens:
  - `Core`
  - `UIView`
  - `UITableView`
  - `UICollectionView`
  - `Business`
- Added full-coverage demo flows for:
  - empty/loading/error/no-network states
  - retry/refresh callbacks
  - global style configuration
  - custom business state rendering
  - manual show/hide and auto-hide after data load

### Changed (Documentation)
- Updated root `README.md` with FKEmptyState module-doc navigation and release version alignment (`0.23.0`).

## [0.22.0] - 2026-04-20

### Added (FKUIKit FKRefresh)
- Added a production-ready module guide at `Sources/FKUIKit/Components/Refresh/README.md` with complete usage, advanced customization, and API reference sections.
- Added async/await callback support for refresh controls:
  - `fk_addPullToRefresh(configuration:asyncAction:)`
  - `fk_addPullToRefresh(configuration:contentView:asyncAction:)`
  - `fk_addLoadMore(configuration:asyncAction:)`
  - `fk_addLoadMore(configuration:contentView:asyncAction:)`
- Added async action type alias: `FKRefreshAsyncHandler`.
- Added global configuration manager: `FKRefreshManager.shared` (`@MainActor`) for unified pull/load default style updates.
- Added load-more trigger mode model: `FKLoadMoreTriggerMode` (`automatic` / `manual`).
- Added built-in async auto-end options in `FKRefreshConfiguration`:
  - `automaticallyEndsRefreshingOnAsyncCompletion`
  - `automaticEndDelay`
- Added one-line footer control helpers in `UIScrollView+FKRefresh`:
  - `fk_setLoadMoreHidden(_:)`
  - `fk_resetLoadMoreState()`
  - `fk_removeRefreshComponents()`

### Changed (FKUIKit FKRefresh)
- Reorganized FKRefresh sources into layered directories while preserving public behavior:
  - `Core`
  - `Model`
  - `Manager`
  - `Extension`
  - `View`
  - `Animation`
- Improved Swift concurrency diagnostics handling in refresh manager/control lifecycle.

### Changed (Examples)
- Refactored FKRefresh example sources into clear functional folders:
  - `Hub`, `Common`, `Basic`, `Container`, `Custom`, `Advanced`
- Added `FKRefreshAsyncAwaitDemoViewController` to cover async/await integration and automatic end behavior.
- Expanded existing demos to cover:
  - manual start/end operations
  - no-more-data and failed load-more states
  - global configuration updates through `FKRefreshManager`
  - footer hide/show and reset flows
  - auto refresh on initial screen load

## [0.21.0] - 2026-04-20

### Added (FKUIKit FKSkeleton)
- Added a layered module structure for `FKSkeleton` under `Sources/FKUIKit/Components/Skeleton/`:
  - `Core`
  - `Animation`
  - `Manager`
  - `Extension`
  - `Model`
  - `Cell`
  - `Preset`
- Added automatic view-tree skeleton management via `FKSkeletonManager.shared` with:
  - `fk_showAutoSkeleton` / `fk_hideAutoSkeleton`
  - `fk_setSkeletonLoading`
  - `fk_withSkeletonLoading`
- Added view-level customization capabilities:
  - `fk_skeletonConfigurationOverride`
  - `fk_skeletonShape`
  - `fk_isSkeletonExcluded`
  - `FKSkeletonDisplayOptions`
- Added style and animation extensions:
  - `FKSkeletonStyle`
  - `FKSkeletonAnimationMode.pulse`
  - `FKSkeletonConfiguration.gradientColors`
  - `FKSkeletonConfiguration.borderWidth`
- Added module-level README for FKSkeleton at:
  - `Sources/FKUIKit/Components/Skeleton/README.md`

### Changed (FKUIKit FKSkeleton)
- Reorganized existing Skeleton source files into functional directories while preserving public API behavior.
- Aligned animation implementation with reusable factory helpers and unified style semantics.
- Improved Swift concurrency diagnostics handling for skeleton manager singleton usage.

### Changed (Examples)
- Refactored `FKSkeletonExampleViewController` into a complete copy-ready showcase that covers:
  - basic `UIView` overlay skeleton on `UIButton` / `UILabel` / `UIImageView`
  - `UITableView` skeleton with dedicated skeleton cells
  - `UITableView` skeleton overlay on existing cells
  - `UICollectionView` skeleton with dedicated skeleton cells
  - `UICollectionView` skeleton overlay on existing items
  - gradient and pulse animation examples
  - global style configuration
  - custom color/radius/speed configuration
  - excluded subviews and `UIStackView` auto skeleton
  - manual and async loading-state control patterns

## [0.20.1] - 2026-04-20

### Added (FKUIKit FKBadge)
- Added a protocol-oriented and production-ready FKBadge architecture with `Core/Model/Manager/Extension/Animation` layering under `Sources/FKUIKit/Components/Badge/`.
- Added `FKBadgeManager.shared` for global default style and global hide/restore operations.
- Added `FKBadgePresenting` protocol and main-actor-safe conformance for `FKBadgeController`.
- Added additional one-line APIs and lifecycle controls (`updateCount`, `clearCount`, `setHidden`) plus badge tap callback support.
- Added dedicated extensions for `UIButton`, `UILabel`, and `UIImageView` shortcut accessors.
- Added host-view based badge helpers for `UIBarButtonItem` and `UITabBarItem` (dot/text/count/hide).

### Added (Documentation)
- Added module-level FKBadge documentation at `Sources/FKUIKit/Components/Badge/README.md` with complete usage, advanced styling, and API reference.
- Updated root `README.md` with FKBadge release highlights and navigation to the module guide.

### Changed (FKUIKit FKBadge)
- Reorganized FKBadge source files into layered directories without changing public behavior.
- Expanded badge style configuration with text kerning support.
- Improved main-thread bridging in controller internals for Swift concurrency safety.

## [0.20.0] - 2026-04-20

### Added (FKCoreKit FKUtils)
- **`FKUtils`**: pure-native Swift utility module under `Sources/FKCoreKit/Utils/` with unified namespace entry (`FKUtils`) and category facades:
  - `FKUtils.DateTime`
  - `FKUtils.Regex`
  - `FKUtils.Number`
  - `FKUtils.String`
  - `FKUtils.Device`
  - `FKUtils.Collection`
  - `FKUtils.Common`
  - `FKUtils.UI` *(UIKit-available builds)*
  - `FKUtils.Image` *(UIKit-available builds)*
- **Date/time utilities**: custom format conversion, timestamp conversion, relative descriptions, date comparison, date addition, weekday/month extraction, and date-string validation.
- **Regex utilities**: built-in high-frequency validators (phone/email/ID/password/code/license plate/url/ip/postal/bank card), plus generic match/extract/replace APIs.
- **Number utilities**: grouped amount formatting, rounding/truncation, percent formatting, Chinese unit formatting (`万`/`亿`), random integers, zero-padding, and compact number text.
- **String utilities**: trimming/cleaning, safe substring, masking (phone/ID/email/bank card), pinyin + first letter, URL/Base64/HTML encode-decode.
- **Device/app utilities**: model/system/screen/battery/network/disk/memory/app metadata, safe vendor identifier, and one-shot reachability callback.
- **UI/image/common utilities**: hex color conversion, dynamic color, adaptive font, point/pixel conversion, corner/shadow/gradient helpers, screenshot, image compress/crop/round/base64, sandbox/file-size helpers, app jumps, vibration/sound, null checks, safe conversion and safe execution wrapper.

### Added (Examples)
- **`FKUtilsExampleViewController`** under `Examples/FKKitExamples/.../FKCoreKit/Utils/` with copy-ready, button-driven demos covering all utility categories.
- **Example menu**: **FKUtils** entry under **FKCoreKit** in `ExampleMenuViewController`.

### Added (Documentation)
- Root `README.md` updated to a complete FKUtils-focused open-source guide with API categories, usage, advanced examples, and best practices.
- Public API docs for new utility files are fully documented with English Swift-style comments.

### Fixed (Swift 6 Concurrency)
- Eliminated shared mutable static-state warnings in FKUtils providers and audio player storage.
- Resolved main-actor default argument warnings in UI helpers and sendability warnings in network-status callback.
- Updated memory page-size retrieval and compact number formatting implementation to avoid Swift 6 diagnostics.

## [0.19.0] - 2026-04-20

### Added (FKCoreKit FKBusinessKit)
- **`FKBusinessKit`**: pure-native Swift business capability module under `Sources/FKCoreKit/BusinessKit/` with singleton entry (`FKBusinessKit.shared`) and protocol-oriented architecture.
- **Version management**: local app metadata (`bundleID`/version/build), remote version provider abstraction, semantic version comparison, optional/forced update decision, and built-in update prompt presentation.
- **Global analytics**: unified event models (`pageView`/`click`/`custom`), automatic common parameter merge (device/system/version/channel/environment), file-backed FIFO buffering, periodic + threshold flush, and retry/drop policy.
- **In-app i18n**: runtime language switching independent of system language, persisted language selection, localized string lookup from language bundle, and observer/notification-based UI refresh hooks.
- **Lifecycle monitor**: centralized `UIApplication` lifecycle observation with normalized states and disposable observation tokens.
- **Deeplink router**: route registration/unregistration, host/path pattern matching (`*` wildcard segments), query parameter extraction, and source-aware routing context.
- **Device/app info**: bundle ID, app version/build, system version, hardware model identifier, screen size, channel, and environment exposure.
- **Business utilities**: time formatting + relative time, number formatting + compact units, sensitive-data masking (phone/ID/email/generic), global alert de-duplication, and startup task orchestration.
- **Concurrency alignment**: Swift 6-safe async signatures and sendability adjustments for version checks, flush callbacks, startup task execution, and demo uploader state handling.

### Added (Documentation)
- New module guide: `Sources/FKCoreKit/BusinessKit/README.md` (GitHub-style structure with copy-paste examples, architecture notes, and API reference).
- Completed English documentation comments across all BusinessKit source files (Core/Version/Track/I18n/Lifecycle/Deeplink/Utils/Model).

### Added (Examples)
- **`FKBusinessKitExampleViewController`** under `Examples/FKKitExamples/.../FKCoreKit/BusinessKit/` covering:
  - app info lookup
  - closure + async version checks
  - analytics tracking + flush
  - language switch + localization lookup
  - lifecycle monitoring
  - deeplink/universal link routing
  - formatter and masking utilities
  - alert de-duplication
  - startup task orchestration
- **Example menu**: **FKBusinessKit** entry under **FKCoreKit**.

## [0.17.0] - 2026-04-20

### Added (FKCoreKit FKFileManager)
- **`FKFileManager`**: native file + transfer module under `Sources/FKCoreKit/FileManager/` with unified entry point (`FKFileManager.shared`), sandbox directory helpers (`Documents`, `Caches`, `Tmp`), file CRUD (create/remove/move/copy/rename), file info (`FKFileInfo`), MIME type resolution (`FKFileMimeResolver`), content read/write (text/data/JSON object and `Codable` JSON), directory traversal (`FKFileTraversalOptions`), directory size calculation and cache/temp cleanup, transfer models (`FKDownloadRequest/Result`, `FKUploadRequest/Result`, `FKTransferProgress`, `FKPersistedTransfer`), disk-space guard (`ensureSufficientDiskSpace`), and iOS convenience helpers for sharing/preview (Quick Look).
- **Downloads**: `URLSessionDownloadDelegate` based resumable downloads with pause/resume (resume-data persistence), background downloads (background session identifier), progress callbacks, task cancellation, and snapshots persistence via `FKTransferPersistenceStore`.
- **Uploads**: multipart form upload via `URLSession` with progress callbacks and snapshot persistence.

### Added (Documentation)
- English module documentation: `Sources/FKCoreKit/FileManager/README.md` (GitHub-style structure with copy-paste examples and Background Modes guidance).

### Added (Examples)
- **`FKFileManagerExampleViewController`** under `Examples/FKKitExamples/.../FKCoreKit/FileManager/` covering: sandbox directories, file ops, text/JSON/image/`Codable` IO, resumable download with progress, single/multi file upload, cache size/clean, ZIP API usage, and file info checks (async/await + closure APIs).
- **Example menu**: **FKFileManager** entry under **FKCoreKit**.

### Notes
- ZIP compress/decompress uses native system APIs that are not available on iOS 13+ without newer OS support; current implementation may throw `zipUnavailable` depending on platform availability.

## [0.18.0] - 2026-04-20

### Added (FKCoreKit FKSecurity)
- **`FKSecurity`**: pure-native Swift security and cryptography module under `Sources/FKCoreKit/Security/` with singleton entry (`FKSecurity.shared`) and protocol-oriented services:
  - **Hash**: MD5 / SHA1 / SHA256 / SHA512 for String / Data / File (streaming file hashing).
  - **AES**: CBC / ECB with PKCS7 padding for String / Data / File (streaming file encryption via `CCCryptor`), plus secure key/IV generation.
  - **RSA**: key pair generation (2048/3072/4096), encrypt/decrypt (PKCS#1 v1.5, OAEP SHA-256), sign/verify (PKCS#1 v1.5 SHA-256/SHA-512), and DER import/export (Public SPKI, Private PKCS#8).
  - **Coding**: Base64, HEX, and URL encode/decode helpers.
  - **HMAC**: SHA-256/SHA-512, plus stable request parameter signing and verification helpers.
  - **Utilities**: secure random bytes/strings, sensitive data masking (phone/ID/email), basic anti-debug/suspicious environment hints, in-memory wipe and secure file wipe.
  - **Key storage**: built-in Keychain-backed raw key store (`FKKeychainKeyStore`).
- English module documentation: `Sources/FKCoreKit/Security/README.md` (GitHub-style structure with copy-paste examples and security notes).

### Added (Examples)
- **`FKSecurityExampleViewController`** under `Examples/FKKitExamples/.../FKCoreKit/Security/` covering: hash (string/data/file), AES (string/data) encrypt/decrypt, RSA key pair + encrypt/decrypt + sign/verify, Base64/HEX/URL encoding, HMAC, secure random + Keychain store, masking, secure wipe, and anti-tamper snapshot checks (async/await + closure usage).
- **Example menu**: **FKSecurity** entry under **FKCoreKit**.

## [0.16.0] - 2026-04-20

### Added (FKCoreKit FKPermissions)
- **`FKPermissions`**: native permission management module under `Sources/FKCoreKit/Permissions/` with protocol-oriented architecture (`FKPermissionHandling`, `FKPermissionObserving`), unified permission models (`FKPermissionKind`, `FKPermissionStatus`, `FKPermissionRequest`, `FKPermissionResult`, `FKPermissionError`), singleton entry (`FKPermissions.shared`), async/await and closure-based APIs, batch requests, real-time status checks, app-settings jump helper, customizable pre-permission prompt (`FKPermissionPrePrompt`), permission observation token (`FKPermissionObservationToken`), iOS version adaptation (photo access level and temporary full-accuracy location), and Swift 6 concurrency-safe delegate bridging for Bluetooth and Location handlers.
- English module documentation: `Sources/FKCoreKit/Permissions/README.md` (GitHub-style structure with copy-paste examples and Info.plist guidance).

### Added (Examples)
- **`FKPermissionsExampleViewController`** under `Examples/FKKitExamples/.../FKCoreKit/Permissions/` covering: status checks, single permission requests (camera/photo/microphone/location/notifications), batch requests, denied-state handling, jump-to-settings flow, and async/await plus closure usage.
- **Example menu**: **FKPermissions** entry under **FKCoreKit**.
- **`Examples/FKKitExamples/Info.plist`** updated with required permission usage descriptions for the permissions example.

## [0.15.0] - 2026-04-20

### Added (FKCoreKit FKLogger)
- **`FKLogger`**: native logging and debugging module under `Sources/FKCoreKit/Logger/` with protocol-oriented architecture (`FKLogFormatting`, `FKLogFileManaging`, `FKConsoleOutputting`), singleton + global one-line API (`FKLogger.shared`, `FKLogV/D/I/W/E`), five log levels (`verbose`, `debug`, `info`, `warning`, `error`), build-aware defaults (`debugDefault` / `releaseDefault`), structured formatting (timestamp, level, source info, metadata), ANSI color + emoji console styling, asynchronous thread-safe pipeline, file persistence with daily and size-based rotation, total storage cap cleanup, log listing/clear/export APIs, and debug dump helpers (`dumpValue`, `dumpEncodable`).
- **Crash and diagnostics capture**: uncaught exception handler, common fatal signal capture (`SIGABRT`, `SIGILL`, `SIGSEGV`, `SIGFPE`, `SIGBUS`, `SIGPIPE`), custom exception logging, and network diagnostic capture helpers.
- English module documentation: `Sources/FKCoreKit/Logger/README.md` (GitHub-style structure with copy-paste examples).

### Added (Examples)
- **`FKLoggerExampleViewController`** under `Examples/FKKitExamples/.../FKCoreKit/Logger/` covering: 5-level log printing, basic global configuration, model/array/dictionary printing, file logging and management, custom format toggles, debug/release environment behavior, crash capture setup, and clear/export flows.
- **Example menu**: **FKLogger** entry under **FKCoreKit**.

## [0.14.0] - 2026-04-20

### Added (FKCoreKit FKAsync)
- **`FKAsync`**: native GCD-based scheduling under `Sources/FKCoreKit/Async/` — protocol-oriented API (`FKAsyncMainExecuting`, `FKAsyncBackgroundExecuting`, `FKAsyncCancellable`, `FKAsyncDebouncing`, `FKAsyncThrottling`), main-thread-safe execution (`runOnMain`, `asyncOnMain`), global/serial/concurrent queue helpers (`FKAsyncQueues`), cancelable delayed work (`FKCancellableDelayedWork`), debounce (`FKDebouncer`), throttle (`FKThrottler`), `DispatchGroup` wrapper (`FKAsyncTaskGroup`), and serial/concurrent executors.
- English module documentation: `Sources/FKCoreKit/Async/README.md` (includes Table of Contents and copy-paste-ready examples).

### Added (Examples)
- **`FKAsyncExampleViewController`** under `Examples/FKKitExamples/.../FKCoreKit/Async/` covering main/background dispatch, delay+cancel, debounce (search bar), throttle (scroll/button), group coordination, serial/concurrent tasks, and thread checks.
- **Example menu**: **FKAsync** entry under **FKCoreKit**.

### Fixed (Examples)
- `FKAsyncExampleViewController`: ensure all log UI updates run on the main actor (no Main Thread Checker violations).

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

[Unreleased]: https://github.com/feng-zhang0712/FKKit/compare/0.37.0...HEAD
[0.37.0]: https://github.com/feng-zhang0712/FKKit/compare/0.36.0...0.37.0
[0.36.0]: https://github.com/feng-zhang0712/FKKit/compare/0.35.1...0.36.0
[0.35.1]: https://github.com/feng-zhang0712/FKKit/compare/0.35.0...0.35.1
[0.35.0]: https://github.com/feng-zhang0712/FKKit/compare/0.34.0...0.35.0
[0.34.0]: https://github.com/feng-zhang0712/FKKit/compare/0.33.1...0.34.0
[0.33.1]: https://github.com/feng-zhang0712/FKKit/compare/0.33.0...0.33.1
[0.33.0]: https://github.com/feng-zhang0712/FKKit/compare/0.32.0...0.33.0
[0.32.0]: https://github.com/feng-zhang0712/FKKit/compare/0.31.0...0.32.0
[0.31.0]: https://github.com/feng-zhang0712/FKKit/compare/0.30.0...0.31.0
[0.30.0]: https://github.com/feng-zhang0712/FKKit/compare/0.29.0...0.30.0
[0.29.0]: https://github.com/feng-zhang0712/FKKit/compare/0.28.0...0.29.0
[0.28.0]: https://github.com/feng-zhang0712/FKKit/compare/0.27.0...0.28.0
[0.27.0]: https://github.com/feng-zhang0712/FKKit/compare/0.26.0...0.27.0
[0.26.0]: https://github.com/feng-zhang0712/FKKit/compare/0.25.0...0.26.0
[0.25.0]: https://github.com/feng-zhang0712/FKKit/compare/0.24.0...0.25.0
[0.24.0]: https://github.com/feng-zhang0712/FKKit/compare/0.23.0...0.24.0
[0.23.0]: https://github.com/feng-zhang0712/FKKit/compare/0.22.0...0.23.0
[0.22.0]: https://github.com/feng-zhang0712/FKKit/compare/0.21.0...0.22.0
[0.21.0]: https://github.com/feng-zhang0712/FKKit/compare/0.20.1...0.21.0
[0.20.1]: https://github.com/feng-zhang0712/FKKit/compare/0.20.0...0.20.1
[0.20.0]: https://github.com/feng-zhang0712/FKKit/compare/0.19.0...0.20.0
[0.19.0]: https://github.com/feng-zhang0712/FKKit/compare/0.18.0...0.19.0
[0.18.0]: https://github.com/feng-zhang0712/FKKit/compare/0.17.0...0.18.0
[0.17.0]: https://github.com/feng-zhang0712/FKKit/compare/0.16.0...0.17.0
[0.16.0]: https://github.com/feng-zhang0712/FKKit/compare/0.15.0...0.16.0
[0.15.0]: https://github.com/feng-zhang0712/FKKit/compare/0.14.0...0.15.0
[0.14.0]: https://github.com/feng-zhang0712/FKKit/compare/0.13.0...0.14.0
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
