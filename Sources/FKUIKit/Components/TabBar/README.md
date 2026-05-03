# FKTabBar

`FKTabBar` is a UIKit-native **tab strip** (segmented header) for apps worldwide: it renders tabs, animates an indicator, integrates `FKBadge`, and exposes deterministic selection APIs. It intentionally does **not** own view controllers, navigation, or paging—hosts wire selection to their own containers.

Typical uses:

- **Pager header**: drive `setSelectionProgress(from:to:progress:)` from an external scroll view, then commit with `setSelectedIndex(_:reason:)`.
- **Bottom bar surface**: pin the view like `UITabBar` using layout + `FKTabBarAppearance` (still no `UITabBarController` wrapper).

---

## Source layout (Swift Package)

Files are grouped for readability; **all types remain `import FKUIKit`** regardless of folder.

| Area | Path | Responsibility |
|------|------|----------------|
| Public API | `Public/FKTabBar.swift` | Main `UIView` subclass |
| | `Public/Configuration/` | `FKTabBarConfiguration`, layout/appearance/animation enums |
| | `Public/Models/` | `FKTabBarItem`, text/image models, badge models |
| | `Public/Protocols/` | `FKTabBarDelegate`, `FKTabBarDataSource` |
| | `Public/Indicator/` | Indicator style configuration |
| | `Public/SwiftUI/` | `FKTabBarRepresentable` |
| Internal | `Internal/Selection/` | Selection reducer + `FKTabBarSwitchPhase` |
| | `Internal/Layout/` | Width, scroll alignment, indicator frame math, index sync |
| | `Internal/Views/` | `FKTabBarItemCell`, `FKTabBarIndicatorView` |
| | `Internal/Badge/` | Badge anchor resolution |

---

## Requirements

- Swift 6 language mode (see repo `Package.swift`)
- iOS 15+ / UIKit (current `FKUIKit` target)

---

## Installation (SwiftPM)

Add the `FKKit` package and depend on the **`FKUIKit`** product.

```swift
dependencies: [
  .package(url: "https://github.com/your-org/FKKit.git", from: "1.0.0"),
],
targets: [
  .target(name: "YourApp", dependencies: [.product(name: "FKUIKit", package: "FKKit")]),
]
```

```swift
import FKUIKit
```

---

## Threading

All public entry points are `@MainActor`. Call from the main thread only.

---

## Core concepts

### Items vs visible strip

- `items` — full array you pass in (includes `isHidden` tabs).
- `visibleItems` — read-only list actually laid out (hidden filtered out). Selection indices are **always relative to `visibleItems`**.

### Stable IDs

Use a stable `FKTabBarItem.id` across reloads. Selection preservation, badge updates by ID, and SwiftUI bridging rely on it.

### Configuration entry point

Prefer a single `FKTabBarConfiguration`:

```swift
var config = FKTabBarDefaults.defaultConfiguration
config.layout.isScrollable = true
config.layout.widthMode = .intrinsic
config.appearance.indicatorStyle = .line(.init())
let tabBar = FKTabBar(items: items, selectedIndex: 0, configuration: config)
```

Shortcuts `appearance`, `layoutConfiguration`, and `animationConfiguration` on `FKTabBar` mirror subtrees but exist for compatibility; new code should set `configuration` directly.

---

## Selection API

| API | Purpose |
|-----|---------|
| `setSelectedIndex(_:animated:notify:reason:)` | Programmatic selection; `notify: false` skips callbacks and VoiceOver announcement |
| `setSelectedIndex(forItemID:animated:notify:reason:)` | Select by stable `id` (returns `false` if ID not visible) |
| `selectionControlMode = .controlled` | Tap emits `onSelectionRequest` / delegate; host commits when ready |
| `setSelectionProgress(from:to:progress:)` | Interactive pager interpolation |

Callback order for a committed change: `shouldSelect` → delegate `shouldSelect` → `willSelect` → visual update → `onSelectionChanged` → delegate `didSelect`.

---

## SwiftUI

`FKTabBarRepresentable(items:selectedIndex:configuration:)` keeps UIKit rendering with a `Binding<Int>`. See doc comments in `Public/SwiftUI/FKTabBarRepresentable.swift` for binding sync rules when the item list changes.

---

## Badges

Configure per item via `FKTabBarBadgeConfiguration`. For frequent updates, prefer `setBadge(_:at:)` / `setBadge(_:forItemID:)` to avoid full `reloadData()`.

---

## RTL & Dynamic Type

`FKTabBar` reacts to `traitCollection.layoutDirection` and `preferredContentSizeCategory`. Tune `layout.rtlBehavior` and `layout.largeTextLayoutStrategy` for forced direction and accessibility text sizing.

---

## Example app layout

Under `Examples/.../FKUIKit/TabBar/`:

- `Hub/` — navigation hub
- `Shared/` — `FKTabBarExampleSupport` factories
- `Scenarios/<Topic>/` — grouped demos (Basics, Scrollable, Indicator, Badge, Accessibility, Dynamic, Performance, …)

---

## API checklist (public types)

- `FKTabBar`
- `FKTabBarItem`, `FKTabBarTextConfiguration`, `FKTabBarImageConfiguration`, …
- `FKTabBarBadgeConfiguration`, `FKTabBarBadgeContent`
- `FKTabBarConfiguration`, `FKTabBarLayoutConfiguration`, `FKTabBarAppearance`, `FKTabBarAnimationConfiguration`
- `FKTabBarIndicatorStyle` (+ related indicator configs)
- `FKTabBarDelegate`, `FKTabBarDataSource`
- `FKTabBarRepresentable` (SwiftUI)
- `FKTabBarDefaults`, `FKTabBarSwitchPhase`

---

## Best practices

1. Keep item IDs stable.
2. Integrate paging with progress APIs, then commit selection explicitly.
3. Use `notify: false` when mirroring external state to prevent loops.
4. Keep `itemViewProvider`, indicator providers, and `itemButtonConfigurator` lightweight on the main thread.

---

## License

Same as the enclosing FKKit repository.
