# FKToast

`FKToast` is a unified Toast / HUD / Snackbar component for iOS applications built with UIKit-first rendering and optional SwiftUI integration.

It is designed for production apps that need lightweight transient messages, blocking progress overlays, and action-oriented snackbars without coupling call sites to a specific view controller hierarchy.

## Overview

`FKToast` covers three presentation roles:

- **Toast**: short-lived, lightweight, non-blocking feedback.
- **HUD**: centered status or progress overlays that may optionally block interaction.
- **Snackbar**: bottom-aligned, action-capable messages intended for recoverable flows.

Key design goals:

- global, thread-safe entry points
- scene-aware window resolution
- queue and priority handling for burst traffic
- accessibility and Dynamic Type support
- keyboard, safe-area, navigation bar, and tab bar adaptation
- UIKit-native rendering with SwiftUI hosting support

Typical use cases:

- form validation feedback
- upload / sync progress
- retryable error messages
- system status updates after async work

## Features

- Unified APIs for Toast, HUD, and Snackbar presentation
- Built-in semantic styles: `normal`, `success`, `error`, `warning`, `info`, `loading`
- Queue management with arrival policy, deduplication window, and priority preemption
- Lifecycle hooks for `willShow`, `didShow`, `willDismiss`, and `didDismiss`
- Action and secondary action support for snackbar-like flows
- Dynamic Type-aware labels and buttons
- VoiceOver announcement support and accessibility labels for actions
- Positioning strategies for top / center / bottom overlays
- Navigation bar and tab bar aware top/bottom offsets
- Keyboard avoidance for bottom overlays
- Scene-aware window selection for multi-window apps
- Optional material blur and liquid-glass-preferred fallback behavior
- Custom SF Symbol mapping via `FKToastSymbolSet`
- Custom UIKit view embedding
- SwiftUI view hosting through `UIHostingController`
- Background-thread-safe public entry points with main-actor UI rendering
- No third-party runtime dependency

## Requirements

- iOS 13.0 or later
- Swift 5.0 or later
- UIKit-based host application
- No external runtime dependency beyond Apple frameworks already used by the package

## Installation

### Swift Package Manager

Add `FKKit` and depend on `FKUIKit`.

```swift
// Package.swift
dependencies: [
  .package(url: "https://github.com/feng-zhang0712/FKKit.git", from: "0.33.1")
],
targets: [
  .target(
    name: "YourApp",
    dependencies: [
      .product(name: "FKUIKit", package: "FKKit")
    ]
  )
]
```

```swift
import FKUIKit
```

### CocoaPods

If your project uses CocoaPods and the FKKit podspec exposes `FKUIKit`, add:

```ruby
pod 'FKKit/FKUIKit'
```

Then run:

```bash
pod install
```

### Manual integration

Manual integration is possible, but Swift Package Manager is recommended because this component lives inside the FKKit package structure and may rely on neighboring package targets and source organization.

## Quick Start

```swift
import UIKit
import FKUIKit

final class DemoViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()

    FKToast.show("Saved successfully", style: .success, kind: .toast)
    FKHUD.showLoading("Syncing profile…", interceptTouches: true, timeout: 15)
    FKSnackbar.show("Upload failed", action: .init(title: "Retry"), style: .error) {
      print("Retry tapped")
    }
  }
}
```

## Usage

### Toast

Use `FKToast` for brief, non-blocking feedback.

```swift
import UIKit
import FKUIKit

func showBasicToast() {
  FKToast.show("Profile updated")
}
```

#### Position

```swift
import FKUIKit

func showPositionedToasts() {
  FKToast.show(
    "Top toast",
    configuration: FKToastConfiguration(kind: .toast, style: .info, position: .top)
  )

  FKToast.show(
    "Center toast",
    configuration: FKToastConfiguration(kind: .toast, style: .normal, position: .center)
  )

  FKToast.show(
    "Bottom toast",
    configuration: FKToastConfiguration(kind: .toast, style: .warning, position: .bottom)
  )
}
```

#### Duration and style

```swift
import FKUIKit

func showStyledToast() {
  var configuration = FKToastConfiguration(kind: .toast, style: .success, duration: 3)
  configuration.animationStyle = .scale
  configuration.cornerRadius = 16

  FKToast.show("Order submitted", configuration: configuration)
}
```

#### Queue strategy

```swift
import FKUIKit

func showQueuedToasts() {
  var configuration = FKToastConfiguration(kind: .toast, style: .info, duration: 2)
  configuration.queue.arrivalPolicy = .coalesce
  configuration.queue.deduplicationWindow = 3

  for _ in 0..<3 {
    FKToast.show("Connection is unstable", configuration: configuration)
  }
}
```

#### Custom icon and custom view

