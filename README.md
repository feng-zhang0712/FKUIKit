# FKKit

[![iOS](https://img.shields.io/badge/iOS-13.0%2B-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange.svg)](https://swift.org/)
[![SPM](https://img.shields.io/badge/SPM-supported-brightgreen.svg)](https://swift.org/package-manager/)
[![CocoaPods](https://img.shields.io/badge/CocoaPods-supported-ee3322.svg)](https://cocoapods.org/)
[![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)](LICENSE)

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Module Structure](#module-structure)
- [Core Components](#core-components)
  - [FKCoreKit](#fkcorekit)
  - [FKUIKit](#fkuikit)
  - [FKCompositeKit](#fkcompositekit)
- [Requirements](#requirements)
- [Installation (SPM)](#installation-spm)
- [Usage](#usage)
- [Branching & Collaboration (Recommended)](#branching--collaboration-recommended)
- [License](#license)
- [Changelog](#changelog)

## Overview
FKKit is a modular, pure-native Swift component library for iOS applications.  
It is built on top of Apple system frameworks and distributed via Swift Package Manager (SPM), with no third-party runtime dependencies.

The repository is organized into three product modules:
- `FKCoreKit`
- `FKUIKit`
- `FKCompositeKit`

Each module focuses on a different layer of app development, from infrastructure and utilities to UI components and composite business widgets.

In addition, the package exposes a small Foundation-only product for EmptyState core logic (also linked by **`FKUIKit`** and re-exported for convenience):
- `FKEmptyStateCoreLite` (resolver + i18n + `FKEmptyStateType` / factory; no UIKit dependency)

## Features
- Pure Swift implementation (Swift 6 language mode in package settings).
- No third-party dependencies.
- Swift Package Manager first-class integration.
- Modular architecture with clear package products.
- Protocol-oriented design in multiple components for extensibility and testability.
- Example project included for direct integration reference.

## Module Structure

```text
FKKit/
├─ Package.swift
├─ Sources/
│  ├─ FKCoreKit/
│  │  ├─ Async/
│  │  ├─ BusinessKit/
│  │  ├─ Extension/
│  │  ├─ FileManager/
│  │  ├─ Logger/
│  │  ├─ Network/
│  │  ├─ Permissions/
│  │  ├─ Security/
│  │  ├─ Storage/
│  │  └─ Utils/
│  ├─ FKUIKit/
│  │  └─ Components/
│  │     ├─ Badge/
│  │     ├─ BlurView/
│  │     ├─ Button/
│  │     ├─ CornerShadow/
│  │     ├─ Divider/
│  │     ├─ EmptyState/
│  │     ├─ ExpandableText/
│  │     ├─ MultiPicker/
│  │     ├─ PresentationController/
│  │     ├─ Refresh/
│  │     ├─ Skeleton/
│  │     ├─ TabBar/
│  │     ├─ TextField/
│  │     └─ Toast/
│  └─ FKCompositeKit/
│     └─ Components/
│        ├─ Base/
│        ├─ Filter/
│        └─ ListKit/
└─ Examples/
```

## Core Components

### FKCoreKit
`FKCoreKit` provides foundational capabilities used across app layers:

- `Network`: URLSession-based networking stack (request models, interceptors, caching, upload/download helpers).
- `Storage`: multi-backend storage abstraction (UserDefaults, Keychain, file, memory) with Codable support.
- `Logger`: structured logging, formatting, file persistence, and diagnostics helpers.
- `Permissions`: unified iOS permission management and status/request flow.
- `Security`: crypto/security utilities (hash, AES/RSA helpers, encoding, signature helpers).
- `FileManager`: file I/O, directory utilities, and transfer-oriented helpers.
- `Async`: concurrency utilities (queues, cancellable task wrappers, debounce/throttle helpers).
- `BusinessKit`: app/business infrastructure (version, deeplink, lifecycle, analytics, i18n helpers).
- `Extension`: cross-cutting `public` extensions for **Foundation**, **CoreGraphics**, and **UIKit** (UIKit files use `#if canImport(UIKit)`); members use an `fk_` prefix to reduce name clashes with app and SDK code.
- `Utils`: high-frequency utility APIs for date/string/number/device/UI/collection/common operations.

### FKUIKit
`FKUIKit` contains reusable UIKit components for modern iOS interfaces:

- `Badge`: flexible badge display for views, bar items, and tab items, with corner/center anchoring and customizable styles/animations.
- `BlurView`: high-performance blur component with system/custom pipelines, UIKit/SwiftUI adapters, image/view snapshot blur APIs, and IB/global-configuration support.
- `Button`: configurable button system with style/content/loading behavior.
- `CornerShadow`: rounded-rect masks, borders, gradient fill/stroke, and explicit-path shadows (`Public` / `Internal` / `Extension`); see `Sources/FKUIKit/Components/CornerShadow/README.md`.
- `Divider`: hairline separator (`FKDivider` / `FKDividerView`); dashed & gradient strokes; `FKDivider.defaultConfiguration`; layout under `Public/`, `Internal/`, `Extension/` (see module README).
- `EmptyState`: loading/empty/error overlay (`Public` / `Internal` / `Extension`) plus **`FKEmptyStateCoreLite`** (resolver + i18n); `import FKUIKit` re-exports CoreLite.
- `ExpandableText`: long attributed text expand/collapse for `UILabel` / `UITextView` plus SwiftUI `FKExpandableTextView`; sources under `Public/`, `Internal/`, `Extension/` with `FKExpandableText.defaultConfiguration` and layout cache (see component README).
- `MultiPicker`: native multi-level cascading picker with built-in region data and custom data provider support.
- `PresentationController`: modal/overlay presentation controller system (sheet/anchor modes, detents, keyboard/safe-area/interaction configuration).
- `Refresh`: pull-to-refresh and load-more controls for scroll views.
- `Skeleton`: skeleton loading system for views/lists/containers with animation options.
- `TabBar`: high-performance UIKit tab header (UICollectionView-based) with indicator, badges, data source, and paging progress linkage (UI-only).
- `TextField`: one-stop formatted input components (`FKTextField`, `FKCodeTextField`, `FKCountTextView`) with validation, counters, OTP slots, and shake feedback.
- `Toast`: unified Toast / HUD / Snackbar presenter (`Public/` + `Internal/`) with queueing, priority, keyboard-aware placement, accessibility, optional material blur, custom content, per-instance progress updates, presentation sound policy, and SwiftUI hosting support (see `Sources/FKUIKit/Components/Toast/README.md`).

### FKCompositeKit
`FKCompositeKit` builds business-facing composite components on top of `FKCoreKit` + `FKUIKit`:

- `Base`: reusable base foundation for cells and controllers.
- `Filter`: filter bar/panel/pill and multi-layout filtering components.
- `ListKit`: list state/pagination coordination and plugin-style list assembly.

This module currently focuses on source-level composable components; add internal docs in each directory as your team standard evolves.

## Requirements
- iOS 15.0+ (as declared in `Package.swift`)
- macOS 10.15+ (package-level declaration for compatible builds)
- Swift toolchain with Swift 6.3 support

## Installation (SPM)

### Xcode
1. Open `File` -> `Add Package Dependencies...`
2. Enter repository URL:
   - `https://github.com/feng-zhang0712/FKKit.git`
3. Select one or more products:
   - `FKCoreKit`
   - `FKEmptyStateCoreLite`
   - `FKUIKit`
   - `FKCompositeKit`

### Package.swift
```swift
dependencies: [
  .package(url: "https://github.com/feng-zhang0712/FKKit.git", from: "0.45.0")
],
targets: [
  .target(
    name: "YourTarget",
    dependencies: [
      .product(name: "FKCoreKit", package: "FKKit"),
      .product(name: "FKEmptyStateCoreLite", package: "FKKit"),
      .product(name: "FKUIKit", package: "FKKit"),
      .product(name: "FKCompositeKit", package: "FKKit")
    ]
  )
]
```

## Usage

Import only what you need:

```swift
import FKCoreKit
import FKUIKit
import FKCompositeKit
```

Example quick integrations:

```swift
// FKCoreKit
let isEmail = FKUtils.Regex.isValidEmail("dev@example.com")
let trimmed = "  hello  ".fk_trimmed

// FKUIKit
someView.fk_showSkeleton()

// FKCompositeKit
let pageManager = FKPageManager()
```

For complete usage and advanced APIs, refer to each module README in `Sources/...`.

## Branching & Collaboration (Recommended)

- Use `develop` as the integration branch.
- Create feature branches from `develop` (for example: `feature/skeleton-auto-mode`).
- Keep commits focused and use clear conventional-style messages.
- Follow this commit format:
  - `<type>(<scope>): <subject>`
  - Example: `feat(ui): add auto skeleton exclusion options`
- Recommended commit types:
  - `feat`: new feature
  - `fix`: bug fix
  - `refactor`: internal refactor without behavior change
  - `perf`: performance improvement
  - `docs`: documentation updates
  - `test`: tests added or updated
  - `build`: build/dependency/tooling changes
  - `chore`: maintenance tasks
- Commit message rules:
  - Use present tense and imperative mood (`add`, `fix`, `refactor`).
  - Keep the subject concise (recommended <= 72 characters).
  - Reference module scope whenever possible (for example: `core`, `ui`, `composite`, `examples`, `docs`).
  - Add a body when context is needed (why, impact, migration notes).
- Open pull requests into `develop` with:
  - change summary
  - test/verification notes
  - migration notes when APIs change
- Tag stable releases with semantic versions (for example: `0.25.0`), then merge release work back into `develop`.

## License
This repository is licensed under the MIT License.  
See [`LICENSE`](LICENSE) for details.

## Changelog
Release history and migration details are maintained in [`CHANGELOG.md`](CHANGELOG.md).
