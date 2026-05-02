# FKToast

Global **Toast**, **HUD**, and **Snackbar** presenter for UIKit-first apps, with optional SwiftUI hosting. One queue coordinates bursts, deduplication, and priority; rendering respects safe area, keyboard, navigation bar, and tab bar.

## Requirements

- iOS 13+
- Swift 5.9+ (Swift concurrency)
- `import FKUIKit`

## Source layout

Same layering as **`Badge`** and **`PresentationController`**: **`Public`** (API you import), **`Internal`** (implementation). Paths live under `Sources/FKUIKit/Components/Toast/`.

### `Public/`

| File | Role |
|------|------|
| `FKToast.swift` | `FKToast`, `FKToastHandle`, `FKHUD`, `FKSnackbar` — global entry points |
| `FKToastConfiguration.swift` | `FKToastConfiguration`, queue/lifecycle/action/localization helpers |
| `FKToastContent.swift` | `FKToastContent`, `FKToastBuilder`, SwiftUI builder helper |
| `FKToastTypes.swift` | `FKToastStyle`, placement, animation, priority, dismiss reasons, symbols, blur, sound |

### `Internal/`

| File | Role |
|------|------|
| `FKToastCenter.swift` | Window resolution, presentation, timers, keyboard/layout observers |
| `FKToastPresentation.swift` | Binds one request to its view and position constraint |
| `FKToastQueue.swift` | `FKToastQueueActor`, `FKToastRequest`, arrival policy |
| `FKToastView.swift` | Layout, chrome, gestures, Dynamic Type labels |
| `FKToastAnimator.swift` | Enter/exit animations |
| `FKToastBlockingView.swift` | Touch interception with optional passthrough rects |

## API overview

### Threading

- `FKToast.show(...)`, `FKToast.show(builder:)`, `FKHUD.*`, and `FKSnackbar.show(...)` may be called from **any** thread; UI work runs on the **main actor**.
- `FKToast.defaultConfiguration`, `FKToast.isPresenting`, and SwiftUI `show(swiftUIView:)` are **`@MainActor`**.
- `showReturningID` / `showReturningHandle`, `update`, and `updateProgress` are `async` and hop to the main actor as needed.

### Core types

| Type | Purpose |
|------|---------|
| `FKToastKind` | `.toast` (transient), `.hud` (centered, may block touches), `.snackbar` (bottom, actions) |
| `FKToastConfiguration` | Duration, timeout, position, queue policy, typography, blur, accessibility |
| `FKToastBuilder` | Content + configuration + hooks + primary/secondary action handlers |
| `FKToastDismissReason` | Fed into `FKToastLifecycleHooks` (`userTap`, `userLongPress`, `timeout`, …) |

### Naming (Swift API Design Guidelines)

- **`showReturningID`** / **`showReturningHandle`** — async APIs that yield a stable `UUID` or `FKToastHandle` for updates and dismissal.
- **`FKHUD`** / **`FKSnackbar`** — thin presets on top of `FKToast` for the most common product flows without extra configuration.

## Quick start

```swift
import UIKit
import FKUIKit

FKToast.show("Saved", style: .success, kind: .toast)
FKHUD.showLoading("Syncing…", interceptTouches: true, timeout: 20)
FKSnackbar.show("Offline", action: .init(title: "Retry"), style: .warning) {
  // retry
}
```

### Global defaults

```swift
@MainActor
func configureToastAtLaunch() {
  var base = FKToastConfiguration()
  base.duration = 2.4
  base.font = .preferredFont(forTextStyle: .callout)
  FKToast.defaultConfiguration = base
}
```

### Advanced: builder + stable id

```swift
Task {
  let id = await FKToast.showReturningID(
    builder: .init(
      content: .message("Uploading"),
      configuration: .init(kind: .hud, style: .loading, duration: 0, timeout: 60, interceptTouches: true)
    )
  )
  _ = await FKToast.updateProgress(id, progress: 0.42)
}
```

### Custom view + VoiceOver

For `customView` / SwiftUI content, set `accessibilityAnnouncementOverride` when automatic text derivation is not possible.

## Example app layout

Under `Examples/.../FKUIKit/Toast/`:

| Path | Contents |
|------|----------|
| `FKToastExamplesHubViewController.swift` | Navigation hub |
| `Support/` | `FKToastExampleUI`, `FKToastExampleBaseViewController` |
| `Playbook/` | `FKToastExamplePlaybook` — shared demo triggers |
| `Pages/` | One `UIViewController` per topic (basics, queue, HUD, snackbar, environment, SwiftUI) |

## Accessibility

- `accessibilityAnnouncementEnabled` + optional `accessibilityAnnouncementOverride`
- Action buttons support `accessibilityLabel`
- HUD text paths use `.updatesFrequently` where appropriate

## Multi-window / scenes

The center picks a **foreground active** `UIWindowScene` key window. In multi-scene setups, invoke presentation from code running in the scene that should own the overlay.
