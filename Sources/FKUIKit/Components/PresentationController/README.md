# FKPresentationController

`FKPresentationController` is a UIKit-first presentation infrastructure for FKKit. It unifies bottom/top sheets, center modals, and anchor dropdowns under one API, with production-focused configuration for animation, safe area, keyboard, backdrop, interaction, and lifecycle handlers.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Presentation Modes](#presentation-modes)
- [Requirements](#requirements)
- [Installation](#installation)
  - [Swift Package Manager](#swift-package-manager)
- [Basic Usage](#basic-usage)
  - [One-line Bottom Sheet](#one-line-bottom-sheet)
  - [Top Sheet](#top-sheet)
  - [Center Modal](#center-modal)
  - [Anchor Popup](#anchor-popup)
- [Advanced Usage](#advanced-usage)
  - [Sheet Detents and Programmatic Switching](#sheet-detents-and-programmatic-switching)
  - [Backdrop Styles](#backdrop-styles)
  - [Safe Area Policy](#safe-area-policy)
  - [Keyboard Avoidance](#keyboard-avoidance)
  - [Animation Control](#animation-control)
  - [Lifecycle Handlers / Delegate](#lifecycle-handlers--delegate)
  - [Background Interaction Policy](#background-interaction-policy)
- [API Reference](#api-reference)
  - [Core Types](#core-types)
  - [Main APIs](#main-apis)
  - [Configuration Highlights](#configuration-highlights)
- [Best Practices](#best-practices)
- [Internal Architecture](#internal-architecture)
- [Notes](#notes)
- [License](#license)

## Overview

This component is designed for large UIKit codebases:

- Unified API across multiple presentation paradigms
- Modal host path for sheet/center/anchor/edge
- Anchor host path for in-hierarchy anchor dropdowns
- Strongly-typed configuration model
- Main-actor friendly lifecycle and handlers
- Interactive dismissal and detent change hooks

## Features

- Supports `bottomSheet`, `topSheet`, `center`, `anchor`, and `edge`
- Detent-based sheet sizing (`fitContent`, `fixed`, `fraction`, `full`)
- Programmatic detent switching through controller API
- Backdrop styles: `none`, `dim`
- Safe area strategies for container/content separation
- Keyboard avoidance strategies (`adjustContainer`, `adjustContentInsets`, `interactive`)
- Configurable animation preset/timing/custom animator
- Flexible dismiss behavior (tap outside, swipe, backdrop tap)
- Background interaction policy with optional passthrough behavior
- Anchor-hosted hosting with z-order and mask coverage policies

## Presentation Modes

- **`.bottomSheet`**: bottom-attached sheet presentation (default)
- **`.topSheet`**: top-attached sheet presentation
- **`.center`**: centered floating modal
- **`.anchor(FKAnchorConfiguration)`**: anchor popup hosted in existing view hierarchy
- **`.edge(UIRectEdge)`**: custom edge-based tray/panel behavior

## Requirements

- Swift 5.9+
- UIKit / Foundation
- iOS 15+ in current `FKUIKit` package setup

## Installation

### Swift Package Manager

Add `FKKit` and depend on `FKUIKit`.

```swift
dependencies: [
  .package(url: "https://github.com/your-org/FKKit.git", from: "1.0.0")
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

Then import:

```swift
import FKUIKit
```

## Basic Usage

### One-line Bottom Sheet

```swift
let content = UIViewController()
content.view.backgroundColor = .systemBackground
content.preferredContentSize = CGSize(width: 0, height: 320)

var configuration = FKPresentationConfiguration()
configuration.layout = .bottomSheet(configuration.sheet)

let presentation = FKPresentationController.present(
  contentController: content,
  from: self,
  configuration: configuration,
  animated: true
)
```

### Top Sheet

```swift
var configuration = FKPresentationConfiguration()
configuration.layout = .topSheet(configuration.sheet)

FKPresentationController.present(
  contentController: contentVC,
  from: self,
  configuration: configuration
)
```

### Center Modal

```swift
var configuration = FKPresentationConfiguration()
configuration.layout = .center(configuration.center)
configuration.center.size = .fitted(maxSize: CGSize(width: 460, height: 640))
configuration.cornerRadius = 16

FKPresentationController.present(
  contentController: contentVC,
  from: self,
  configuration: configuration
)
```

### Anchor Popup

```swift
let anchor = FKAnchor(
  sourceView: anchorView,
  edge: .bottom,
  direction: .down,
  alignment: .fill,
  widthPolicy: .matchContainer,
  offset: 0
)

var configuration = FKPresentationConfiguration()
let anchorConfig = FKAnchorConfiguration(
  anchor: anchor,
  hostStrategy: .inSameSuperviewBelowAnchor,
  zOrderPolicy: .keepAnchorAbovePresentation,
  maskCoveragePolicy: .fullScreen
)
configuration.layout = .anchor(anchorConfig)

FKPresentationController.present(
  contentController: popupVC,
  from: self,
  configuration: configuration
)
```

## Advanced Usage

### Sheet Detents and Programmatic Switching

```swift
var configuration = FKPresentationConfiguration()
configuration.layout = .bottomSheet(configuration.sheet)
configuration.sheet.detents = [.fitContent, .fraction(0.5), .full]
configuration.sheet.initialDetentIndex = 0

let controller = FKPresentationController.present(
  contentController: formVC,
  from: self,
  configuration: configuration
)

// Later:
controller.setDetent(.full, animated: true)
// or:
controller.setDetent(index: 1, animated: true)
```

### Backdrop Styles

```swift
var configuration = FKPresentationConfiguration()
configuration.backdropStyle = .dim(color: .black, alpha: 0.35)
// Alternatives:
// configuration.backdropStyle = .none
```

### Safe Area Policy

```swift
var configuration = FKPresentationConfiguration()
configuration.safeAreaPolicy = .contentRespectsSafeArea
// Alternative:
// configuration.safeAreaPolicy = .containerRespectsSafeArea
```

### Keyboard Avoidance

```swift
var configuration = FKPresentationConfiguration()
configuration.keyboardAvoidance.isEnabled = true
configuration.keyboardAvoidance.strategy = .interactive
configuration.keyboardAvoidance.additionalBottomInset = 8
```

### Animation Control

```swift
var configuration = FKPresentationConfiguration()
configuration.animation.preset = .spring
configuration.animation.duration = 0.32
configuration.animation.dampingRatio = 0.9

// Disable transition animation:
// configuration.animation.preset = .none
// configuration.animation.duration = 0
```

### Lifecycle Handlers / Delegate

```swift
let handlers = FKPresentationLifecycleHandlers(
  willPresent: { print("willPresent") },
  didPresent: { print("didPresent") },
  willDismiss: { print("willDismiss") },
  didDismiss: { print("didDismiss") },
  progress: { progress in print("progress:", progress) },
  detentDidChange: { detent, index in
    print("detent changed:", detent, index)
  }
)

let controller = FKPresentationController(
  contentController: contentVC,
  configuration: configuration,
  delegate: nil,
  handlers: handlers
)
controller.present(from: self, animated: true)
```

### Background Interaction Policy

```swift
var configuration = FKPresentationConfiguration()
configuration.backgroundInteraction.isEnabled = false
configuration.backgroundInteraction.showsBackdropWhenEnabled = true
```

## API Reference

### Core Types

- `FKPresentationController`
- `FKPresentationConfiguration`
- `FKPresentationConfiguration.Layout`
- `FKPresentationDetent`
- `FKAnchorConfiguration`
- `FKBackdropStyle`
- `FKSafeAreaPolicy`
- `FKKeyboardAvoidanceStrategy`
- `FKPresentationControllerDelegate`
- `FKPresentationLifecycleHandlers`

### Main APIs

- `FKPresentationController.init(contentController:configuration:delegate:handlers:)`
- `FKPresentationController.present(from:animated:completion:)`
- `FKPresentationController.dismiss(animated:completion:)`
- `FKPresentationController.setDetent(_:animated:)`
- `FKPresentationController.setDetent(index:animated:)`
- `FKPresentationController.present(contentController:from:configuration:delegate:handlers:animated:completion:)`

### Configuration Highlights

- Placement: `layout`
- Sheet behavior: `sheet.detents`, `sheet.initialDetentIndex`, thresholds, magnetic snapping
- Center behavior: `center.size`, margins, interactive dismiss settings
- Interaction: `dismissBehavior`, `backgroundInteraction`
- Visuals: `cornerRadius`, `shadow`, `border`, `backdropStyle`, `contentInsets`
- Adaptation: `safeAreaPolicy`, `keyboardAvoidance`, `rotationHandling`, `preferredContentSizePolicy`
- Motion: `animation`
- Accessibility/Haptics: `accessibility`, `haptics`

## Best Practices

- Keep all presentation operations on main actor (`present`, `dismiss`, `setDetent`).
- Prefer `.anchor` for in-page dropdown UX where anchor z-order and hierarchy attachment matter.
- Use `preferredContentSize` on content controllers for predictable fit-content behavior.
- Use callback/delegate hooks to sync business state with transition state.
- For deterministic no-motion UX, set `configuration.animation.preset = .none`.

## Internal Architecture

- `Public/`: stable API surface (`Core`, `Configuration`, `Animation`, `Anchor`, `Model`, `Support`)
- `Internal/Host/Container`: modal `UIPresentationController` pipeline split by concern (`+Layout`, `+Gesture`, `+Keyboard`, `+Backdrop`, `+Scroll`, `+Callbacks`)
- `Internal/Host/Anchor`: in-hierarchy anchor hosting (`FKAnchorHost`, host view controller, reposition coordinator)
- `Internal/Core`: routing contracts and shared resolvers (`FKPresentationHost`, transitioning delegate, anchor layout resolver)
- `Internal/Support`: shared internal utilities (for example responder-chain lookup)

## Notes

- `anchor` layout uses anchor hosting and does not go through the modal `UIPresentationController` path.
- Detent APIs are meaningful for sheet modes; non-sheet modes ignore detent switching.
- `backgroundInteraction.isEnabled` is an advanced setting; enable only when passthrough behavior is intentional.
- In anchor-hosted layout, choose `maskCoveragePolicy` carefully (`fullScreen` vs `belowAnchorOnly`) based on expected touch interception.

## License

`FKPresentationController` is part of the FKKit project and is distributed under the same license as this repository.