```swift
import UIKit
import FKUIKit

func showCustomContentToast() {
  var iconConfiguration = FKToastConfiguration(kind: .toast, style: .info)
  iconConfiguration.symbolSet = .init(info: "sparkles")

  FKToast.show(
    "Custom symbol mapping",
    icon: UIImage(systemName: "bolt.fill"),
    configuration: iconConfiguration
  )

  let stack = UIStackView()
  stack.axis = .horizontal
  stack.spacing = 8

  let dot = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 8))
  dot.backgroundColor = .systemGreen
  dot.layer.cornerRadius = 4

  let label = UILabel()
  label.text = "Realtime stream connected"
  label.font = .preferredFont(forTextStyle: .subheadline)
  label.textColor = .white

  stack.addArrangedSubview(dot)
  stack.addArrangedSubview(label)

  FKToast.show(customView: stack, configuration: .init(kind: .toast, style: .normal))
}
```

### HUD

Use `FKHUD` when the user needs stronger feedback, progress visibility, or optional interaction blocking.

#### Loading

```swift
import FKUIKit

func showLoadingHUD() {
  FKHUD.showLoading("Fetching data…", interceptTouches: true, timeout: 20)
}
```

#### Success and failure

```swift
import FKUIKit

func showStatusHUDs() {
  FKHUD.showSuccess("Import completed")
  FKHUD.showFailure("Import failed")
}
```

#### Determinate progress

```swift
import FKUIKit

func showProgressHUD(progress: Double) {
  FKHUD.showProgress("Uploading", progress: progress, interceptTouches: true)
}
```

#### Blocking vs non-blocking

```swift
import FKUIKit

func showBlockingExamples() {
  FKHUD.showLoading("Blocking HUD", interceptTouches: true, timeout: 10)
  FKHUD.showLoading("Passthrough HUD", interceptTouches: false, timeout: 10)
}
```

#### Manual dismiss and timeout safety

```swift
import FKUIKit

func dismissHUDManually() {
  FKHUD.showLoading("Waiting for response…", interceptTouches: true, timeout: 30)

  // Later:
  FKToast.clearAll(animated: true)
}
```

Notes:

- `loading` renders a spinner.
- `success`, `error`, `warning`, and `info` render semantic symbols.
- `timeout` provides a safety net against hanging HUDs.

### Snackbar

Use `FKSnackbar` for action-oriented bottom messages.

#### Action and dismiss behavior

```swift
import FKUIKit

func showRetrySnackbar() {
  FKSnackbar.show(
    "Upload failed",
    action: .init(title: "Retry"),
    secondaryAction: .init(title: "Dismiss"),
    style: .error,
    actionHandler: {
      print("Retry tapped")
    },
    secondaryActionHandler: {
      print("Dismiss tapped")
    }
  )
}
```

#### Swipe dismiss

```swift
import FKUIKit

func showSwipeDismissSnackbar() {
  var configuration = FKToastConfiguration(kind: .snackbar, style: .info, duration: 6)
  configuration.swipeToDismiss = true

  FKToast.show("Swipe me away", configuration: configuration)
}
```

#### Accessibility-oriented snackbar

```swift
import FKUIKit

func showAccessibleSnackbar() {
  var configuration = FKToastConfiguration(
    kind: .snackbar,
    style: .info,
    duration: 5,
    action: .init(title: "Retry", accessibilityLabel: "Retry upload")
  )
  configuration.accessibilityAnnouncementEnabled = true

  FKToast.show(
    "Upload failed. Retry is available.",
    configuration: configuration
  ) {
    print("Retry triggered")
  }
}
```

### Advanced customization

#### Global defaults

```swift
import UIKit
import FKUIKit

@MainActor
func configureToastSystem() {
  var configuration = FKToastConfiguration(kind: .toast, style: .normal)
  configuration.font = .preferredFont(forTextStyle: .callout)
  configuration.titleFont = .preferredFont(forTextStyle: .headline)
  configuration.duration = 2.5
  configuration.cornerRadius = 14
  configuration.backgroundVisualEffect = .blur(style: .systemThinMaterial)
  configuration.topInsetWhenHasNavigationBar = 10
  configuration.bottomInsetWhenHasTabBar = 10

  FKToast.defaultConfiguration = configuration
}
```

#### Per-request override

```swift
import UIKit
import FKUIKit

func showOneOffToast() {
  var configuration = FKToastConfiguration(kind: .snackbar, style: .success, duration: 4)
  configuration.backgroundColor = .systemIndigo
  configuration.textColor = .white
  configuration.iconTintColor = .white
  configuration.symbolSet = .init(success: "checkmark.seal.fill")

  FKToast.show("One-off styled snackbar", configuration: configuration)
}
```

#### Lifecycle hooks

