# FKBadge

UIKit badge overlay: dot, numeric (with overflow such as `99+`), and short text. The badge is a **sibling** of your target view in its superview so clipping and hit-testing on the target stay unchanged.

## Requirements

- Swift 6 / iOS 15+
- `import FKUIKit`

## Source layout

Same layering idea as `PresentationController`: **`Public`** (exported types), **`Internal`** (implementation details), **`Extension`** (UIKit entry points). Paths are under `Sources/FKUIKit/Components/Badge/`.

### `Public/`

| File | Role |
|------|------|
| `FKBadgeController.swift` | Attachment, layout, content, gestures, accessibility |
| `FKBadgeConfiguration.swift` | `FKBadgeConfiguration` + `FKBadge` defaults / global hide |
| `FKBadgeAnimation.swift` | Optional entrance / emphasis animations |
| `FKBadgeAnchor.swift` | Corner / center anchors (RTL-safe leading/trailing) |
| `FKBadgeVisibilityPolicy.swift` | Automatic vs forced visibility |
| `FKBadgeFormatter.swift` | Count formatting and digit-string parsing |

### `Internal/`

| File | Role |
|------|------|
| `FKBadgeContentView.swift` | Rendering view (dot / pill label) |
| `FKBadgeRegistry.swift` | Weak registry for global hide / restore |
| `FKBadgeHierarchyObserver.swift` | One-time `didMoveToSuperview` hook for re-attachment |

### `Extension/`

| File | Role |
|------|------|
| `UIView+FKBadge.swift` | `fk_badge` and one-line helpers |
| `UIBarButtonItem+FKBadge.swift`, `UITabBarItem+FKBadge.swift` | Bar item / tab item helpers |

## Quick start

```swift
import UIKit
import FKUIKit

iconView.fk_showBadgeDot(animated: true, animation: .pop())
button.fk_showBadgeCount(12, animated: true)
label.fk_showBadgeText("NEW", animated: true)
button.fk_clearBadge(animated: true)
```

Advanced control uses the lazily created controller:

```swift
button.fk_badge.setAnchor(.topTrailing, offset: UIOffset(horizontal: -4, vertical: 4))
button.fk_badge.showCount(128, animated: true, animation: .pulse())
```

## Global defaults and batch hide

Set once at launch:

```swift
FKBadge.defaultConfiguration.maxDisplayCount = 99
FKBadge.defaultConfiguration.backgroundColor = .systemRed
```

Hide or restore **all** active badges (weakly tracked):

```swift
FKBadge.hideAllBadges(animated: true)
FKBadge.restoreAllBadges(animated: true)
```

## API summary

### `UIView`

- `fk_badge` — `FKBadgeController` (created on first access).
- `fk_showBadgeDot(animated:animation:)`
- `fk_showBadgeCount(_:animated:animation:)`
- `fk_showBadgeText(_:animated:animation:)`
- `fk_clearBadge(animated:)` — clears content (same as `fk_badge.clear`).

### `UIBarButtonItem` / `UITabBarItem`

- `fk_badge` — optional controller when a host `UIView` exists.
- Same `fk_showBadge*` / `fk_clearBadge` helpers (forward to optional controller).

`UITabBarItem` additionally:

- `fk_setBadgeCount(_:maxDisplay:overflowSuffix:)` — sets UIKit `badgeValue` using the same overflow rules as `FKBadgeFormatter`.
- `fk_clearBadge` also clears `badgeValue`.

### `FKBadgeController`

**Content**

- `showDot(animated:animation:)`
- `showCount(_:animated:animation:)` — values `<= 0` hide under `.automatic`.
- `showText(_:animated:animation:)` — whitespace-only → dot.
- `setCount(parsing:animated:animation:)` — digits-only string; invalid input clears.
- `clear(animated:)`

**Visibility**

- `visibilityPolicy` — `.automatic` / `.forcedHidden` / `.forcedVisible`
- `setForcedHidden(_:animated:)` — `true` → `.forcedHidden`; `false` → `.automatic` (does not restore `.forcedVisible` if you had switched earlier).

**Layout**

- `anchor`, `offset`, `setAnchor(_:offset:)`, `reattachIfNeeded()`

**Interaction & motion**

- `onTap`
- `minimumTouchTargetSide` — expands hit testing when `onTap != nil` (e.g. `44`).
- `playAnimation(_:)` — respects Reduce Motion.

**Accessibility**

- `accessibilityBadgeLabel` — optional override; numeric/text default to visible glyphs; pure dot needs a label if you want a separate VoiceOver element.
- Numeric glyphs may use `.updatesFrequently`.

**Lifecycle**

- `removeFromTarget()` — removes view and clears association.
- `isEffectivelyHidden`

## Styling

`FKBadgeConfiguration` controls fill, title color, font, border, padding, kerning, dot diameter, optional text corner radius, `maxDisplayCount`, `overflowSuffix`, and optional `minimumContentWidth`.

Assign to `fk_badge.configuration` (or pass into `FKBadgeController(target:configuration:)` if you construct manually).

## Architecture notes

- Badge is **not** a subview of the target; it shares the target’s superview.
- `FKBadgeHierarchyObserver` swizzles `UIView.didMoveToSuperview` once so badges follow hierarchy changes.
- APIs are main-thread oriented; the controller hops to the main actor when needed.

## Examples

See `Examples/FKKitExamples/.../Examples/FKUIKit/Badge/`:

| Location | Contents |
|----------|----------|
| Root | `FKBadgeExamplesHubViewController.swift` (sample list), `FKBadgeExampleSupport.swift` (shared demo UI) |
| `Scenarios/` | Basics, appearance, anchors, and integration screens (one Swift file per topic) |

## License

Same as the FKKit repository.
