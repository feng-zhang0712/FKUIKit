# FKMultiPicker

`FKMultiPicker` is a pure native Swift cascading picker built on `UIKit` and `Foundation` only.  
It is designed for production iOS projects and open-source libraries that need multi-level linkage selection with clean APIs and customizable UI.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Supported Levels](#supported-levels)
- [Built-in Data Sources](#built-in-data-sources)
- [Requirements](#requirements)
- [Installation](#installation)
- [Basic Usage](#basic-usage)
- [Advanced Usage](#advanced-usage)
- [API Reference](#api-reference)
- [Data Model Protocol](#data-model-protocol)
- [Best Practices](#best-practices)
- [Performance Optimization](#performance-optimization)
- [Notes](#notes)
- [License](#license)

## Overview

`FKMultiPicker` provides bottom-sheet style linked selection for 1 to N levels (commonly 2/3/4/5).  
When a value changes at one level, downstream levels are recalculated and refreshed automatically. The component supports:

- built-in region hierarchy data (Province-City-District-Street),
- custom business tree data,
- protocol-driven data source and delegate callbacks,
- global defaults plus per-instance configuration overrides.

## Features

- Pure Swift 5.9+ implementation, iOS 13+, no third-party dependencies.
- Unlimited tree depth support, with configurable visible component count.
- Smooth linkage logic: selecting upper levels refreshes lower levels instantly.
- Bottom sheet presentation with mask tap dismissal and toolbar actions.
- Configurable title/cancel/confirm toolbar and separator visibility.
- Configurable row text color, selected color, fonts, and row height.
- Configurable container background, corner radius, shadow, and mask color.
- Configurable popup size and animation duration.
- Supports default selections by node `id` or `title`.
- Supports callbacks via closures and delegate protocol.
- Supports code and Interface Builder initialization.

## Supported Levels

`FKMultiPicker` works with hierarchical trees of any depth.

- **Recommended production range:** 1 to 5 visible levels (`componentCount`).
- **Unlimited depth support:** the data model can be deeper; you control how many components are shown at once.
- **Typical scenarios:** category/subcategory, organization tree, address selection, SKU attributes.

## Built-in Data Sources

### Province-City-District-Street 4 Levels

Use the built-in region tree through:

- `FKMultiPickerBuiltInRegionDataProvider`
- `FKMultiPickerBuiltInRegionDataProvider.standardRegionNodes`
- `FKMultiPicker.presentRegionPicker(...)`

This built-in data is lightweight and intended as a ready-to-use default plus extension template.

### Custom Business Data

You can provide data in two ways:

1. **Static tree nodes** (`[FKMultiPickerNode]`)
2. **Protocol-based provider** (`FKMultiPickerDataProviding`) for dynamic/lazy loading logic

## Requirements

- iOS 13.0+
- Swift 5.9+
- Xcode 15+
- UIKit/Foundation only

## Installation

### Swift Package Manager

Add this repository to your `Package.swift` or Xcode package dependencies.

```swift
dependencies: [
  .package(url: "https://github.com/your-org/FKKit.git", from: "1.0.0")
]
```

Then add `FKUIKit` to your target dependencies.

```swift
.target(
  name: "YourTarget",
  dependencies: [
    .product(name: "FKUIKit", package: "FKKit")
  ]
)
```

## Basic Usage

### 2/3/4 Levels Linkage Picker

```swift
let nodes: [FKMultiPickerNode] = [
  FKMultiPickerNode(
    id: "electronics",
    title: "Electronics",
    children: [
      FKMultiPickerNode(
        id: "phones",
        title: "Phones",
        children: [
          FKMultiPickerNode(id: "ios", title: "iOS"),
          FKMultiPickerNode(id: "android", title: "Android")
        ]
      )
    ]
  )
]

var config = FKMultiPickerConfiguration(componentCount: 3)
FKMultiPicker.present(in: view, nodes: nodes, configuration: config) { result in
  print(result.joinedTitle)
}
```

### Province-City-District Picker

```swift
var config = FKMultiPickerConfiguration(componentCount: 3)
config.toolbarStyle.title = "Select Region"

FKMultiPicker.presentRegionPicker(in: view, configuration: config) { result in
  let titles = result.items.map { $0.node.title }
  let province = titles.count > 0 ? titles[0] : ""
  let city = titles.count > 1 ? titles[1] : ""
  let district = titles.count > 2 ? titles[2] : ""
  print(province, city, district)
}
```

### Custom Data Linkage Picker

```swift
@MainActor
final class CategoryProvider: FKMultiPickerDataProviding {
  func rootNodes() -> [FKMultiPickerNode] {
    [
      FKMultiPickerNode(id: "a", title: "Category A"),
      FKMultiPickerNode(id: "b", title: "Category B")
    ]
  }

  func children(of node: FKMultiPickerNode, atLevel level: Int) -> [FKMultiPickerNode] {
    switch (node.id, level) {
    case ("a", 0): return [FKMultiPickerNode(id: "a-1", title: "A-1")]
    case ("a-1", 1): return [FKMultiPickerNode(id: "a-1-i", title: "A-1-I")]
    case ("b", 0): return [FKMultiPickerNode(id: "b-1", title: "B-1")]
    default: return []
    }
  }
}

let provider = CategoryProvider()
FKMultiPicker.present(in: view, provider: provider) { result in
  print(result.items.map { $0.node.id })
}
```

### Show/Hide Picker

```swift
let picker = FKMultiPicker(configuration: FKMultiPickerConfiguration(componentCount: 4))
picker.updateNodes(FKMultiPickerBuiltInRegionDataProvider.standardRegionNodes)
picker.show(in: view)

// Hide manually
picker.dismiss()
```

## Advanced Usage

### Custom UI Style (Color/Font/Height)

```swift
var config = FKMultiPickerConfiguration(componentCount: 4)
config.rowStyle.textColor = .darkGray
config.rowStyle.selectedTextColor = .systemRed
config.rowStyle.font = .systemFont(ofSize: 15, weight: .regular)
config.rowStyle.selectedFont = .systemFont(ofSize: 17, weight: .bold)
config.rowStyle.rowHeight = 44

config.toolbarStyle.title = "Choose Address"
config.toolbarStyle.titleColor = .label
config.toolbarStyle.confirmTitleColor = .systemGreen
config.toolbarStyle.showsSeparator = true
```

### Custom Popup Animation & Size

```swift
var config = FKMultiPickerConfiguration(componentCount: 4)
config.presentationStyle = .custom(height: 380)
config.pickerHeight = 280
config.toolbarHeight = 56
config.animationDuration = 0.35
config.dismissOnMaskTap = true
```

### Default Selected Item Setup

`defaultSelectionKeys` supports matching by node `id` first, then by `title`.

```swift
var config = FKMultiPickerConfiguration(componentCount: 4)
config.defaultSelectionKeys = ["440000", "440300", "440305", "440305002"]
FKMultiPicker.presentRegionPicker(in: view, configuration: config, onConfirmed: nil)
```

### Global Style Configuration

```swift
FKMultiPickerManager.shared.defaultConfiguration = {
  var config = FKMultiPickerConfiguration()
  config.componentCount = 4
  config.toolbarStyle.title = "Global Picker"
  config.containerStyle.cornerRadius = 20
  return config
}()
```

### Callback Events (Confirm/Cancel/Change)

```swift
let picker = FKMultiPicker(configuration: FKMultiPickerConfiguration(componentCount: 3))
picker.updateNodes(FKMultiPickerBuiltInRegionDataProvider.standardRegionNodes)

picker.onSelectionChanged = { result in
  print("changed:", result.joinedTitle)
}
picker.onConfirmed = { result in
  print("confirmed:", result.items)
}
picker.onCancelled = {
  print("cancelled")
}

picker.show(in: view)
```

Delegate style:

```swift
final class ViewController: UIViewController, FKMultiPickerDelegate {
  func multiPickerDidCancel(_ picker: FKMultiPicker) {}

  func multiPicker(_ picker: FKMultiPicker, didChange result: FKMultiPickerSelectionResult) {}

  func multiPicker(_ picker: FKMultiPicker, didConfirm result: FKMultiPickerSelectionResult) {}
}
```

### Dynamic Data Refresh

```swift
let picker = FKMultiPicker(configuration: FKMultiPickerConfiguration(componentCount: 4))
picker.bindDataProvider(FKMultiPickerBuiltInRegionDataProvider())
picker.show(in: view)

// Data changed from business layer
picker.reloadData()

// Replace root nodes directly
picker.updateNodes(newNodes)

// Reset to first option in each active level
picker.resetSelection(animated: true)
```

## API Reference

Core type:

- `FKMultiPicker`

Main methods:

- `init(configuration:)`
- `configure(_:)`
- `show(in:)`
- `dismiss(completion:)`
- `reloadData()`
- `updateNodes(_:)`
- `bindDataProvider(_:)`
- `resetSelection(animated:)`
- `present(in:nodes:configuration:onConfirmed:)`
- `present(in:provider:configuration:onConfirmed:)`
- `presentRegionPicker(in:configuration:onConfirmed:)`

Main callbacks:

- `onSelectionChanged`
- `onConfirmed`
- `onCancelled`

Main protocols:

- `FKMultiPickerDataSource`
- `FKMultiPickerDelegate`
- `FKMultiPickerDataProviding`

## Data Model Protocol

### Node Model

`FKMultiPickerNode` is the base tree model:

- `id`: stable identifier for restore/diff/business mapping
- `title`: row display title
- `children`: next-level nodes

### Selection Model

- `FKMultiPickerSelectionItem` (`level`, `row`, `node`)
- `FKMultiPickerSelectionResult` (`items`, `joinedTitle`)

### Data Protocols

- `FKMultiPickerDataSource`: picker-oriented source (`rootNodes`, `childrenOf`)
- `FKMultiPickerDataProviding`: provider-oriented source (`rootNodes`, `children`)
- `FKMultiPickerDelegate`: lifecycle and interaction callbacks

## Best Practices

- Use `id` as stable business key and keep it unique at each level.
- Keep node titles user-friendly; avoid exposing raw backend codes directly.
- Prefer provider protocol for frequently changing or large datasets.
- Set `componentCount` to the minimal practical level count for better UX.
- Use `defaultSelectionKeys` to restore user context in edit flows.
- Centralize common style through `FKMultiPickerManager.shared.defaultConfiguration`.

## Performance Optimization

- Linkage is incremental: only downstream levels are rebuilt after selection changes.
- Tree-based data avoids expensive flattening operations.
- For large data:
  - load children lazily in `children(of:atLevel:)`,
  - avoid heavy work in callbacks,
  - keep UI updates on main thread only.
- Use `reloadData()` when source changes, instead of recreating picker each time.
- Reuse one picker instance in repeated flows when suitable.

## Notes

- `FKMultiPicker` is `@MainActor`; call UI APIs from the main thread.
- The component supports code and XIB/Storyboard initialization.
- Built-in region data is a practical starter set and can be replaced by your domain data.
- Current presentation animation is fade + bottom slide with configurable duration.
- If you need custom row rendering, extend `UIPickerViewDelegate` behavior in your fork or wrapper.

## License

This component follows the same license as the FKKit repository.  
Please check the root `LICENSE` file for details.
