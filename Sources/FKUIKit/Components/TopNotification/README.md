# FKTopNotification

[![iOS](https://img.shields.io/badge/iOS-13.0%2B-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange.svg)](https://swift.org/)
[![SPM](https://img.shields.io/badge/SPM-supported-brightgreen.svg)](https://swift.org/package-manager/)
[![CocoaPods](https://img.shields.io/badge/CocoaPods-supported-ee3322.svg)](https://cocoapods.org/)
[![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)](LICENSE)

Lightweight, pure-native top floating notification component for iOS apps, with UIKit + SwiftUI interoperability and global in-app presentation.

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
  - [Custom Content](#custom-content)
  - [Custom View](#custom-view)
  - [Progress Notification](#progress-notification)
  - [Queue Management](#queue-management)
  - [Interaction](#interaction)
  - [Global Configuration](#global-configuration)
  - [SwiftUI Support](#swiftui-support)
- [API Reference](#api-reference)
- [License](#license)

## Overview

`FKTopNotification` is a lightweight global in-app top notification component for iOS, built with pure Swift and no third-party runtime dependencies.

It delivers a system-notification-like experience inside your app:

- global one-line API calls
- top window-level presentation without page coupling
- modern styles and interactions for actionable, non-intrusive feedback

It is designed to solve common product UX needs such as upload/download status, operation feedback, warnings, and actionable banners while keeping integration minimal and maintainable.

## Features

- Pure native Swift implementation, no third-party library dependency
- Global and non-invasive API (`FKTopNotification.show(...)`)
- Top-level window presentation across app screens
- Five built-in styles: `normal`, `success`, `error`, `warning`, `info`
- Rich content model: title, subtitle, icon, trailing action button
- Fully custom content support with `UIView` or SwiftUI `View`
- Queue-based serialized rendering (no stacked overlap)
- Priority scheduling with high-priority preemption
- Progress notification with real-time update capability
- Auto-dismiss with configurable duration
- Manual dismissal (`hideCurrent`, per-handle `hide`)
- User interaction support: tap callback, action callback, swipe-to-dismiss
- Dynamic dark mode and safe-area aware layout
- Rotation-safe Auto Layout rendering
- Thread-safe calls from any queue (UI updates are main-thread handled)
- Global default configuration with per-notification override
- Typed API design with enums/structs for compile-time safety

## Requirements

- iOS 13.0+
- Swift 5.9+
- Xcode 14.0+ (recommended: latest stable release)

## Installation

### Swift Package Manager

Add `FKKit` to your dependencies, then import `FKUIKit`.

```swift
dependencies: [
  .package(url: "https://github.com/feng-zhang0712/FKKit.git", from: "0.35.1")
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

Show a top notification with one line:

```swift
import FKUIKit

FKTopNotification.show("Saved successfully", style: .success)
```

### Preset Styles

`FKTopNotification` ships with five built-in style levels:

```swift
FKTopNotification.show("Default message", style: .normal)
FKTopNotification.show("Operation completed", style: .success)
FKTopNotification.show("Something went wrong", style: .error)
FKTopNotification.show("Please review this warning", style: .warning)
FKTopNotification.show("Heads up: info update", style: .info)
```

### Custom Content

Customize title, subtitle, leading icon, trailing action button, and visual config:

```swift
var config = FKTopNotificationConfiguration(
  style: .info,
  priority: .high,
  duration: 4.0,
  action: FKTopNotificationAction(title: "VIEW", titleColor: .white)
)
config.cornerRadius = 16
config.backgroundColor = .systemIndigo
config.textColor = .white
config.subtitleColor = UIColor(white: 1, alpha: 0.85)

FKTopNotification.show(
  title: "Build Finished",
  subtitle: "Tap to inspect output details.",
  icon: UIImage(systemName: "hammer.fill"),
  configuration: config,
  onTap: {
    // Handle body tap
  },
  onAction: {
    // Handle action button tap
  }
)
```

### Custom View

Provide any custom `UIView` as notification content:

```swift
let stack = UIStackView()
stack.axis = .horizontal
stack.spacing = 8

let dot = UIView(frame: .init(x: 0, y: 0, width: 8, height: 8))
dot.backgroundColor = .systemGreen
dot.layer.cornerRadius = 4

let label = UILabel()
label.text = "Connected to production"
label.textColor = .white
label.font = .preferredFont(forTextStyle: .subheadline)

stack.addArrangedSubview(dot)
stack.addArrangedSubview(label)

FKTopNotification.show(
  customView: stack,
  configuration: FKTopNotificationConfiguration(style: .normal)
)
```

### Progress Notification

Use progress mode for upload/download style feedback:

```swift
var config = FKTopNotificationConfiguration(style: .info, priority: .high, duration: 0)
config.progressTintColor = .systemBlue
config.progressTrackColor = UIColor(white: 1, alpha: 0.22)

let handle = FKTopNotification.show(
  title: "Uploading...",
  subtitle: "Please keep the app open.",
  configuration: config,
  progress: 0.1
)

handle.updateProgress(0.45)
handle.updateProgress(0.88)
handle.hide()
```

### Queue Management

Notifications are serialized automatically to avoid overlap.

Priority controls queue order and allows urgent banners to preempt:

```swift
FKTopNotification.show(
  title: "Background sync complete",
  configuration: .init(style: .success, priority: .normal)
)

FKTopNotification.show(
  title: "Connection Lost",
  configuration: .init(style: .error, priority: .critical)
)
```

### Interaction

Built-in interaction model:

- tap callback (`onTap`)
- action callback (`onAction`)
- swipe-up gesture to dismiss (enabled by default)
- manual close via handle or static API

```swift
let handle = FKTopNotification.show(
  title: "Draft Saved",
  configuration: .init(style: .success, tapToDismiss: true, swipeToDismiss: true)
)

// Manually dismiss this specific notification
handle.hide()

// Dismiss current active notification
FKTopNotification.hideCurrent()

// Clear current + queued notifications
FKTopNotification.clearAll()
```

### Global Configuration

Set app-wide defaults once (for example at app launch):

```swift
@MainActor
func setupTopNotificationDefaults() {
  var global = FKTopNotificationConfiguration(style: .normal)
  global.duration = 2.2
  global.animationDuration = 0.25
  global.animationStyle = .slide
  global.animationCurve = .easeOut
  global.cornerRadius = 14
  FKTopNotification.defaultConfiguration = global
}
```

Each `show(...)` call can still override any option with its own configuration.

### SwiftUI Support

Display a SwiftUI view via hosting bridge:

```swift
import SwiftUI
import FKUIKit

struct TopBannerView: View {
  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: "sparkles")
      Text("Hello from SwiftUI")
        .font(.subheadline)
    }
    .foregroundStyle(.white)
    .padding(.vertical, 4)
  }
}

@MainActor
func showSwiftUIBanner() {
  FKTopNotification.show(
    swiftUIView: TopBannerView(),
    configuration: FKTopNotificationConfiguration(style: .info)
  )
}
```

## API Reference

### Core Entry

- `FKTopNotification.defaultConfiguration`
- `FKTopNotification.show(_:style:)`
- `FKTopNotification.show(title:subtitle:icon:configuration:progress:onTap:onAction:)`
- `FKTopNotification.show(customView:configuration:onTap:onAction:)`
- `FKTopNotification.show(swiftUIView:configuration:onTap:onAction:)`
- `FKTopNotification.hideCurrent(animated:)`
- `FKTopNotification.hide(id:animated:)`
- `FKTopNotification.updateProgress(id:progress:)`
- `FKTopNotification.clearAll(animated:)`

### Handle

- `FKTopNotificationHandle.hide(animated:)`
- `FKTopNotificationHandle.updateProgress(_:)`

### Models

- `FKTopNotificationConfiguration`
- `FKTopNotificationAction`

### Enums

- `FKTopNotificationStyle`: `normal`, `success`, `error`, `warning`, `info`
- `FKTopNotificationPriority`: `low`, `normal`, `high`, `critical`
- `FKTopNotificationAnimationStyle`: `fade`, `slide`
- `FKTopNotificationAnimationCurve`: `easeInOut`, `easeOut`, `easeIn`, `linear`
- `FKTopNotificationSound`: `none`, `default`, `custom(url:)`

## License

`FKTopNotification` is part of FKKit and released under the MIT License.  
See [LICENSE](../../../../LICENSE).
