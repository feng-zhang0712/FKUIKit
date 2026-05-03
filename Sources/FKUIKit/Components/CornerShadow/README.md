# FKCornerShadow

UIKit helper for **rounded corners**, **optional gradient fill and border**, and **drop shadows** using explicit `shadowPath` geometry (smooth scrolling, reuse-safe).

## Requirements

- Swift 6, iOS 15+ (package platform)
- `import FKUIKit`

## Source layout

Same layering as `Badge` and `BlurView`:

| Area | Path | Role |
|------|------|------|
| **Public** | `Public/*.swift` | `FKCornerShadowStyle`, `FKCornerShadowElevation`, `FKCornerShadowEdge`, `FKCornerShadowGradient`, `FKCornerShadowBorder`, `FKCornerShadowManager`, `FKCornerShadowStylable` |
| **Internal** | `Internal/*.swift` | Renderer, layout hook, associated-object layer store, main-thread assertion |
| **Extension** | `Extension/UIView+FKCornerShadow.swift` | `fk_*` entry points on `UIView` |

### Internal files

| File | Role |
|------|------|
| `FKCornerShadowRenderer.swift` | Builds paths, updates mask/fill/border/shadow layers |
| `FKCornerShadowLayerStore.swift` | Cached sublayers + associated objects |
| `FKCornerShadowLayoutObserver.swift` | One-time `layoutSubviews` swizzle → refresh |
| `FKCornerShadowAssertions.swift` | Main-thread precondition |

## Quick start

```swift
import UIKit
import FKUIKit

card.fk_applyCornerShadow(
  corners: .allCorners,
  cornerRadius: 16,
  fillColor: .secondarySystemBackground,
  shadow: FKCornerShadowElevation(
    opacity: 0.14,
    offset: CGSize(width: 0, height: 6),
    blur: 12,
    spread: 0,
    edges: .all
  )
)
```

## Defaults manager

Set once (e.g. app launch), then apply everywhere:

```swift
FKCornerShadowManager.shared.configureDefaultStyle { style in
  style.cornerRadius = 12
  style.fillColor = .secondarySystemBackground
  style.shadow = FKCornerShadowElevation(edges: .all)
}

label.fk_applyCornerShadowFromDefaults()
chip.fk_applyCornerShadowFromDefaults { $0.cornerRadius = 20 }
```

## API overview

### Models

- **`FKCornerShadowStyle`** — `corners`, `cornerRadius`, `fillColor`, `fillGradient`, `border`, `shadow` (`FKCornerShadowElevation?`).
- **`FKCornerShadowElevation`** — `color`, `opacity`, `offset`, `blur`, `spread`, **`edges`** (`FKCornerShadowEdge`). When `edges == .all`, shadow uses the host layer’s `shadowPath` (cheapest). Otherwise extra sublayers approximate shadows on selected edges.
- **`FKCornerShadowEdge`** — `.top`, `.left`, `.bottom`, `.right`, `.all`.
- **`FKCornerShadowGradient`** — linear gradient for fill or border.
- **`FKCornerShadowBorder`** — `.none`, `.solid`, `.gradient`.

### `UIView`

| Method | Purpose |
|--------|---------|
| `fk_applyCornerShadow(_:)` | Apply a full style |
| `fk_applyCornerShadowFromDefaults(_:)` | Copy `FKCornerShadowManager.shared.defaultStyle`, optional mutate |
| `fk_applyCornerShadowFromDefaults()` | Same with no overrides |
| `fk_applyCornerShadow(corners:cornerRadius:fillColor:fillGradient:border:shadow:)` | Inline convenience |
| `fk_setCorners`, `fk_setShadow`, `fk_setBorder` | Patch current style |
| `fk_resetCornerShadow()` | Remove layers + clear stored style (use in `prepareForReuse`) |
| `fk_resetCorners` / `fk_resetShadow` / `fk_resetBorder` | Partial clears |
| `fk_cornerShadowCurrentStyle` | Last applied style snapshot |

All APIs must run on the **main thread**.

## Migration (breaking)

| Before | After |
|--------|-------|
| `FKCornerShadowShadow` | `FKCornerShadowElevation` |
| `FKCornerShadowSide`, `.sides` | `FKCornerShadowEdge`, `.edges` |
| `fk_applyCornerShadowFromGlobal` | `fk_applyCornerShadowFromDefaults` |

## Examples

Under `Examples/FKKitExamples/.../FKUIKit/CornerShadow/`:

- `FKCornerShadowExamplesHubViewController.swift`
- `FKCornerShadowExampleSupport.swift`
- `Scenarios/` — basics, controls, lists

## Behavior notes

- **Dynamic colors:** `UIColor.cgColor` is resolved when applied; after Light/Dark switches, re-apply if you need layers to track semantic colors.
- **Swizzling:** First use installs a single `UIView.layoutSubviews` hook for views that have an applied style.
- **Performance:** Prefer `edges: .all` when you do not need edge-limited shadows.

## License

Same as the repository — see [LICENSE](../../../LICENSE).
