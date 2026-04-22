# FKExpandableText

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Supported Views](#supported-views)
- [Requirements](#requirements)
- [Installation](#installation)
- [Basic Usage](#basic-usage)
  - [UILabel (Extension API)](#uilabel-extension-api)
  - [UITextView (Extension API)](#uitextview-extension-api)
  - [Factory API](#factory-api)
  - [SwiftUI Usage](#swiftui-usage)
- [Advanced Usage](#advanced-usage)
  - [Custom Configuration](#custom-configuration)
  - [One-way Expand](#one-way-expand)
  - [Full Text Area Interaction](#full-text-area-interaction)
  - [Global Default Configuration](#global-default-configuration)
  - [State Callback](#state-callback)
  - [Accessibility](#accessibility)
- [API Reference](#api-reference)
- [Best Practices](#best-practices)
- [Performance Notes](#performance-notes)
- [Notes](#notes)
- [License](#license)

## Overview
`FKExpandableText` is the README entry name for the `FKExpandableText` component in `FKUIKit`.

`FKExpandableText` is a UIKit/SwiftUI expandable text component for long-form content.  
It supports rich text, configurable truncation behavior, expand/collapse actions, animation styles, and VoiceOver metadata.

This component is suitable for:
- article summary blocks
- user profile introduction
- comment/review previews
- message feed text snippets

## Features
- Pure native Swift + UIKit implementation, no third-party dependency.
- `UILabel` and `UITextView` integration with one-line extension APIs.
- Rich text support via `NSAttributedString`.
- Two collapse strategies: fixed line limit or no body truncation.
- Two button placements: inline tail or trailing bottom line.
- Two interaction modes: button-only or full text area tap.
- Configurable animation: `none`, `curve`, `spring`.
- Optional one-way expand mode.
- Global default configuration and per-instance override.
- SwiftUI bridge with `FKExpandableTextView`.
- Main-actor UI safety for public entry points.

## Supported Views
`FKExpandableText` can be attached to:
- `UILabel`
- `UITextView`
- SwiftUI via `FKExpandableTextView` (`UIViewRepresentable`)

## Requirements
- Swift 5.9+ for component-level usage goals.
- UIKit (and SwiftUI bridge when needed).
- iOS 13+ API compatibility in component implementation.
- Package-level note: this repository currently declares `iOS 15+` in `Package.swift`. If consumed via this package directly, follow package platform settings.

## Installation
Add `FKUIKit` with Swift Package Manager.

### Xcode
1. Open `File` -> `Add Package Dependencies...`
2. Enter:
   - `https://github.com/feng-zhang0712/FKKit.git`
3. Select product:
   - `FKUIKit`

### Package.swift
```swift
dependencies: [
  .package(url: "https://github.com/feng-zhang0712/FKKit.git", from: "0.22.0")
],
targets: [
  .target(
    name: "YourTarget",
    dependencies: [
      .product(name: "FKUIKit", package: "FKKit")
    ]
  )
]
```

## Basic Usage
```swift
import UIKit
import FKUIKit
```

### UILabel (Extension API)
```swift
let label = UILabel()
label.numberOfLines = 0

label.fk_setExpandableText(
  "A very long text content...",
  onStateChanged: { state in
    print("Label state: \(state)")
  }
)
```

### UITextView (Extension API)
```swift
let textView = UITextView()
textView.backgroundColor = .clear
textView.linkTextAttributes = [
  .foregroundColor: UIColor.systemBlue,
  .underlineStyle: NSUnderlineStyle.single.rawValue
]

let text = NSAttributedString(string: "Long content with a link: https://www.fkkit.com")
textView.fk_setExpandableText(
  text,
  onStateChanged: { state in
    print("TextView state: \(state)")
  },
  onLinkTapped: { url in
    print("Link tapped: \(url)")
  }
)
```

### Factory API
```swift
let labelController = FKExpandableText.apply(
  to: label,
  text: NSAttributedString(string: "Long text...")
)

let textViewController = FKExpandableText.apply(
  to: textView,
  text: NSAttributedString(string: "Another long text...")
)
```

### SwiftUI Usage
```swift
import SwiftUI
import FKUIKit

struct DemoView: View {
  @State private var isExpanded = false

  var body: some View {
    FKExpandableTextView(
      text: NSAttributedString(string: "Long SwiftUI text..."),
      isExpanded: $isExpanded,
      onStateChanged: { state in
        print("SwiftUI state: \(state)")
      }
    )
    .padding()
  }
}
```

## Advanced Usage
### Custom Configuration
```swift
let configuration = FKExpandableTextConfiguration(
  truncationToken: NSAttributedString(string: "... "),
  expandActionText: NSAttributedString(
    string: "Read more",
    attributes: [
      .foregroundColor: UIColor.systemRed,
      .font: UIFont.systemFont(ofSize: 16, weight: .bold)
    ]
  ),
  collapseActionText: NSAttributedString(
    string: "Collapse",
    attributes: [
      .foregroundColor: UIColor.systemGreen,
      .font: UIFont.systemFont(ofSize: 16, weight: .semibold)
    ]
  ),
  collapseRule: .lines(3),
  buttonPlacement: .inlineTail,
  interactionMode: .buttonOnly,
  oneWayExpand: false,
  animation: .curve(duration: 0.25, options: [.curveEaseInOut])
)

label.fk_setExpandableText(
  NSAttributedString(string: "Custom long content..."),
  configuration: configuration
)
```

### One-way Expand
```swift
let configuration = FKExpandableTextConfiguration(oneWayExpand: true)
label.fk_setExpandableText("Expand only mode text...", configuration: configuration)
```

### Full Text Area Interaction
```swift
let configuration = FKExpandableTextConfiguration(interactionMode: .fullTextArea)
label.fk_setExpandableText("Tap anywhere to toggle...", configuration: configuration)
```

### Global Default Configuration
```swift
FKExpandableTextGlobalConfiguration.shared = FKExpandableTextConfiguration(
  collapseRule: .lines(2),
  buttonPlacement: .trailingBottom
)

// Use defaults directly
label.fk_setExpandableText("Uses global defaults")
```

### State Callback
```swift
label.fk_setExpandableText(
  "Long content...",
  onStateChanged: { state in
    switch state {
    case .collapsed:
      print("collapsed")
    case .expanded:
      print("expanded")
    }
  }
)
```

### Accessibility
```swift
let config = FKExpandableTextConfiguration(
  accessibility: .init(
    expandLabel: "Expand article",
    collapseLabel: "Collapse article",
    hint: "Double tap to toggle."
  )
)
label.fk_setExpandableText("Accessible long text...", configuration: config)
```

## API Reference
Core types:
- `FKExpandableText`
- `FKExpandableTextConfiguration`
- `FKExpandableTextGlobalConfiguration`
- `FKExpandableTextState`
- `FKExpandableTextLabelController`
- `FKExpandableTextTextViewController`
- `FKExpandableTextView` (SwiftUI)

Main APIs:
- `FKExpandableText.apply(to:text:configuration:onStateChanged:)`
- `UILabel.fk_setExpandableText(_:configuration:onStateChanged:)`
- `UILabel.fk_setExpandableText(_:attributes:configuration:onStateChanged:)`
- `UITextView.fk_setExpandableText(_:configuration:onStateChanged:onLinkTapped:)`
- `UITextView.fk_setExpandableText(_:attributes:configuration:onStateChanged:onLinkTapped:)`
- `FKExpandableTextView.init(text:configuration:isExpanded:onStateChanged:onLinkTapped:)`

## Best Practices
- Set a deterministic width before first render (Auto Layout constraints first, then assign text).
- Prefer `NSAttributedString` for mixed styles and links.
- Use `.lines(n)` for feed-like previews; use `.noBodyTruncation` when only action control is needed.
- Keep action text short (`Read more` / `Collapse`) to reduce wrapping uncertainty.
- In list cells, avoid rebuilding attributed text repeatedly; update only when content changes.
- Capture `self` weakly in callbacks.

## Performance Notes
- Internal collapsed-text building uses layout measurement and cache for repeated layouts.
- Keep attributed text payload reasonably small for high-frequency list updates.
- If content changes often, debounce model updates before calling `fk_setExpandableText`.

## Notes
- Public UI entry points are main-actor oriented.
- If text is shorter than the collapse rule, the component renders original text without toggle action.
- `UITextView` integration can intercept toggle link (`fkexpand://toggle`) while preserving custom link callbacks.

## License
This module is part of the FKKit project and is released under the MIT License.  
See the root [LICENSE](../../../../LICENSE) file for details.

