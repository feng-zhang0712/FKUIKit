# FKLoadingAnimator

`FKLoadingAnimator` is a pure native Swift loading animation component for UIKit.
It provides multiple built-in loading styles, full-screen and embedded presentation modes, determinate progress support, and protocol-based custom animation extension, all built on `UIKit` + `CoreAnimation` without third-party dependencies.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Supported Animation Styles](#supported-animation-styles)
  - [Circle / Ring Animations](#circle--ring-animations)
  - [Wave / Pulse Animations](#wave--pulse-animations)
  - [Particle Animations](#particle-animations)
  - [Classic Spinner](#classic-spinner)
  - [Dot / Gear Animations](#dot--gear-animations)
- [High Performance Advantages](#high-performance-advantages)
- [Requirements](#requirements)
- [Installation](#installation)
- [Basic Usage](#basic-usage)
  - [Show Fullscreen Loading](#show-fullscreen-loading)
  - [Add Embedded Loading to View](#add-embedded-loading-to-view)
  - [Start / Stop Animation](#start--stop-animation)
  - [Progress Ring Animation](#progress-ring-animation)
- [Advanced Usage](#advanced-usage)
  - [Custom Color, Size, Speed](#custom-color-size-speed)
  - [Custom Animation Style](#custom-animation-style)
  - [Global Style Configuration](#global-style-configuration)
  - [Fullscreen Mask & Interaction](#fullscreen-mask--interaction)
  - [Animation State Callbacks](#animation-state-callbacks)
  - [List Cell & Popup Adaptation](#list-cell--popup-adaptation)
- [API Reference](#api-reference)
- [Performance Optimization](#performance-optimization)
- [Best Practices](#best-practices)
- [Notes](#notes)
- [License](#license)

## Overview

`FKLoadingAnimator` is designed for production iOS projects and large-scale reusable UI libraries:

- Multiple loading animation styles in one unified API
- Full-screen overlay and embedded loading support
- Determinate progress ring support (`0...1`)
- Main-thread-safe state control (`start`, `stop`, `pause`, `resume`)
- Global template configuration + per-instance override
- Protocol-based custom animator extension (`FKLoadingAnimationProviding`)

The component is zero-intrusive and can be attached to any `UIView`, including pages, list cells, and popup containers.

## Features

- Pure native implementation (`Swift` + `UIKit` + `Foundation` + `CoreAnimation`)
- No Objective-C dependency and no third-party library
- Built-in style switching at runtime
- Full-screen mask mode and embedded mode
- One-line show/hide convenience APIs on `UIView`
- Progress ring support with explicit progress updates
- Fine-grained style customization:
  - primary/secondary/gradient colors
  - line width, ring width, corner radius
  - duration, repeat count, speed
  - particle count and wave amplitude
  - container size and insets
- Optional mask tap to dismiss behavior
- State callback and completion callback
- Works with code initialization and Interface Builder loaded views

## Supported Animation Styles

### Circle / Ring Animations

- `.ring`
- `.gradientRing`
- `.progressRing`

### Wave / Pulse Animations

- `.wave`
- `.rippleWave`
- `.pulseCircle`
- `.pulseSquare`

### Particle Animations

- `.particles`
- `.flowingParticles`
- `.twinkleParticles`

### Classic Spinner

- `.spinner` (enhanced system style)

### Dot / Gear Animations

- `.rotatingDots`
- `.gear`

## High Performance Advantages

- CoreAnimation-driven rendering with lightweight layer trees
- Reuse of animator layers and associated host views to reduce allocation churn
- `CAReplicatorLayer` usage for dot/particle families to minimize sublayer count
- `CAEmitterLayer` for flowing particles with hardware-optimized particle rendering
- Determinate progress updates with implicit animation disabled (`CATransaction.setDisableActions(true)`)
- Avoids unnecessary redraw loops and avoids third-party runtime overhead
- Designed for high-frequency scenes such as `UITableViewCell` / `UICollectionViewCell`

## Requirements

- Swift `5.9+`
- iOS `13.0+` for this component API surface
- `UIKit`
- `Foundation`
- `QuartzCore` / CoreAnimation

## Installation

### Option 1: Swift Package Manager (Recommended)

Add FKKit to your project, then import:

```swift
import FKUIKit
```

### Option 2: Source Integration

Copy `Sources/FKUIKit/Components/LoadingAnimator` into your project and include the files in your app target.

## Basic Usage

### Show Fullscreen Loading

```swift
import UIKit
import FKUIKit

view.fk_showLoadingAnimator { config in
  config.presentationMode = .fullScreen
  config.style = .gradientRing
  config.maskColor = .black
  config.maskAlpha = 0.28
}
```

### Add Embedded Loading to View

```swift
import UIKit
import FKUIKit

cardView.fk_showLoadingAnimator { config in
  config.presentationMode = .embedded
  config.style = .wave
  config.size = CGSize(width: 80, height: 80)
}
```

### Start / Stop Animation

```swift
view.fk_showLoadingAnimator()
view.fk_pauseLoadingAnimation()
view.fk_resumeLoadingAnimation()
view.fk_stopLoadingAnimation()
view.fk_hideLoadingAnimator(animated: true)
```

### Progress Ring Animation

```swift
import UIKit
import FKUIKit

view.fk_showLoadingAnimator { config in
  config.style = .progressRing
  config.presentationMode = .embedded
}

view.fk_updateLoadingProgress(0.0)
view.fk_updateLoadingProgress(0.35)
view.fk_updateLoadingProgress(0.72)
view.fk_updateLoadingProgress(1.0)
```

## Advanced Usage

### Custom Color, Size, Speed

```swift
view.fk_showLoadingAnimator { config in
  config.style = .particles
  config.size = CGSize(width: 96, height: 96)
  config.backgroundColor = .secondarySystemBackground
  config.animationInset = .init(top: 10, left: 10, bottom: 10, right: 10)

  config.styleConfiguration.primaryColor = .systemOrange
  config.styleConfiguration.secondaryColor = .systemPink
  config.styleConfiguration.gradientColors = [.systemOrange, .systemPink, .systemPurple]
  config.styleConfiguration.duration = 0.9
  config.styleConfiguration.speed = 1.2
  config.styleConfiguration.lineWidth = 3
  config.styleConfiguration.ringWidth = 5
  config.styleConfiguration.particleCount = 12
  config.styleConfiguration.waveAmplitude = 10
}
```

### Custom Animation Style

```swift
import UIKit
import QuartzCore
import FKUIKit

final class MyBarLoadingAnimator: FKLoadingBaseAnimator {
  private let bar = CAShapeLayer()

  override func configure(style: FKLoadingAnimatorStyleConfiguration, bounds: CGRect) {
    super.configure(style: style, bounds: bounds)
    bar.frame = bounds
    bar.fillColor = style.primaryColor.cgColor
    bar.path = UIBezierPath(roundedRect: CGRect(x: bounds.midX - 6, y: bounds.midY - 20, width: 12, height: 40), cornerRadius: 6).cgPath
    if bar.superlayer == nil {
      renderLayer.addSublayer(bar)
    }
  }

  override func start() {
    stop()
    let anim = CABasicAnimation(keyPath: "transform.scale.y")
    anim.fromValue = 0.4
    anim.toValue = 1.0
    anim.autoreverses = true
    anim.repeatCount = style.repeatCount
    anim.duration = style.duration
    bar.add(anim, forKey: "bar.scale")
  }
}

let customAnimator = MyBarLoadingAnimator()
view.fk_showLoadingAnimator { config in
  config.style = .custom(customAnimator)
}
```

### Global Style Configuration

```swift
import FKUIKit

FKLoadingAnimatorManager.shared.configureTemplate { config in
  config.style = .ring
  config.size = CGSize(width: 72, height: 72)
  config.presentationMode = .embedded
  config.styleConfiguration.primaryColor = .systemBlue
  config.styleConfiguration.duration = 1.1
}

// Use the shared template directly
view.fk_showLoadingAnimator()
```

### Fullscreen Mask & Interaction

```swift
view.fk_showLoadingAnimator { config in
  config.presentationMode = .fullScreen
  config.style = .spinner
  config.maskColor = .black
  config.maskAlpha = 0.35
  config.allowsMaskTapToStop = true
}
```

### Animation State Callbacks

```swift
view.fk_showLoadingAnimator { config in
  config.style = .rotatingDots
  config.stateDidChange = { state in
    print("loading state:", state)
  }
  config.completion = {
    print("loading stopped")
  }
}
```

### List Cell & Popup Adaptation

```swift
// UITableViewCell / UICollectionViewCell
cell.contentView.fk_showLoadingAnimator { config in
  config.presentationMode = .embedded
  config.style = .pulseCircle
  config.size = CGSize(width: 44, height: 44)
}

// In prepareForReuse()
cell.contentView.fk_hideLoadingAnimator(animated: false)

// Popup container
popupContainerView.fk_showLoadingAnimator { config in
  config.presentationMode = .embedded
  config.style = .gear
}
```

## API Reference

Core public types:

- `FKLoadingAnimatorView`
- `FKLoadingAnimatorConfiguration`
- `FKLoadingAnimatorStyle`
- `FKLoadingAnimatorStyleConfiguration`
- `FKLoadingAnimatorPresentationMode`
- `FKLoadingAnimatorState`
- `FKLoadingAnimatorManager`
- `FKLoadingAnimationProviding`

`UIView` convenience APIs:

- `fk_showLoadingAnimator(configuration:configure:)`
- `fk_hideLoadingAnimator(animated:)`
- `fk_switchLoadingStyle(_:autoRestart:)`
- `fk_updateLoadingProgress(_:)`
- `fk_startLoadingAnimation()`
- `fk_stopLoadingAnimation()`
- `fk_pauseLoadingAnimation()`
- `fk_resumeLoadingAnimation()`
- `fk_loadingAnimatorView`

`FKLoadingAnimatorView` control APIs:

- `apply(_:restart:)`
- `start()`
- `stop()`
- `pause()`
- `resume()`
- `setProgress(_:)`
- `switchStyle(_:autoRestart:)`
- `state`
- `configuration`
- `progress`

## Performance Optimization

`FKLoadingAnimator` is tuned for commercial iOS apps and high-throughput UI scenes:

- Reuses host views via associated objects instead of creating/destroying views repeatedly
- Relies on layer animations instead of per-frame `draw(_:)` code paths
- Uses replicator/emitter primitives where appropriate for fewer manual sublayers
- Uses bounded geometry updates and keeps animation timelines concise
- Progress updates disable implicit animations to avoid stutter in frequent updates
- Supports quick style switching without replacing the entire container hierarchy

## Best Practices

- Keep loading UI updates on the main thread (component APIs already enforce this pattern)
- Prefer embedded mode inside reusable list cells and call `fk_hideLoadingAnimator(animated: false)` in reuse cleanup
- Use global template configuration for consistent product style, then override only screen-specific values
- Use `.progressRing` only for determinate tasks and feed normalized progress (`0...1`)
- Keep `stateDidChange` and `completion` callbacks lightweight; dispatch heavy work asynchronously
- For full-screen loading in complex pages, keep mask alpha moderate (`0.2...0.4`) for better perceived responsiveness

## Notes

- The component itself is designed for iOS `13.0+` APIs.
- If you integrate through FKKit SwiftPM package, follow the package platform settings defined by the root `Package.swift`.
- `fk_loadingAnimatorView` references the embedded host view. Full-screen mode uses an internal overlay view.
- `.custom` style requires an object conforming to `FKLoadingAnimationProviding`.

## License

`FKLoadingAnimator` is part of FKKit and is available under the [MIT License](../../../../LICENSE).
