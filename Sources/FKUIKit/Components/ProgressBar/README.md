# FKProgressBar

`FKProgressBar` is a **UIKit** `UIControl` subclass: determinate and indeterminate **linear** and **ring** progress, optional **buffer**, **segmented** tracks, **gradient** fills, a **value label**, **VoiceOver** overrides, and optional **button** interaction. A small **SwiftUI** wrapper is available when SwiftUI is linked.

## Contents

- [Overview](#overview)
- [Module layout](#module-layout)
- [Requirements](#requirements)
- [Quick start](#quick-start)
- [Configuration](#configuration)
- [Indeterminate behavior](#indeterminate-behavior)
- [Labels](#labels)
- [Accessibility](#accessibility)
- [Button mode](#button-mode)
- [Delegate](#delegate)
- [SwiftUI](#swiftui)
- [Interface Builder](#interface-builder)
- [Intrinsic size](#intrinsic-size)
- [Examples](#examples)
- [Migrating from earlier 0.44.x](#migrating-from-earlier-044x)
- [License](#license)

## Overview

| Topic | Detail |
|--------|--------|
| **Variants** | `FKProgressBarVariant.linear` (horizontal or vertical) and `.ring` (stroke progress). |
| **Progress API** | Normalized `0…1` via `setProgress(_:animated:)`, `setBufferProgress(_:animated:)`, `setProgress(_:buffer:animated:)`. |
| **Threading** | `@MainActor`; update the view on the main queue only. |

## Module layout

Path: `Sources/FKUIKit/Components/ProgressBar/`

| Path | Contents |
|------|-----------|
| `Public/FKProgressBar.swift` | Main control. |
| `Public/Configuration/` | `FKProgressBarConfiguration` and nested value types: `FKProgressBarLayoutConfiguration`, `FKProgressBarAppearanceConfiguration`, `FKProgressBarMotionConfiguration`, `FKProgressBarLabelConfiguration`, `FKProgressBarAccessibilityConfiguration`, `FKProgressBarInteractionConfiguration`. |
| `Public/Models/FKProgressBarEnums.swift` | Variants, axes, caps, fill style, indeterminate style, timing, label placement/format, interaction mode, touch haptics, etc. |
| `Public/FKProgressBarDelegate.swift` | Optional delegate protocol. |
| `Public/Bridge/FKProgressBarSwiftUIView.swift` | `UIViewRepresentable` when SwiftUI is available. |
| `Extension/FKProgressBar+InterfaceBuilder.swift` | `@IBInspectable` shortcuts. |
| `Internal/` | Layout engine, layer stack, label formatting, indeterminate animator (not public API). |

## Requirements

- **Swift** 6 (see package manifest).
- **iOS 15+** for `FKUIKit`.

## Quick start

```swift
import FKUIKit

let bar = FKProgressBar()
bar.configuration.layout.trackThickness = 6
bar.configuration.appearance.showsBuffer = true
view.addSubview(bar)
bar.setProgress(0.42, buffer: 0.78, animated: true)
```

## Configuration

`bar.configuration` is a **`FKProgressBarConfiguration`** with six grouped structs:

| Member | Type | Role |
|--------|------|------|
| `layout` | `FKProgressBarLayoutConfiguration` | Variant, axis, track/ring geometry, insets, segments, cap style. |
| `appearance` | `FKProgressBarAppearanceConfiguration` | Colors, borders, fill style, gradient end color, `showsBuffer`. |
| `motion` | `FKProgressBarMotionConfiguration` | Determinate animation, indeterminate style/period, `playsIndeterminateAnimation`, reduced motion, completion haptic. |
| `label` | `FKProgressBarLabelConfiguration` | Placement, format, typography, logical range, value prefix/suffix, `numberFormatter`. |
| `accessibility` | `FKProgressBarAccessibilityConfiguration` | `customLabel`, `customHint`, `treatAsFrequentUpdates`. |
| `interaction` | `FKProgressBarInteractionConfiguration` | `interactionMode`, `highlightedAlphaMultiplier`, `disabledAlpha`, `minimumTouchTargetSize`, `touchHaptic`. |

Defaults: **`FKProgressBar.defaultConfiguration`** or **`FKProgressBarDefaults.configuration`**.

## Indeterminate behavior

Set `isIndeterminate = true` (or call `startIndeterminate()`). Choose `configuration.motion.indeterminateStyle` (`.none`, `.marquee`, `.breathing`).

Set **`configuration.motion.playsIndeterminateAnimation`** to `false` if you need indeterminate **semantics** (label / VoiceOver) **without** marquee, breathing, or rotating-arc **animations**.

## Labels

Configure **`configuration.label`**:

- **`placement`**: `.none`, `.above`, `.below`, `.leading`, `.trailing`, `.centeredOnTrack`.
- **`format`**: percent (integer or fractional), normalized `0…1`, or logical range.
- **`contentMode`**: how `customTitle` combines with formatted progress (`FKProgressBarLabelContentMode`).
- For `.above`, `.below`, and `.centeredOnTrack`, the label uses the full usable width so short strings like `100%` are unlikely to ellipsize.

## Accessibility

- **`accessibility.customLabel`** / **`customHint`** override defaults when non-empty.
- **`treatAsFrequentUpdates`** toggles `UIAccessibilityTraits.updatesFrequently` with indeterminate/animation state.

## Button mode

When **`interaction.interactionMode`** is **`.button`**, use `addTarget(_:action:for:)` with `.touchUpInside` or `.primaryActionTriggered`. Optional **`touchHaptic`**, **`minimumTouchTargetSize`**, and alpha multipliers apply while highlighted or disabled.

## Delegate

`FKProgressBarDelegate` — all methods have default empty implementations in a `public extension`; implement only what you need.

## SwiftUI

```swift
FKProgressBarView(
  progress: $progress,
  bufferProgress: $buffer,
  isIndeterminate: $isIndeterminate,
  configuration: myConfiguration,
  animateChanges: true
)
```

Use **`onPrimaryAction`** for `.primaryActionTriggered` in button mode.

## Interface Builder

`FKProgressBar` is `@IBDesignable`. Limited knobs are exposed as `ib*` properties; use **`configuration`** in code for full control.

## Intrinsic size

- **Linear horizontal**: intrinsic **height**; width is `noIntrinsicMetric`.
- **Linear vertical**: intrinsic **width**; height is flexible.
- **Ring**: intrinsic width and height from diameter, insets, and optional centered label.

`clipsToBounds` is `false` by default so ring strokes are not clipped.

## Examples

See **`Examples/FKKitExamples/…/ProgressBar/`**: hub, playground, gallery, progress-as-button, delegate log, RTL/accessibility, SwiftUI host.

## Migrating from earlier 0.44.x

**0.44.0** used a **flat** `FKProgressBarConfiguration` (all fields on the root). **0.44.1+** nests fields under `layout`, `appearance`, `motion`, `label`, `accessibility`, and `interaction` (see table above).

**After 0.44.1**, label and accessibility property names were shortened (no repeated `label` / `accessibility` prefixes on nested structs):

| Previous (0.44.1) | Current |
|-------------------|---------|
| `label.labelPlacement` | `label.placement` |
| `label.labelFormat` | `label.format` |
| `label.labelContentMode` | `label.contentMode` |
| `label.labelFont` / `labelColor` / `labelPadding` | `label.font` / `textColor` / `padding` |
| `label.labelFractionDigits` | `label.fractionDigits` |
| `label.labelPrefix` / `labelSuffix` | `label.valuePrefix` / `valueSuffix` |
| `label.labelUsesSemanticLabelColor` | `label.usesSemanticTextColor` |
| `accessibility.accessibilityCustomLabel` | `accessibility.customLabel` |
| `accessibility.accessibilityCustomHint` | `accessibility.customHint` |
| `accessibility.accessibilityTreatAsFrequentUpdates` | `accessibility.treatAsFrequentUpdates` |
| `interaction.buttonHighlightedContentAlphaMultiplier` | `interaction.highlightedAlphaMultiplier` |
| `interaction.disabledContentAlpha` | `interaction.disabledAlpha` |

`FKProgressBarInteractionMode`, `FKProgressBarLabelContentMode`, and `FKProgressBarTouchHaptic` now live in **`FKProgressBarEnums.swift`** (same module, same symbols).

## License

`FKProgressBar` is part of **FKKit** and uses the **same license** as this repository.