```swift
import FKUIKit

func showTrackedToast() {
  let hooks = FKToastLifecycleHooks(
    willShow: { id in print("willShow:", id) },
    didShow: { id in print("didShow:", id) },
    willDismiss: { id, reason in print("willDismiss:", id, reason) },
    didDismiss: { id, reason in print("didDismiss:", id, reason) }
  )

  FKToast.show(
    "Tracked toast",
    configuration: .init(kind: .toast, style: .info),
    hooks: hooks
  )
}
```

#### Queue policy tuning

```swift
import FKUIKit

func showPriorityAwareSnackbar() {
  var configuration = FKToastConfiguration(kind: .snackbar, style: .warning, priority: .high, duration: 4)
  configuration.queue.arrivalPolicy = .interruptAndRequeueCurrent
  configuration.queue.allowPriorityPreemption = true

  FKToast.show("High priority message", configuration: configuration)
}
```

Note:

The current implementation includes a clock abstraction for queue internals. Public scheduler or clock injection is not currently exposed as a stable public API, so prefer testing via lifecycle hooks and controlled request configuration.

### SwiftUI integration

SwiftUI calls use the same underlying presenter as UIKit.

```swift
import SwiftUI
import FKUIKit

struct ToastDemoView: View {
  var body: some View {
    VStack(spacing: 16) {
      Button("Show Toast") {
        FKToast.show("Saved from SwiftUI", style: .success, kind: .toast)
      }

      Button("Show HUD") {
        FKHUD.showLoading("Syncing…", interceptTouches: true, timeout: 10)
      }

      Button("Show Snackbar") {
        FKSnackbar.show(
          "Connection lost",
          action: .init(title: "Retry"),
          style: .warning,
          actionHandler: {
            print("Retry tapped")
          }
        )
      }
    }
    .padding()
  }
}
```

For fully custom SwiftUI content:

```swift
import SwiftUI
import FKUIKit

struct InlineToastContent: View {
  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: "sparkles")
      Text("Hello from SwiftUI")
        .font(.subheadline)
    }
    .foregroundStyle(.white)
  }
}

@MainActor
func showHostedSwiftUIView() {
  FKToast.show(
    swiftUIView: InlineToastContent(),
    configuration: FKToastConfiguration(kind: .toast, style: .info)
  )
}
```

## Accessibility

Built-in accessibility support includes:

- VoiceOver announcements via `accessibilityAnnouncementEnabled`
- Accessibility labels for action buttons through `FKToastAction.accessibilityLabel`
- Dynamic Type support on labels and buttons
- Appropriate element grouping for message content
- HUD content marked as frequently updating for assistive technologies

Recommendations:

- Keep snackbar actions short and explicit
- Disable automatic announcements for noisy, high-frequency events
- Provide custom `accessibilityLabel` when button text is ambiguous
- Prefer success/failure semantic styles over purely decorative colors

## Threading model

Public entry points are safe to call from any thread:

- `FKToast.show(...)`
- `FKToast.show(builder:)`
- `FKHUD.*`
- `FKSnackbar.show(...)`

Internally:

- UI creation, layout, animation, and dismissal run on the main actor
- Queue orchestration is isolated behind an actor
- SwiftUI hosting overloads that capture view values are explicitly `@MainActor`

Practical guidance:

- You may trigger a toast from async background work without manual `DispatchQueue.main.async`
- If you build UIKit views yourself for `customView`, create and configure them on the main thread

## Troubleshooting / FAQ

### Why is the toast shown in a different window than expected?

`FKToast` resolves the active foreground scene window. In multi-window apps, call the API from the scene that should own the overlay.

### My bottom snackbar is near the keyboard. Is keyboard avoidance supported?

Yes. Bottom overlays track keyboard frame changes and update their constraints to remain above the keyboard while preserving configured bottom spacing.

### What happens when I call show many times in a row?

Requests are queued and processed according to `FKToastQueueConfiguration`, including deduplication and priority preemption.

### How does top and bottom positioning interact with navigation bars or tab bars?

Top overlays can position below a visible navigation bar. Bottom overlays can position above a visible tab bar. Safe area and keyboard overlap are taken into account during final placement.

### Can I use this inside modal presentations?

Yes. The presenter resolves the top-most visible controller stack in the active scene and computes placement using the current container environment.

## License

This component is intended to be distributed under an open-source license such as MIT.

Replace this section with the license used by your repository and ensure a matching `LICENSE` file exists at the project root.

## Contributing

Contributions are welcome.

Recommended workflow:

1. Open an Issue describing the bug, API change, or feature request.
2. Keep pull requests focused and scoped to one concern.
3. Preserve naming, formatting, and documentation style already used in FKKit.
4. Add or update tests when behavior changes in a way that can be verified deterministically.
5. Include reproduction or validation steps in your PR description, especially for scene, keyboard, and accessibility behavior.

Before submitting a PR:

- run project checks relevant to your environment
- verify UIKit and SwiftUI examples still behave correctly
- document user-visible API changes in the README and changelog when applicable
