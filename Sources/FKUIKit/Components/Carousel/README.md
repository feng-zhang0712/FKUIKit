# FKCarousel

`FKCarousel` is a high-performance, infinitely looping carousel component for UIKit apps.
It is written in pure Swift and built only on Apple system frameworks (`UIKit`, `Foundation`, `CoreAnimation`) with zero third-party dependencies.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Supported Content Types](#supported-content-types)
  - [Local Images](#local-images)
  - [Network Images](#network-images)
  - [Custom Views](#custom-views)
- [Core Capabilities](#core-capabilities)
  - [Infinite Loop Scrolling](#infinite-loop-scrolling)
  - [Auto Carousel & Manual Swipe](#auto-carousel--manual-swipe)
  - [Horizontal/Vertical Scrolling](#horizontalvertical-scrolling)
  - [Custom PageControl](#custom-pagecontrol)
- [Requirements](#requirements)
- [Installation](#installation)
- [Basic Usage](#basic-usage)
  - [Create Carousel with Code](#create-carousel-with-code)
  - [Create Carousel with XIB/Storyboard](#create-carousel-with-xibstoryboard)
  - [Local Image Carousel](#local-image-carousel)
  - [Network Image Carousel](#network-image-carousel)
  - [Custom View Carousel](#custom-view-carousel)
- [Advanced Usage](#advanced-usage)
  - [Custom Auto Scroll Time & Direction](#custom-auto-scroll-time--direction)
  - [PageControl Customization (Color/Size/Position)](#pagecontrol-customization-colorsizeposition)
  - [Disable Infinite Loop & Auto Scroll](#disable-infinite-loop--auto-scroll)
  - [Global Style Configuration](#global-style-configuration)
  - [Click & Scroll Callback Events](#click--scroll-callback-events)
  - [Dynamic Update Carousel Data](#dynamic-update-carousel-data)
  - [Single Item Adaptation](#single-item-adaptation)
- [API Reference](#api-reference)
- [Performance Optimization](#performance-optimization)
- [Best Practices](#best-practices)
- [Notes](#notes)
- [License](#license)

## Overview

`FKCarousel` is designed for production iOS projects that require:

- truly infinite scrolling without visible boundary jumps
- smooth auto-play and manual paging interactions
- reusable architecture for banners, ads, cards, and mixed custom content
- a lightweight API with global defaults and per-instance customization

It uses `UICollectionView` with cell reuse for memory efficiency and consistent performance in list, feed, and fullscreen scenarios.

## Features

- Pure native implementation, no Objective-C dependency, no third-party library
- Swift 5.9+ compatible
- iOS 13+ compatible
- Infinite loop scrolling with virtual index recentering
- Auto carousel with drag-aware pause/resume behavior
- Manual swipe paging with horizontal or vertical direction
- Built-in customizable page control
- Supports local image, remote image, and custom view content
- Supports single-item adaptation (auto-scroll and paging disabled)
- Supports global default configuration and per-carousel overrides
- Supports callback events for tap and page change

## Supported Content Types

### Local Images

Use `FKCarouselItem.image(UIImage)` for assets bundled in app or generated images.

### Network Images

Use `FKCarouselItem.url(URL)` for remote images.
The built-in loader uses `URLSession` + `NSCache` and supports placeholder/failure images.

### Custom Views

Use:

- `FKCarouselItem.customView(UIView)` for simple non-loop or lightweight scenarios
- `FKCarouselItem.customViewProvider(() -> UIView)` for infinite-loop safe rendering (recommended)

## Core Capabilities

### Infinite Loop Scrolling

`FKCarousel` achieves seamless infinite scrolling by:

- creating a large virtual item space (`realCount * multiplier`)
- mapping every virtual index back to logical data index using modulo
- recentering to the middle virtual region when user approaches virtual edges

This avoids first/last item flicker and removes boundary stalls.

### Auto Carousel & Manual Swipe

- Auto-play interval is configurable via `autoScrollInterval`
- Auto-play pauses when user starts dragging
- Auto-play resumes after drag/deceleration completes
- You can also manually `startAutoScroll()`, `pauseAutoScroll()`, `resumeAutoScroll()`, `stopAutoScroll()`

### Horizontal/Vertical Scrolling

Choose direction via:

- `.horizontal`
- `.vertical`

### Custom PageControl

Built-in page control supports:

- bottom alignment: left / center / right
- custom normal/selected colors
- custom normal/selected dot sizes
- optional custom normal/selected dot images
- custom spacing and insets

## Requirements

- iOS 13.0+
- Swift 5.9+
- Xcode 15+

## Installation

Add the `Carousel` directory under:

`Sources/FKUIKit/Components/Carousel`

to your UIKit module target (or keep it in FKKit if you already use the repository as a package/module).

No external dependency is required.

## Basic Usage

### Create Carousel with Code

```swift
import UIKit

let carousel = FKCarousel()
carousel.translatesAutoresizingMaskIntoConstraints = false
view.addSubview(carousel)

NSLayoutConstraint.activate([
  carousel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
  carousel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
  carousel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
  carousel.heightAnchor.constraint(equalToConstant: 180),
])

carousel.apply(configuration: FKCarouselConfiguration())
carousel.reload(items: [
  .image(UIImage(named: "banner_1")!),
  .image(UIImage(named: "banner_2")!),
  .image(UIImage(named: "banner_3")!)
])
```

### Create Carousel with XIB/Storyboard

1. Drag a `UIView` into your layout.
2. Set its custom class to `FKCarousel`.
3. Connect an outlet and configure in code:

```swift
@IBOutlet private weak var carousel: FKCarousel!

override func viewDidLoad() {
  super.viewDidLoad()
  carousel.apply(configuration: FKCarouselConfiguration())
  carousel.reload(items: [
    .image(UIImage(named: "banner_a")!),
    .image(UIImage(named: "banner_b")!)
  ])
}
```

### Local Image Carousel

```swift
let items: [FKCarouselItem] = [
  .image(UIImage(named: "local_1")!),
  .image(UIImage(named: "local_2")!),
  .image(UIImage(named: "local_3")!)
]
carousel.reload(items: items)
```

### Network Image Carousel

```swift
var config = FKCarouselConfiguration()
config.placeholderImage = UIImage(named: "placeholder")
config.failureImage = UIImage(named: "load_failed")
carousel.apply(configuration: config)

carousel.reload(items: [
  .url(URL(string: "https://example.com/banner1.jpg")!),
  .url(URL(string: "https://example.com/banner2.jpg")!),
  .url(URL(string: "https://example.com/banner3.jpg")!)
])
```

### Custom View Carousel

```swift
let items: [FKCarouselItem] = [
  .customViewProvider {
    let card = UIView()
    card.backgroundColor = .systemBlue

    let label = UILabel()
    label.text = "Card A"
    label.textColor = .white
    label.font = .boldSystemFont(ofSize: 20)
    label.translatesAutoresizingMaskIntoConstraints = false
    card.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: card.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: card.centerYAnchor),
    ])
    return card
  },
  .customViewProvider {
    let card = UIView()
    card.backgroundColor = .systemGreen
    return card
  }
]

carousel.reload(items: items)
```

## Advanced Usage

### Custom Auto Scroll Time & Direction

```swift
var config = FKCarouselConfiguration()
config.autoScrollInterval = 2.5
config.direction = .vertical
carousel.apply(configuration: config)
```

### PageControl Customization (Color/Size/Position)

```swift
var style = FKCarouselPageControlStyle()
style.normalDotSize = CGSize(width: 6, height: 6)
style.selectedDotSize = CGSize(width: 18, height: 6)
style.normalColor = .lightGray
style.selectedColor = .white
style.spacing = 8

var config = FKCarouselConfiguration()
config.pageControlStyle = style
config.pageControlAlignment = .right
config.pageControlInsets = UIEdgeInsets(top: 0, left: 12, bottom: 10, right: 12)
carousel.apply(configuration: config)
```

### Disable Infinite Loop & Auto Scroll

```swift
var config = FKCarouselConfiguration()
config.isInfiniteEnabled = false
config.isAutoScrollEnabled = false
carousel.apply(configuration: config)
```

### Global Style Configuration

```swift
@MainActor
func setupCarouselTheme() {
  var global = FKCarouselConfiguration()
  global.autoScrollInterval = 4
  global.containerStyle.cornerRadius = 12
  global.containerStyle.contentMode = .scaleAspectFill
  FKCarouselManager.shared.templateConfiguration = global
}
```

All new `FKCarousel()` instances will use this template unless you override with `apply(configuration:)`.

### Click & Scroll Callback Events

```swift
carousel.onItemSelected = { index, item in
  print("Tapped index:", index, "item:", item)
}

carousel.onPageChanged = { index in
  print("Current page:", index)
}
```

### Dynamic Update Carousel Data

```swift
// Replace full data source dynamically on main thread
carousel.reload(items: [
  .image(UIImage(named: "new_1")!),
  .image(UIImage(named: "new_2")!)
])

// Jump to a target page
carousel.scrollToPage(1, animated: true)
```

### Single Item Adaptation

When only one item is provided:

- scrolling is automatically disabled
- page control is hidden
- auto scroll does not start

No extra handling is required.

## API Reference

Main type:

- `FKCarousel`

Primary methods:

- `apply(configuration:)`
- `reload(items:)`
- `scrollToPage(_:animated:)`
- `startAutoScroll()`
- `stopAutoScroll()`
- `pauseAutoScroll()`
- `resumeAutoScroll()`

Callbacks:

- `onItemSelected: ((Int, FKCarouselItem) -> Void)?`
- `onPageChanged: ((Int) -> Void)?`

Configuration:

- `FKCarouselConfiguration`
- `FKCarouselDirection`
- `FKCarouselPageControlAlignment`
- `FKCarouselPageControlStyle`
- `FKCarouselContainerStyle`
- `FKCarouselItem`

Global defaults:

- `FKCarouselManager.shared.templateConfiguration`

Convenience embedding:

- `UIView.fk_addCarousel(items:configuration:configure:)`

## Performance Optimization

`FKCarousel` is optimized for smooth rendering and memory efficiency:

- `UICollectionView` paging + cell reuse
- lightweight virtual-index infinite loop (no heavy data duplication)
- image loading with memory cache (`NSCache`)
- drag-aware timer control to reduce unnecessary animation work
- safe recentering strategy to keep content offset stable in long sessions

## Best Practices

- Use `customViewProvider` for custom content in infinite-loop scenarios
- Keep custom views lightweight and AutoLayout-friendly
- Set explicit height constraints for carousel in complex layouts
- Provide placeholder/failure images for remote URLs
- Apply global style once at app startup, then override per scene when needed
- Always update data source on main thread

## Notes

- `FKCarousel` is a `UIView` subclass and works with code, XIB, and Storyboard.
- For network images, ensure your server and ATS configuration are compatible (`https` recommended).
- If you need full analytics, track page and click events via `onPageChanged` and `onItemSelected`.

## License

This component follows the repository license policy.
Please refer to the root `LICENSE` file of the FKKit project.
