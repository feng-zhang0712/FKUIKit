# FKBlurView

UIKit (and optional SwiftUI) blur with **two backends**:

| Backend | Technology | Best for |
|--------|------------|----------|
| `.system(style:)` | `UIVisualEffectView` / `UIBlurEffect` | Live content, scrolling, maximum frame rate |
| `.custom(parameters:)` | Snapshot + Core Image | Exact radius, saturation, brightness, tint |

## Requirements

- Swift 6 / iOS 15+
- `import FKUIKit`

## Source layout

Aligned with **`Badge`** and **`PresentationController`**: **`Public`** (exported API), **`Internal`** (implementation), **`Extension`** (UIKit entry points). Paths: `Sources/FKUIKit/Components/BlurView/`.

### `Public/`

| File | Role |
|------|------|
| `FKBlurView.swift` | Main view: system vs custom pipeline, masks, IB inspectables, Reduce Transparency handling |
| `FKBlurConfiguration.swift` | `FKBlurConfiguration`, `FKBlur.defaultConfiguration` |
| `FKSwiftUIBlurView.swift` | `UIViewRepresentable` wrapper + optional `blurSourceProvider` |

### `Internal/`

| File | Role |
|------|------|
| `FKBlurImageProcessor.swift` | Shared Core Image pipeline (Gaussian blur, color controls, tint; Metal-biased `CIContext`) |

### `Extension/`

| File | Role |
|------|------|
| `UIView+FKBlur.swift` | `fk_blurredSnapshot`, `fk_blurredSnapshotAsync` |
| `UIImage+FKBlur.swift` | `fk_blurred` |

## Quick start

```swift
import UIKit
import FKUIKit

let blur = FKBlurView()
blur.configuration = FKBlurConfiguration(backend: .system(style: .systemMaterial))
```

Custom Core Image parameters:

```swift
let params = FKBlurConfiguration.CustomParameters(blurRadius: 18, saturation: 1.1, brightness: 0, tintColor: nil, tintOpacity: 0)
blur.configuration = FKBlurConfiguration(mode: .dynamic, backend: .custom(parameters: params), downsampleFactor: 4)
blur.blurSourceView = backgroundContainerView
```

## Global defaults

Set once at launch (main thread); new `FKBlurView` instances read `FKBlur.defaultConfiguration` until you assign `FKBlurView.configuration`:

```swift
FKBlur.defaultConfiguration = FKBlurConfiguration(backend: .system(style: .systemThinMaterial))
```

## Reduce Transparency

When the user enables **Settings → Accessibility → Display & Text Size → Reduce Transparency**, the **`.custom`** backend shows an opaque fill instead of a CPU blur (system `.system` backend is unchanged). Customize the fill with:

```swift
FKBlurConfiguration(
  backend: .custom(parameters: params),
  reduceTransparencyFallbackColor: UIColor { $0.userInterfaceStyle == .dark ? .black : .white }
)
```

`nil` uses `UIColor.secondarySystemBackground` resolved with the view’s `traitCollection`.

## Interface Builder

`FKBlurView` is `@IBDesignable`. Map inspectables (`ibBackend`, `ibMode`, `ibBlurRadius`, …) through **Live-prepare**: `prepareForInterfaceBuilder` syncs into `FKBlurConfiguration`.

## SwiftUI

```swift
import SwiftUI
import FKUIKit

FKSwiftUIBlurView(
  configuration: FKBlurConfiguration(backend: .system(style: .systemMaterial)),
  blurSourceProvider: { uiKitHostView }
)
```

Prefer `.system` for animated or scrolling content.

## API summary

### `FKBlurView`

- `configuration` — thread-safe assign; UI work runs on the main thread.
- `blurSourceView` — snapshot source for `.custom` (defaults to `superview`).
- `maskPath`, `maskedCornerRadius` — clip blurred output.
- `invalidateBlurContent()` — refresh `.custom` output when pixels change without layout (especially `.static`).

### `FKBlurConfiguration`

- `mode` — `.static` (capture once) vs `.dynamic` (display link refresh for `.custom`).
- `backend` — `.system(style:)` or `.custom(parameters:)`.
- `opacity`, `downsampleFactor`, `preferredFramesPerSecond`, `reduceTransparencyFallbackColor`.

### `UIImage` / `UIView`

- `UIImage.fk_blurred(parameters:downsampleFactor:context:)`
- `UIView.fk_blurredSnapshot(...)` / `fk_blurredSnapshotAsync(...)` (snapshot must start on main).

## Examples

See `Examples/FKKitExamples/.../Examples/FKUIKit/BlurView/`:

| Location | Contents |
|----------|----------|
| Root | `FKBlurExamplesHubViewController.swift` (table of contents), `FKBlurExampleSupport.swift` (shared UI helpers) |
| `Scenarios/` | One Swift file per topic (basics, custom parameters, modes, snapshot, mask, defaults, XIB, SwiftUI, performance) |

## License

Same as the FKKit repository.
