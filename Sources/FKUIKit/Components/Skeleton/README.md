# FKSkeleton

UIKit skeleton loading for production apps: overlay mode, hierarchy scanning, composable blocks, presets, and list helpers. Pure Swift, zero third-party dependencies.

## Source layout

```
Skeleton/
├── README.md
├── Public/
│   ├── FKSkeleton.swift                 # Global defaults
│   ├── Manager/
│   │   └── FKSkeletonManager.swift      # Auto-mode lifecycle (also used by UIView helpers)
│   ├── Models/                          # Configuration & enums
│   ├── Views/
│   │   ├── FKSkeletonView.swift
│   │   └── FKSkeletonContainerView.swift
│   ├── Cells/
│   ├── Presets/
│   └── ...
├── Internal/
│   ├── FKSkeletonController.swift       # Tree scan & placeholder layout
│   ├── FKSkeletonDispatch.swift         # Main-queue marshaling
│   ├── FKSkeletonPresentable.swift      # Module-internal hook
│   ├── FKSkeletonVisibleCells.swift     # Shared table/collection helper
│   └── Rendering/
│       ├── FKSkeletonLayer.swift
│       ├── FKSkeletonUnifiedShimmerHost.swift
│       └── FKSkeletonAnimationFactory.swift
└── Extension/
    ├── UIView+FKSkeleton.swift          # Overlay, auto mode, list helpers
    └── UIKit+FKSkeletonConvenience.swift # UILabel / UIImageView / UIButton / UITextField sugar
```

Public API lives under **`Public/`** and **`Extension/`**. **`Internal/`** holds implementation details consumers should not subclass or mirror.

## Overview

| Mode | Entry | Use case |
|------|--------|----------|
| Overlay | `fk_showSkeleton` / `fk_hideSkeleton` | Quick mask over any `UIView` without restructuring layout |
| Auto | `fk_showAutoSkeleton` / `fk_hideAutoSkeleton` | Scan stacks and common controls; honors exclusions & shapes |
| Composable | `FKSkeletonContainerView` + `FKSkeletonView` | Pixel-aligned placeholders with optional unified shimmer |
| Presets | `FKSkeletonPresets` | Opinionated rows, cards, text columns, grid tiles |

## Requirements

- iOS 15+ (matches `FKUIKit` package platform)
- Swift 5.9+

## Installation

`FKSkeleton` ships inside `FKUIKit`:

```swift
import FKUIKit
```

## Threading

- **Overlay** APIs (`fk_showSkeleton`, `fk_hideSkeleton`, visible-cell helpers) hop to the main queue before touching UIKit.
- **Auto** APIs forward to `FKSkeletonManager`, which marshals work onto the main queue.
- **`fk_withSkeletonLoading`** captures a token on the main queue; call the completion from any queue—the implementation re-dispatches to main before hiding.

## Animation modes

`FKSkeletonAnimationMode`: `.shimmer`, `.pulse`, `.breathing` (alias of pulse-style), `.none`.

`FKSkeletonStyle` maps coarse semantics (`.solid`, `.gradient`, `.pulse`) onto those modes via `FKSkeletonConfiguration.style`.

## Basic usage

### Overlay

```swift
cardView.fk_showSkeleton(animated: true, respectsSafeArea: false, blocksInteraction: true)
cardView.fk_hideSkeleton(animated: true)
```

### Auto mode

```swift
stackView.fk_showAutoSkeleton(
  options: FKSkeletonDisplayOptions(blocksInteraction: true, hidesTargetView: true)
)
stackView.fk_hideAutoSkeleton()
```

### Per-view tuning

```swift
avatarView.fk_skeletonShape = .circle
badgeView.fk_isSkeletonExcluded = true
titleLabel.fk_skeletonConfigurationOverride = customConfig
```

### Convenience wrappers

```swift
titleLabel.fk_showSkeletonLabel()
avatarView.fk_showSkeletonImage()
actionButton.fk_showSkeletonButton()
textField.fk_showSkeletonTextField()
```

### Lists

**Visible cells**

```swift
tableView.fk_showAutoSkeletonOnVisibleCells(animated: true)
tableView.fk_hideAutoSkeletonOnVisibleCells(completion: { ... })
```

**Dedicated skeleton cells**

Register `FKSkeletonTableViewCell` / `FKSkeletonCollectionViewCell` with a **different** reuse ID than real content; build layouts on `skeletonContainer`.

### Global defaults

```swift
FKSkeleton.defaultConfiguration = FKSkeletonConfiguration(cornerRadius: 8, animationMode: .pulse)
```

### Loading helpers

```swift
rootView.fk_setSkeletonLoading(true)
rootView.fk_withSkeletonLoading { done in
  api.fetch { _ in done() }
}
```

### Explicit manager

```swift
FKSkeletonManager.shared.show(on: hostView, options: .init(), animated: true)
FKSkeletonManager.shared.hide(on: hostView, animated: true, completion: nil)
```

## API surface (quick index)

- Namespace: `FKSkeleton.defaultConfiguration`
- Models: `FKSkeletonConfiguration`, `FKSkeletonDisplayOptions`, `FKSkeletonShape`, `FKSkeletonAvatarStyle`, `FKSkeletonShimmerDirection`, `FKSkeletonAnimationMode`, `FKSkeletonStyle`
- Views: `FKSkeletonView`, `FKSkeletonContainerView`, `FKSkeletonPresets`
- Cells: `FKSkeletonTableViewCell`, `FKSkeletonCollectionViewCell`
- Manager: `FKSkeletonManager`
- Extensions: `UIView` (`fk_*`), `UILabel` / `UIImageView` / `UIButton` / `UITextField` convenience methods

## Performance notes

- Prefer `FKSkeletonContainerView.usesUnifiedShimmer = true` for multi-block layouts inside scrolling surfaces (one masked gradient vs. many).
- Avoid enabling auto mode on huge off-screen hierarchies.

## Examples

Sample apps live under `Examples/FKKitExamples/.../Skeleton/`:

- `Hub/` — index of scenarios  
- `Support/` — shared layout helpers & cells  
- `Scenarios/` — one screen per integration style  

## License

See the repository [`LICENSE`](../../../../LICENSE) file.
