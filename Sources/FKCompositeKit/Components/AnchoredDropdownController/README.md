# Anchored dropdown (`FKAnchoredDropdownController`)

Composite UIKit controller: **`FKTabBar`** + **anchor-embedded panel** via **`FKPresentationController`** (`FKUIKit`).

## Layout

| Location | Role |
|----------|------|
| **`Public/`** | Controller, configuration, tab model, tab bar host protocol, anchor placement, defaults. |
| **`Internal/`** | Content container and SwiftUI-style view hosting helper. |
| **`Extension/`** | `FKAnchoredDropdownConfiguration` presets. |

## When to use

- Tap a tab to **expand** a panel anchored under the bar (or a custom view).
- Tap the **same** tab to **collapse**.
- Tap **another** tab to **switch** (in-place animation or dismiss-then-present, configurable).
- Dismiss via **backdrop / swipe** when enabled on `presentationConfiguration.dismissBehavior`.

Panel content is **your** `UIViewController` (or hosted `UIView`) per tab.

## Anchor

Default: source = ``FKAnchoredDropdownTabBarHost/tabBar``, overlay = the host’s `view`.

Custom: assign ``FKAnchoredDropdownConfiguration/anchorPlacement`` or call ``FKAnchoredDropdownController/setAnchor(source:overlayHost:)``. Adjust geometry with ``updateAnchorPlacement(...)``; ``resetAnchorToDefault()`` clears placement.

Choose `overlayHost` as an ancestor of `source` when possible so mask and layout bounds match the screen region you expect.

## Main types

| Type | Role |
|------|------|
| ``FKAnchoredDropdownController`` | Child-friendly `UIViewController`; generic `TabID: Hashable`. |
| ``FKAnchoredDropdownTab`` | Tab id, `makeTabBarItem`, and content factory. |
| ``FKAnchoredDropdownConfiguration`` | Tab bar + **full** `FKPresentationConfiguration` (dismiss, backdrop, keyboard, …), switch animation, caching, optional `anchorPlacement`. |
| ``FKAnchoredDropdownConfiguration/Events`` | Optional `on*` closures for state and transitions. |
| ``FKAnchoredDropdownAnchorPlacement`` | Weak `sourceView` / `overlayHostView` + `FKAnchor` fields. |
| ``FKAnchoredDropdownTabBarHost`` | Custom chrome around `FKTabBar`; default type ``FKAnchoredDropdownDefaultTabBarHost``. |

## Dependencies

- **FKUIKit**: `FKTabBar`, `FKPresentationController`, anchor types.
- **FKCoreKit**: optional for your own panel code.

Integration: build `[FKAnchoredDropdownTab]`, pick `configuration`, optionally `events`, then ``embed(in:pinTo:)`` or add as a child view controller.
