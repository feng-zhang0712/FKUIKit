# FKUtils

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Core Utility Categories](#core-utility-categories)
  - [Date \& Time Utilities](#date--time-utilities)
  - [Regex Validation](#regex-validation)
  - [Number Formatting](#number-formatting)
  - [String Processing](#string-processing)
  - [Device \& App Info](#device--app-info)
  - [UI Helpers](#ui-helpers)
  - [Collection Safety](#collection-safety)
  - [Image Processing](#image-processing)
  - [Common Helpers](#common-helpers)
- [Requirements](#requirements)
- [Installation](#installation)
- [Basic Usage](#basic-usage)
- [Advanced Usage](#advanced-usage)
  - [Date Format \& Relative Time](#date-format--relative-time)
  - [Regular Expression Validation](#regular-expression-validation)
  - [String Masking \& Format](#string-masking--format)
  - [Device Info Acquisition](#device-info-acquisition)
  - [UI \& Color Adaptation](#ui--color-adaptation)
  - [Safe Collection Operations](#safe-collection-operations)
- [API Reference](#api-reference)
- [Best Practices](#best-practices)
- [Notes](#notes)
- [License](#license)

## Overview
`FKUtils` is a native Swift utility component for large-scale iOS projects. It provides a unified, static API for high-frequency tasks across date/time handling, validation, formatting, string processing, device metadata, UI helpers, collection safety, image operations, and general application utilities.

The module is implemented with system frameworks only (`Foundation`, `UIKit`, `Network`, `AudioToolbox`, `AVFoundation`) and does not require Objective-C bridging or third-party dependencies.

Latest release: **0.20.1**

### Release Highlights (0.20.1)
- Introduced a production-ready `FKBadge` module under `Sources/FKUIKit/Components/Badge/` (`Public/`, `Internal/`, `Extension/`, same layering style as `PresentationController`).
- Global defaults and batch hide use `FKBadge.defaultConfiguration`, `FKBadge.hideAllBadges`, and `FKBadge.restoreAllBadges`; one-line APIs on `UIView`, `UIBarButtonItem`, and `UITabBarItem`.
- Module documentation: `Sources/FKUIKit/Components/Badge/README.md`

## Features
- Pure native implementation with zero external dependencies.
- Static utility APIs with no initialization cost.
- Namespace-based usage via `FKUtils.*`.
- Protocol-based provider customization for date and regex modules.
- Thread-safe provider registration for extensibility and testability.
- Commercial-project friendly utility coverage for common iOS workflows.

## Core Utility Categories

### Date & Time Utilities
Use when you need reliable date transformations and timeline logic:
- Date ↔ String conversion with custom format, timezone, locale, and calendar.
- Relative time description (`just now`, `minutes ago`, `yesterday`).
- Timestamp conversion, date comparison, component-based date addition.
- Weekday and month extraction.
- Date-string validation against a specific format.

### Regex Validation
Use for user input validation and text processing:
- Built-in validations for phone, email, ID card, password strength, verification code, license plate.
- URL, IPv4, postal code, and bank card validation (with Luhn check).
- Generic regex matching, extraction, and replacement.

### Number Formatting
Use for financial display and numeric readability:
- Decimal amount formatting with grouping separators.
- Rounding and truncation for `Decimal` values.
- Chinese unit formatting (`万`/`亿`).
- Percentage formatting.
- Random integer generation, zero-padding, and compact large-number formatting.

### String Processing
Use for text normalization and secure display:
- Safe substring extraction and join utilities.
- Whitespace/newline/special-character cleanup.
- Sensitive data masking (phone, ID card, email, bank card).
- Blank checks and length access.
- Pinyin conversion and first-letter extraction.
- URL/Base64 encode-decode and HTML escape-unescape.

### Device & App Info
Use for diagnostics, analytics metadata, and runtime info:
- Device model identifier and system version.
- Screen size, scale, and pixel resolution.
- Battery level/state and async network reachability status.
- Disk and memory status.
- App version, build, bundle identifier, app name, and vendor identifier.

### UI Helpers
Use for fast UI scaffolding and style consistency:
- Hex ↔ `UIColor` conversion and dynamic color creation.
- Adaptive font sizing based on screen width.
- Point/pixel conversion.
- Quick corner radius, shadow, and gradient application.
- Main-thread-safe execution and view screenshot capture.

### Collection Safety
Use to prevent crashes and simplify data mapping:
- Safe array indexing (`array[safe:]`).
- Typed dictionary value access.
- Array deduplication, sorting, and chunk splitting.
- Dictionary compaction, JSON serialization, and dictionary-to-model decoding.

### Image Processing
Use for upload optimization and lightweight image transformation:
- JPEG compression by target byte size.
- Rectangle crop.
- Rounded-corner rendering.
- Solid-color image creation.
- Image/Base64 conversion.

### Common Helpers
Use for app-level utility scenarios:
- Sandbox directory shortcuts and recursive file-size calculation.
- System jumps (App Store, Settings, call, SMS, email).
- Vibration feedback and local sound playback.
- Nil/empty checks and safe type conversions.
- Error-tolerant execution wrapper.

## Requirements
- **Language**: Swift 5.9+ compatible API style.
- **Platform Goal**: iOS 13+ utility design.
- **Current Package Configuration**: this repository currently declares iOS 15+ in `Package.swift`.
- **Dependencies**: no third-party libraries.

## Installation
Add the package with Swift Package Manager and import `FKCoreKit`.

```swift
import FKCoreKit
```

Git URL:

```text
git@github.com:feng-zhang0712/FKKit.git
```

In Xcode:
1. `File` → `Add Package Dependencies...`
2. Paste the repository URL.
3. Select product `FKCoreKit`.

## Basic Usage
`FKUtils` exposes grouped static APIs:

```swift
import FKCoreKit

let dateText = FKUtils.DateTime.string(from: Date(), format: "yyyy-MM-dd HH:mm:ss")
let isEmail = FKUtils.Regex.isValidEmail("dev@example.com")
let amount = FKUtils.Number.formatAmount(Decimal(string: "1234567.89") ?? 0)
let masked = FKUtils.String.maskPhone("13812345678")

let safeValue = [10, 20, 30][safe: 5] // nil
let docsURL = FKUtils.Common.documentsDirectory()
```

## Advanced Usage

### Date Format & Relative Time
```swift
import FKCoreKit

let now = Date()
let createdAt = FKUtils.DateTime.add(DateComponents(hour: -3), to: now) ?? now

let formatted = FKUtils.DateTime.string(
  from: now,
  format: "yyyy-MM-dd HH:mm",
  timeZone: TimeZone(identifier: "Asia/Shanghai"),
  locale: Locale(identifier: "en_US_POSIX"),
  calendar: Calendar(identifier: .gregorian)
)

let relative = FKUtils.DateTime.relativeDescription(for: createdAt, reference: now)
let valid = FKUtils.DateTime.isValidDate("2026-04-20", format: "yyyy-MM-dd")
```

### Regular Expression Validation
```swift
import FKCoreKit

let phoneOK = FKUtils.Regex.isValidPhone("13812345678")
let passwordOK = FKUtils.Regex.isStrongPassword("Aa@12345")
let cardOK = FKUtils.Regex.isValidBankCard("6222021001116244")

let items = FKUtils.Regex.extract("Order IDs: A-100 B-200", pattern: #"[A-Z]-\d+"#)
let replaced = FKUtils.Regex.replace("price=199", pattern: #"\d+"#, with: "299")
```

### String Masking & Format
```swift
import FKCoreKit

let phone = FKUtils.String.maskPhone("13812345678")        // 138****5678
let email = FKUtils.String.maskEmail("hello@example.com")
let noSpace = FKUtils.String.removeWhitespacesAndNewlines(" a \n b\tc ")
let pinyin = FKUtils.String.pinyin(from: "中文工具")
let first = FKUtils.String.firstLetter("中文工具")

let encoded = FKUtils.String.base64Encode("FKUtils")
let decoded = FKUtils.String.base64Decode(encoded)
```

### Device Info Acquisition
```swift
import FKCoreKit

let model = FKUtils.Device.modelIdentifier()
let version = FKUtils.Device.systemVersion()
let resolution = FKUtils.Device.screenResolution()
let appVersion = FKUtils.Device.appVersion()
let disk = FKUtils.Device.diskSpace()
let memory = FKUtils.Device.memoryStatus()

FKUtils.Device.networkStatus { status in
  print("Network:", status) // wifi / cellular / ethernet / unreachable / other
}
```

### UI & Color Adaptation
```swift
import UIKit
import FKCoreKit

let color = FKUtils.UI.color(hex: "#3B82F6")
let dynamic = FKUtils.UI.dynamicColor(light: .white, dark: .black)
let font = FKUtils.UI.adaptiveFont(size: 16, weight: .medium)

let view = UIView(frame: CGRect(x: 0, y: 0, width: 120, height: 120))
view.backgroundColor = color

FKUtils.UI.applyCornerRadius(12, to: view)
FKUtils.UI.applyShadow(to: view)
_ = FKUtils.UI.addGradient(to: view, colors: [.red, .orange])

FKUtils.UI.runOnMain {
  let image = FKUtils.UI.screenshot(of: view)
  print(image.size)
}
```

### Safe Collection Operations
```swift
import FKCoreKit

struct User: Decodable {
  let id: Int
  let name: String
}

let values = [1, 2, 2, 3, 3, 3]
let unique = FKUtils.Collection.unique(values)
let chunks = FKUtils.Collection.chunk(values, size: 2)
let third = values[safe: 2]

let dictionary: [String: Any] = ["id": 1, "name": "Frank"]
let user = FKUtils.Collection.decode(User.self, from: dictionary)
let json = FKUtils.Collection.jsonString(from: dictionary, prettyPrinted: true)
```

## API Reference

### Namespace
- `FKUtils.DateTime`
- `FKUtils.Regex`
- `FKUtils.Number`
- `FKUtils.String`
- `FKUtils.Device`
- `FKUtils.Collection`
- `FKUtils.Common`
- `FKUtils.UI` *(when `UIKit` is available)*
- `FKUtils.Image` *(when `UIKit` is available)*

### Provider Customization
You can replace default providers for extension or testing:

```swift
FKUtils.DateTime.register(provider: FKDateUtilsProvider())
FKUtils.Regex.register(provider: FKRegexUtilsProvider())
```

### Key API Groups
- **Date**: `string`, `date`, `timestamp`, `relativeDescription`, `compare`, `add`, `weekday`, `month`, `isValidDate`
- **Regex**: `isMatch`, `extract`, `replace`, `isValidPhone`, `isValidEmail`, `isValidBankCard`, ...
- **Number**: `formatAmount`, `rounded`, `truncated`, `formatPercent`, `compact`
- **String**: `substring`, `trim`, masking helpers, pinyin helpers, URL/Base64/HTML converters
- **Device**: model/system/screen/battery/network/disk/memory/app metadata
- **Collection**: `unique`, `sort`, `chunk`, `jsonString`, `decode`, plus safe array/dictionary extensions
- **Image**: `compress`, `crop`, `rounded`, `solidColor`, Base64 conversions
- **Common**: sandbox directories, file size, app jumps, vibration, sound, type conversions, safe execution

## Best Practices
- Keep utility calls in application/service layers instead of view code when possible.
- For date parsing in critical paths, pass explicit `locale` and `timeZone`.
- Validate external input using `FKUtils.Regex` before persistence or network submission.
- Use masking helpers before logging or analytics reporting.
- Prefer `array[safe:]` and typed dictionary accessors to avoid runtime crashes.
- For upload pipelines, combine `FKUtilsImage.compress` with server-side constraints.

## Notes
- `UI` and `Image` utilities are conditionally compiled with `UIKit`.
- `networkStatus` is asynchronous and returns one-shot status via callback.
- `safeDeviceIdentifier` uses `identifierForVendor` when available; do not treat it as a permanent global ID.
- In this repository, `swift build` on plain macOS may fail for UIKit-based targets; use an iOS destination in Xcode.

## License
This project is released under the [MIT License](LICENSE).
