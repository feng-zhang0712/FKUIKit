# FKBlurView

[![iOS](https://img.shields.io/badge/iOS-13.0%2B-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange.svg)](https://swift.org)
[![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![CocoaPods](https://img.shields.io/badge/CocoaPods-supported-red.svg)](https://cocoapods.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-lightgrey.svg)](LICENSE)

High-performance blur view for iOS (UIKit + SwiftUI), with both **system hardware blur** and **fully custom Core Image blur parameters**.

## Table of Contents

- [Why](#why)
- [Overview](#overview)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
  - [Swift Package Manager](#swift-package-manager)
  - [CocoaPods](#cocoapods)
- [Usage](#usage)
  - [Quick Start](#quick-start)
  - [System Blur Styles](#system-blur-styles)
  - [Custom Blur Parameters](#custom-blur-parameters)
  - [Static vs Dynamic Blur](#static-vs-dynamic-blur)
  - [Image Blur](#image-blur)
  - [Custom Mask](#custom-mask)
  - [Global Configuration](#global-configuration)
  - [Interface Builder Usage](#interface-builder-usage)
  - [SwiftUI Support](#swiftui-support)
- [API Reference](#api-reference)
- [License](#license)

## Why

Apple’s `UIVisualEffectView` is great for **system materials**, but it has two common limitations in real-world apps:

- You can’t precisely control blur parameters (radius, saturation, brightness, tint overlay).
- “Custom” blur effects often end up as expensive snapshots and filters that stutter during scrolling or animations.

`FKBlurView` exists to offer a single blur component that:

- Keeps **system blur** as a first-class, **hardware-accelerated** option (best for dynamic content).
- Adds a **custom, type-safe configuration** pipeline when you need full control over blur appearance.

## Overview

`FKBlurView` is a drop-in blur view for iOS 13+ that supports:

- **System blur styles** (all built-in materials/styles) for maximum performance.
- **Custom Core Image blur** with adjustable parameters and an optional dynamic refresh loop.
- **UIKit & SwiftUI** integration using the same configuration model (`FKBlurConfiguration`).

## Features

- **System blur styles**: all `UIBlurEffect.Style` materials (light/dark/material variants).
- **Fully custom blur parameters**: radius, saturation, brightness, tint color + tint opacity.
- **Static & dynamic modes**:
  - **Static**: blur once, reuse forever (best for static backgrounds).
  - **Dynamic**: refresh while content changes (scroll/animations).
- **Image blur**: blur any `UIImage` without a view.
- **Custom mask**: blur region can be clipped to rounded rect / circle / arbitrary path.
- **Opacity control**: adjust overall blur transparency.
- **Interface Builder support**: `@IBDesignable` + `@IBInspectable` properties.
- **Global defaults**: set app-wide baseline configuration and override per view.
- **Automatic adaptation**: works with Auto Layout, rotation, and light/dark mode.
- **Thread-safe configuration updates**: setting `configuration` from any thread dispatches UI work to the main thread.

## Requirements

- iOS **13.0+**
- Swift **5.9+**
- Xcode **14+**

## Installation

### Swift Package Manager

Add FKKit to your project (recommended). In Xcode:

1. **File → Add Packages…**
2. Enter your repository URL
3. Select the package product that includes `FKUIKit`

Or add it directly to `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/<your-org-or-user>/FKKit.git", from: "1.0.0")
]
```

Then add `FKUIKit` to your target dependencies:

```swift
.target(
  name: "YourApp",
  dependencies: [
    .product(name: "FKUIKit", package: "FKKit")
  ]
)
```

### CocoaPods

Add to your `Podfile`:

```ruby
platform :ios, '13.0'
use_frameworks!

target 'YourApp' do
  pod 'FKKit'
end
```

Then run:

```bash
pod install
```

> Note: CocoaPods spec/name may vary depending on how you publish FKKit. Update `pod 'FKKit'` accordingly.

## Usage

### Quick Start

One line to create a blur view (system material, dynamic):

```swift
let blurView = FKBlurView()
```

Add it to your hierarchy and constrain it like any other `UIView`.

### System Blur Styles

Use hardware-accelerated system materials for best dynamic performance:

```swift
var config = FKBlurConfiguration(
  backend: .system(style: .systemMaterial)
)

let blurView = FKBlurView()
blurView.configuration = config
```

Examples:

```swift
blurView.configuration = FKBlurConfiguration(backend: .system(style: .light))
blurView.configuration = FKBlurConfiguration(backend: .system(style: .dark))
blurView.configuration = FKBlurConfiguration(backend: .system(style: .systemUltraThinMaterial))
```

### Custom Blur Parameters

Use Core Image when you need full control over appearance:

```swift
let params = FKBlurConfiguration.CustomParameters(
  blurRadius: 18,
  saturation: 1.2,
  brightness: 0.05,
  tintColor: UIColor.systemBlue,
  tintOpacity: 0.12
)

let config = FKBlurConfiguration(
  backend: .custom(parameters: params),
  opacity: 1.0,
  downsampleFactor: 4
)

let blurView = FKBlurView()
blurView.configuration = config
```

### Static vs Dynamic Blur

Static blur (blur once, maximum performance):

```swift
blurView.configuration = FKBlurConfiguration(
  mode: .static,
  backend: .custom(parameters: .init(blurRadius: 24)),
  downsampleFactor: 4
)
```

Dynamic blur (refresh while content changes):

```swift
blurView.configuration = FKBlurConfiguration(
  mode: .dynamic,
  backend: .custom(parameters: .init(blurRadius: 16)),
  downsampleFactor: 4,
  preferredFramesPerSecond: 60
)
```

For **scrolling/animations**, prefer:

```swift
blurView.configuration = FKBlurConfiguration(backend: .system(style: .systemMaterial))
```

### Image Blur

Blur any `UIImage` without using a view:

```swift
let params = FKBlurConfiguration.CustomParameters(
  blurRadius: 20,
  saturation: 1.0,
  brightness: 0.0,
  tintColor: nil,
  tintOpacity: 0.0
)

let blurred = image.fk_blurred(parameters: params, downsampleFactor: 2)
```

### Custom Mask

Rounded corners:

```swift
blurView.maskedCornerRadius = 16
```

Circle:

```swift
blurView.maskPath = UIBezierPath(ovalIn: blurView.bounds)
```

Arbitrary shape:

```swift
let path = UIBezierPath()
path.move(to: CGPoint(x: 0, y: 0))
path.addLine(to: CGPoint(x: 120, y: 0))
path.addLine(to: CGPoint(x: 120, y: 80))
path.close()
blurView.maskPath = path
```

> Tip: if you set `maskPath`, update it in `layoutSubviews` (or after layout) so it matches the final `bounds`.

### Global Configuration

Set app-wide defaults (e.g. at app launch), then override per view when needed:

```swift
FKBlurGlobalDefaults.configuration = FKBlurConfiguration(
  backend: .system(style: .systemMaterial),
  opacity: 1.0
)
```

New instances use the global default as the baseline:

```swift
let blurView = FKBlurView() // uses FKBlurGlobalDefaults.configuration
```

### Interface Builder Usage

`FKBlurView` is `@IBDesignable` and exposes key properties as `@IBInspectable`:

- Backend selector (`ibBackend`): 0 = system, 1 = custom
- Mode (`ibMode`): 0 = static, 1 = dynamic
- System style index (`ibSystemStyleIndex`)
- Custom parameters: radius/saturation/brightness/tint/tintOpacity
- Opacity (`ibOpacity`)
- Downsample factor (`ibDownsampleFactor`)
- Mask corner radius (`maskedCornerRadius`)

Drag a `UIView` into your XIB/Storyboard, set its class to `FKBlurView`, and tune the inspectables.

### SwiftUI Support

Use `FKSwiftUIBlurView`:

```swift
import SwiftUI

struct ContentView: View {
  var body: some View {
    ZStack {
      // background content...
      FKSwiftUIBlurView(
        configuration: FKBlurConfiguration(
          backend: .system(style: .systemMaterial)
        )
      )
    }
  }
}
```

## API Reference

### `FKBlurView` (UIKit)

- `var configuration: FKBlurConfiguration`
  - Set from any thread; UI updates are applied on the main thread.
- `weak var blurSourceView: UIView?`
  - Snapshot source for the `.custom` backend. Defaults to `superview`.
- `var maskPath: UIBezierPath?`
  - Optional shape mask for the blur content.
- `var maskedCornerRadius: CGFloat`
  - Convenience rounded-rect mask using current `bounds`.

### `FKBlurConfiguration`

- `mode: FKBlurConfiguration.Mode`
  - `.static` or `.dynamic`
- `backend: FKBlurConfiguration.Backend`
  - `.system(style:)` or `.custom(parameters:)`
- `opacity: CGFloat`
  - Overall view opacity (0...1)
- `downsampleFactor: CGFloat`
  - Performance knob for `.custom` backend (>= 1)
- `preferredFramesPerSecond: Int`
  - Dynamic refresh rate for `.custom` backend

### `UIImage` Blur Extension

- `func fk_blurred(parameters:downsampleFactor:context:) -> UIImage?`
  - Returns a Core Image blurred image (Metal-accelerated when available).

## License

MIT License

Copyright (c) 2026

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

