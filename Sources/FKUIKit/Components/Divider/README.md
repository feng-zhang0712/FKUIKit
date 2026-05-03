# FKDivider

UIKit hairline and stroke-style separators with an optional SwiftUI twin (`FKDividerView`). Same configuration model for both stacks.

## Requirements

- Swift 6 / iOS 15+
- `import FKUIKit` (SwiftUI examples also `import SwiftUI`)

## Source layout

Aligned with **`Badge`** and **`BlurView`**: **`Public`** (types you import), **`Internal`** (shared geometry), **`Extension`** (UIKit helpers).

Paths are under `Sources/FKUIKit/Components/Divider/`.

### `Public/`

| File | Role |
|------|------|
| `FKDividerConfiguration.swift` | `FKDividerConfiguration`, axis/line/gradient/pin enums |
| `FKDivider.swift` | `FKDivider` (`UIView`), rendering, `defaultConfiguration`, intrinsic size |
| `FKDivider+InterfaceBuilder.swift` | `@IBInspectable` bridges for Storyboards |
| `FKDividerView.swift` | SwiftUI `FKDividerView` |

### `Internal/`

| File | Role |
|------|------|
| `FKDividerGeometry.swift` | Shared horizontal/vertical stroke math for UIKit + SwiftUI |

### `Extension/`

| File | Role |
|------|------|
| `UIView+FKDivider.swift` | `fk_addDivider(at:configuration:margin:)` |

## Quick start

```swift
import UIKit
import FKUIKit

let line = FKDivider(configuration: .init(color: .separator))
```

Set once at launch (optional):

```swift
FKDivider.defaultConfiguration.color = .opaqueSeparator
```

Pin without writing constraints:

```swift
card.fk_addDivider(at: .bottom, margin: 16)
```

## Global defaults

Use **`FKDivider.defaultConfiguration`** as the single baseline (same idea as `FKBlur.defaultConfiguration` / `FKBadge.defaultConfiguration`).  
`FKDivider()` and `fk_addDivider(…)` copy that struct when you do not pass an explicit `FKDividerConfiguration`.

## RTL and edges

- **`FKDividerPinnedEdge.leading` / `.trailing`** pin to `leadingAnchor` / `trailingAnchor` (semantic edges).
- Horizontal **gradients** follow layout direction in UIKit (`CAGradientLayer` flips under RTL) and in SwiftUI (`LinearGradient` uses `.leading` / `.trailing`).

## `dashPattern`

Public API is **`[CGFloat]`** (stroke and gap lengths in points). Internally this maps to `CAShapeLayer.lineDashPattern`.

## Auto Layout

`FKDivider` implements **`intrinsicContentSize`** on the short axis (thickness) so `UIStackView` can size a horizontal line without an extra height constraint when you rely on the hairline thickness.

## Interface Builder

Subclass `UIView` → **`FKDivider`** and use the `ib*` inspectables defined in `FKDivider+InterfaceBuilder.swift`.

## SwiftUI

```swift
import SwiftUI
import FKUIKit

FKDividerView(configuration: .init(direction: .horizontal, color: .separator))
  .frame(height: 1)
```

## Examples

Under `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/Divider/`:

| Location | Role |
|----------|------|
| `FKDividerExamplesHubViewController.swift` | Table of scenarios |
| `FKDividerExampleSupport.swift` | Scroll stack + cards |
| `Scenarios/` | Basics, line styles, layout/defaults, adaptive UI, SwiftUI host |

## API summary

| Symbol | Purpose |
|--------|---------|
| `FKDivider` | Separator `UIView` |
| `FKDividerConfiguration` | Style model |
| `FKDivider.defaultConfiguration` | Global baseline |
| `FKDividerView` | SwiftUI wrapper |
| `FKDividerPinnedEdge` | `.top`, `.bottom`, `.leading`, `.trailing` |
| `UIView.fk_addDivider(at:configuration:margin:)` | Pinned helper |

## License

Part of FKKit — MIT. See repository `LICENSE`.
