# FKToast

Lightweight global message presenter for iOS, built with pure Swift and native UIKit/SwiftUI interop.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
  - [Swift Package Manager](#swift-package-manager)
  - [CocoaPods](#cocoapods)
- [Usage](#usage)
  - [Quick Start](#quick-start)
  - [Preset Styles](#preset-styles)
  - [Show Positions](#show-positions)
  - [Animation Options](#animation-options)
  - [Custom Configuration](#custom-configuration)
  - [Custom View](#custom-view)
  - [SwiftUI Support](#swiftui-support)
  - [Global Configuration](#global-configuration)
- [API Reference](#api-reference)
- [License](#license)

## Overview

`FKToast` is a lightweight global hint component that supports both classic floating **Toast** and action-oriented **Snackbar** presentation modes.

It is designed for production UIKit-based projects that need:

- one-line global calls without view-controller coupling
- queue-safe message orchestration (no stacked overlays)
- customizable visual and interaction behavior
- native dark mode / safe-area / rotation adaptation

`FKToast` addresses common pain points in ad-hoc toast implementations, such as overlapping messages, inconsistent styles, and hard-to-maintain per-screen presenters.

## Features

- Dual presentation modes: `toast` and `snackbar`
- Built-in preset styles: `normal`, `success`, `error`, `warning`, `info`
- Global singleton-like API entry via `FKToast`
- Serialized queue handling for concurrent calls
- Position support: top / center / bottom (safe-area aware)
- Auto-dismiss, tap-to-dismiss, and swipe-to-dismiss interactions
- Action button support via `FKToastAction`
- Per-message configuration + global default configuration
- Custom UIKit content view support
- SwiftUI view hosting support (`UIHostingController` bridge)
- Main-thread-safe rendering even when called from background threads
- Pure Swift, no third-party runtime dependency

## Requirements

- iOS 13.0+
- Swift 5.0+
- Xcode 15.0+ (recommended)

## Installation

### Swift Package Manager

Add `FKKit` to your dependencies, then import `FKUIKit`.

```swift
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

If your project integrates FKKit through CocoaPods, add:

```ruby
pod 'FKKit/FKUIKit'
```

Then run:

```bash
pod install
```

## Usage

### Quick Start

```swift
import FKUIKit

FKToast.show("Saved successfully")
FKToast.show("Network unavailable", style: .error, kind: .snackbar)
```

### Preset Styles

```swift
FKToast.show("Default message", style: .normal)
FKToast.show("Success", style: .success)
FKToast.show("Error", style: .error)
FKToast.show("Warning", style: .warning)
FKToast.show("Info", style: .info)
```

### Show Positions

```swift
let top = FKToastConfiguration(kind: .toast, style: .info, position: .top)
FKToast.show("Top message", configuration: top)

let center = FKToastConfiguration(kind: .toast, style: .normal, position: .center)
FKToast.show("Center message", configuration: center)

let bottom = FKToastConfiguration(kind: .snackbar, style: .warning, position: .bottom)
FKToast.show("Bottom snackbar", configuration: bottom)
```

### Animation Options

```swift
var fade = FKToastConfiguration(kind: .toast, style: .normal)
fade.animationStyle = .fade
fade.animationDuration = 0.2
FKToast.show("Fade animation", configuration: fade)

var slide = FKToastConfiguration(kind: .snackbar, style: .info)
slide.animationStyle = .slide
slide.animationDuration = 0.28
FKToast.show("Slide animation", configuration: slide)
```

### Custom Configuration

```swift
var config = FKToastConfiguration(kind: .snackbar, style: .success)
config.duration = 3.0
config.cornerRadius = 16
config.backgroundColor = .systemIndigo
config.textColor = .white
config.iconTintColor = .white
config.itemSpacing = 12
config.outerInsets = .init(top: 20, leading: 16, bottom: 24, trailing: 16)
config.contentInsets = .init(top: 14, leading: 16, bottom: 14, trailing: 16)
config.action = FKToastAction(title: "UNDO", titleColor: .white)

FKToast.show("Profile updated", configuration: config) {
  // handle action
}
```

### Custom View

```swift
let custom = UIStackView()
custom.axis = .horizontal
custom.spacing = 8

let dot = UIView(frame: .init(x: 0, y: 0, width: 8, height: 8))
dot.backgroundColor = .systemGreen
dot.layer.cornerRadius = 4

let label = UILabel()
label.text = "Connected"
label.font = .preferredFont(forTextStyle: .subheadline)
label.textColor = .white

custom.addArrangedSubview(dot)
custom.addArrangedSubview(label)

FKToast.show(customView: custom, configuration: FKToastConfiguration(kind: .toast, style: .normal))
```

### SwiftUI Support

```swift
import SwiftUI
import FKUIKit

struct ToastTag: View {
  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: "sparkles")
      Text("Hello from SwiftUI")
        .font(.subheadline)
    }
    .foregroundStyle(.white)
  }
}

FKToast.show(
  swiftUIView: ToastTag(),
  configuration: FKToastConfiguration(kind: .toast, style: .info)
)
```

### Global Configuration

```swift
@MainActor
func configureGlobalToastTheme() {
  var global = FKToastConfiguration(kind: .toast, style: .normal)
  global.font = .preferredFont(forTextStyle: .callout)
  global.duration = 2.2
  global.animationStyle = .slide
  global.cornerRadius = 14
  FKToast.defaultConfiguration = global
}
```

Clear active + queued messages:

```swift
FKToast.clearAll(animated: true)
```

## API Reference

### Core Entry

- `FKToast.defaultConfiguration`
- `FKToast.show(_:style:kind:)`
- `FKToast.show(_:icon:configuration:actionHandler:)`
- `FKToast.show(customView:configuration:actionHandler:)`
- `FKToast.show(swiftUIView:configuration:actionHandler:)`
- `FKToast.clearAll(animated:)`

### Models

- `FKToastConfiguration`: per-message visual/behavior configuration
- `FKToastAction`: action button model

### Enums

- `FKToastKind`: `toast`, `snackbar`
- `FKToastStyle`: `normal`, `success`, `error`, `warning`, `info`
- `FKToastPosition`: `top`, `center`, `bottom`
- `FKToastAnimationStyle`: `fade`, `slide`

## License

`FKToast` is part of the FKKit project and is released under the MIT License.  
See [LICENSE](../../../../LICENSE).
