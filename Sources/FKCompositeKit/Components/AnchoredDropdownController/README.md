# Anchored dropdown (`FKAnchoredDropdownController`)

This folder contains a **composite** UIKit controller that combines **`FKTabBar`** with an **anchor-embedded** dropdown panel, using **`FKPresentationController`** from **`FKUIKit`**.

## When to use it

Use **`FKAnchoredDropdownController`** when you need **Meituan-style** interactions:

- Tap a tab to open a panel **anchored below the tab bar**.
- Tap the **same** tab again to **toggle** closed.
- Tap a **different** tab to **switch** panels (previous closes, then the new one opens).
- Tap the **backdrop** (or swipe dismiss, if configured) to close.

It is **not** a general-purpose filter framework; each tab’s **content** is whatever `UIViewController` you supply per tab.

## Main types

| Type | Role |
|------|------|
| **`FKAnchoredDropdownController<TabID>`** | `UIViewController` hosting tab bar + presentation lifecycle. `TabID` is your stable tab identifier (`Hashable`). |
| **`FKAnchoredDropdownTab<TabID>`** | Describes a tab (id, title, optional icon, and a **content factory**). |
| **`FKAnchoredDropdownConfiguration`** | Tab bar styling, presentation animation (`SwitchAnimationStyle`), content caching (`ContentCachingPolicy`), mask behavior, etc. |
| **`FKAnchoredDropdownConfiguration.Callbacks<TabID>`** | `willOpen` / `didOpen` / `willClose` / `didClose` / switching hooks and state observation. |
| **`FKAnchoredDropdownTabBarHost`** | Protocol + default host so you can swap the **container** around the embedded **`FKTabBar`**. |
| **`FKAnchoredDropdownContentContainerViewController`** | Internal container used with anchor presentation; advanced customization starts here. |

## Dependencies

- **`FKUIKit`**: **`FKTabBar`**, **`FKPresentationController`** (`.anchorEmbedded` mode and related configuration).
- **`FKCoreKit`**: available to your **content** view controllers as usual (not required by this component’s public surface).

## Integration sketch

1. Define a `TabID` enum (or use `Int` / `String`).
2. Build `[FKAnchoredDropdownTab<TabID>]` with a **factory** per tab that returns the panel’s `UIViewController`.
3. Create **`FKAnchoredDropdownController`** with `configuration` and `callbacks`.
4. Embed the controller in your hierarchy (e.g. as a child of your root tab or navigation shell).

For API details, read the doc comments on **`FKAnchoredDropdownController`** and **`FKAnchoredDropdownConfiguration`** in the Swift sources next to this file.

## Root README policy

The repository **root** `README.md` keeps the **module tree** truthful but **light**; composite features that are not “first-line marketing” bullets still have **this file** for integrators who search by path.
