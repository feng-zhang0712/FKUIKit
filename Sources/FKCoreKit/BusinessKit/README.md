# FKBusinessKit

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Core Business Capabilities](#core-business-capabilities)
  - [App Version Update](#app-version-update)
  - [Global Event Track](#global-event-track)
  - [Multi-language I18n](#multi-language-i18n)
  - [App Lifecycle Monitor](#app-lifecycle-monitor)
  - [Deeplink & Universal Link](#deeplink--universal-link)
  - [Device & App Info](#device--app-info)
  - [Business Utils (Time/Number/String)](#business-utils-timenumberstring)
- [Requirements](#requirements)
- [Installation](#installation)
- [Architecture](#architecture)
- [Basic Usage](#basic-usage)
- [Advanced Usage](#advanced-usage)
  - [Version Check & Update](#version-check--update)
  - [Event Track Report](#event-track-report)
  - [Language Switch & Localization](#language-switch--localization)
  - [Lifecycle Listener](#lifecycle-listener)
  - [Deeplink Parser & Route](#deeplink-parser--route)
  - [Business Format Utils](#business-format-utils)
- [API Reference](#api-reference)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)
- [Notes](#notes)
- [License](#license)

## Overview

`FKBusinessKit` is a **pure native Swift** business capability component under `FKCoreKit`.
It provides a **single entry point** (`FKBusinessKit.shared`) for high-frequency app features commonly needed in medium and large iOS projects.

Design goals:

- **Zero third-party dependencies** (Foundation/UIKit only)
- **Protocol-oriented** and **pluggable** for testing and extension
- **Thread-safe** and **non-blocking** (does not block the main thread)
- **Async/await + closure dual APIs** for gradual adoption
- Works with any architecture (MVVM / MVP / Clean Architecture / etc.)

Source location:

- `Sources/FKCoreKit/BusinessKit`

---

## Features

- **Version update management**
  - Local/remote version comparison
  - Optional vs forced update decisions
  - Built-in update alert presentation
  - Optional App Store version provider (iTunes Lookup API)
- **Global event tracking**
  - Page view / click / custom event APIs
  - Automatic common parameter injection (device, OS, version, channel, environment)
  - File-backed buffering, batching, and retry with drop policy
  - Pluggable uploader protocol (integrate with your network stack)
- **In-app i18n**
  - Language switching independent of system language
  - `xx.lproj` bundle resolution
  - Observer + notification for UI refresh
- **App lifecycle monitoring**
  - Centralized state stream based on `UIApplication` notifications
  - Disposable observation tokens
- **Deeplink routing**
  - URL parsing + query parameter extraction
  - Host + path pattern matching (`*` wildcard segments)
  - Routing dispatch via pluggable handlers
- **Business utilities**
  - Time formatting and relative time strings
  - Number formatting (thousands separators, compact units)
  - Sensitive-string masking (phone / ID / email)
  - Global alert de-duplication
  - Startup task orchestration with priority and delay

---

## Core Business Capabilities

### App Version Update

Use cases:

- Show a one-time "Update Available" prompt after launch.
- Enforce a forced update when backend requires a minimum version.
- Route users to the App Store (or a custom update URL) with one API call.

What it includes:

- `FKBusinessKit.shared.version.appMetadata()` to read app version/build/bundle ID
- `checkForUpdate(using:)` in async and closure styles
- `presentUpdatePromptIfNeeded(result:presenter:)` for optional/forced prompts
- `FKAppStoreRemoteVersionProvider` for App Store version lookup (optional)

### Global Event Track

Use cases:

- Unified page exposure/click tracking across multiple teams/modules.
- Automatic injection of shared parameters (device, OS, app version, channel).
- Batch uploads with buffering, retry, and a safe drop policy.

What it includes:

- `trackPageView`, `trackClick`, `trackEvent`
- `setCommonParametersProvider(_:)` for extra shared params
- `setUploader(_:)` for real network delivery
- File-backed FIFO store in `Caches/FKBusinessKit/`

### Multi-language I18n

Use cases:

- Allow users to switch language inside the app without changing system settings.
- Keep UI responsive by observing language changes and refreshing views.

What it includes:

- `currentLanguageCode`
- `setLanguageCode(_:)` + persisted selection
- `localized(_:table:)` resolving to `xx.lproj`
- `observeLanguageChange(_:)` and a notification hook for UI refresh

### App Lifecycle Monitor

Use cases:

- Centralize foreground/background transitions for analytics, caching, or task control.
- Avoid scattering lifecycle observers across the app.

What it includes:

- `state` and an observer stream emitting `FKAppLifecycleState`
- `FKBusinessObservationToken` for safe cleanup

### Deeplink & Universal Link

Use cases:

- Route URLs from push notifications, universal links, or external app calls.
- Parse query parameters and dispatch to the correct screen.

What it includes:

- Route registration (`register`) and removal (`unregister`)
- URL matching:
  - Optional host match
  - Optional path pattern match (`*` wildcard segments)
- Query parameter extraction into `[String: String]`

### Device & App Info

Use cases:

- Inject common analytics parameters.
- Log environment/channel/build metadata.
- Diagnostics and support workflows.

What it includes:

- Bundle ID, app version, build number
- Device model identifier (`hw.machine`)
- System version, screen size
- Channel + environment (debug/release)

### Business Utils (Time/Number/String)

Use cases:

- Display "just now / minutes ago / today / yesterday" style timestamps.
- Format amounts and compact numbers for lists.
- Mask sensitive strings before logging/analytics.
- Prevent duplicate alerts.
- Defer non-critical startup work to improve perceived launch performance.

What it includes:

- `utils.time`: formatting + relative description
- `utils.number`: amount and compact formatting (EN + ZH units)
- `utils.mask`: phone/ID/email masking + generic masking
- `utils.alerts`: `presentOnce(id:...)`
- `utils.startup`: startup task registration and execution

---

## Requirements

- Swift 5.9+
- iOS 13.0+ (API design target)
- Xcode 15+

> Note: this repository currently declares `iOS 15+` in `Package.swift`.  
> `FKBusinessKit` is implemented with iOS 13+ compatible APIs, but your package platform setting may need to be aligned with your app target.

---

## Installation

### Swift Package Manager (Recommended)

Add `FKKit` to your project via Swift Package Manager, then import:

```swift
import FKCoreKit
```

Module source path:

- `Sources/FKCoreKit/BusinessKit`

---

## Architecture

`FKBusinessKit` is built around a single entry type and multiple protocol-driven subsystems:

- `FKBusinessKit` (singleton-style hub)
- `Core`
  - `FKBusinessKitConfiguration` (channel/environment/default language/analytics policy)
  - `FKBusinessProtocols.swift` (all public capability protocols)
  - `FKBusinessInfoProvider` (device/app info)
- `Version`
  - `FKBusinessVersionManager` (version compare + update prompt)
  - `FKAppStoreRemoteVersionProvider` (App Store lookup provider)
- `Track`
  - `FKBusinessAnalyticsTracker` (buffer -> batch -> upload -> retry)
- `I18n`
  - `FKBusinessI18nManager` (in-app language switching)
- `Lifecycle`
  - `FKBusinessLifecycleObserver` (non-invasive lifecycle stream)
- `Deeplink`
  - `FKBusinessDeeplinkRouter` (route registry + dispatch)
- `Utils`
  - `FKBusinessTimeFormatter`, `FKBusinessNumberFormatter`, `FKBusinessMasker`
  - `FKBusinessAlertManager` (de-duplication)
  - `FKBusinessStartupTaskManager` (startup task orchestration)
- `Model`
  - `FKBusinessError` (unified error)
  - `FKBusinessObservationToken` (disposable observation)
  - `FKBusinessModels.swift` (version/track/lifecycle/deeplink/utils models)

Key principles:

- **Protocol-oriented** public surface for testability
- **Pluggable implementations** (e.g., remote version provider, analytics uploader)
- **Thread-safe internals** using `NSLock`/serial queues
- **Non-blocking APIs**: event tracking and flushing are async by design

---

## Basic Usage

### 1) Configure channel / environment (optional)

```swift
import FKCoreKit

FKBusinessKit.shared.updateConfiguration { config in
  config.channel = "AppStore"
  config.defaultLanguageCode = "en"
  config.analyticsFlushInterval = 10
  config.analyticsMaxBatchSize = 20
  config.analyticsMaxRetryCount = 3
}
```

### 2) Track events (non-blocking)

```swift
FKBusinessKit.shared.track.trackPageView("Home", parameters: ["source": "tab"])
FKBusinessKit.shared.track.trackClick("BuyButton", page: "Product", parameters: ["sku": "123"])
FKBusinessKit.shared.track.trackEvent("checkout_submit", parameters: ["step": "pay"])
```

### 3) In-app language switching

```swift
FKBusinessKit.shared.i18n.setLanguageCode("zh-Hans")
let title = FKBusinessKit.shared.i18n.localized("home_title", table: nil)
print(title)
```

### 4) Observe lifecycle changes

```swift
let token = FKBusinessKit.shared.lifecycle.observe { state in
  print("lifecycle:", state.rawValue)
}

// Later when no longer needed:
token.invalidate()
```

---

## Advanced Usage

### Version Check & Update

#### Option A: App Store lookup provider (iTunes Lookup API)

```swift
import FKCoreKit

let provider = FKAppStoreRemoteVersionProvider(
  bundleID: FKBusinessKit.shared.info.bundleID,
  countryCode: "us",
  isForceUpdate: false
)

FKBusinessKit.shared.version.checkForUpdate(using: provider) { result in
  switch result {
  case let .success(check):
    FKBusinessKit.shared.version.presentUpdatePromptIfNeeded(result: check, presenter: nil)
  case let .failure(error):
    print("Version check failed:", error.localizedDescription)
  }
}
```

#### Option B: Your own backend version provider

Implement `FKRemoteVersionProviding` and return `FKRemoteVersionInfo`:

```swift
import Foundation
import FKCoreKit

final class MyRemoteVersionProvider: FKRemoteVersionProviding {
  func fetchRemoteVersion() async throws -> FKRemoteVersionInfo {
    // Fetch from your backend and map to FKRemoteVersionInfo.
    return FKRemoteVersionInfo(
      version: "2.0.0",
      releaseNotes: "Performance improvements and bug fixes.",
      updateURL: URL(string: "https://apps.apple.com/app/id123456789"),
      isForceUpdate: false
    )
  }
}
```

Then:

```swift
Task {
  do {
    let check = try await FKBusinessKit.shared.version.checkForUpdate(using: MyRemoteVersionProvider())
    FKBusinessKit.shared.version.presentUpdatePromptIfNeeded(result: check, presenter: nil)
  } catch {
    print(error)
  }
}
```

### Event Track Report

#### 1) Provide a batch uploader

`FKBusinessKit` does not hardcode any network stack. You plug in your uploader by implementing `FKAnalyticsUploading`.

```swift
import Foundation
import FKCoreKit

final class MyAnalyticsUploader: FKAnalyticsUploading {
  func upload(batch: [FKAnalyticsEvent]) async throws {
    // Send to your server using URLSession / your networking module.
    // Throw on failure to enable retry.
    _ = batch
  }
}

FKBusinessKit.shared.track.setUploader(MyAnalyticsUploader())
```

#### 2) Add extra common parameters (optional)

```swift
final class MyCommonParams: FKAnalyticsCommonParametersProviding {
  func commonParameters() -> [String: String] {
    [
      "user_id": "1001",
      "region": "US"
    ]
  }
}

FKBusinessKit.shared.track.setCommonParametersProvider(MyCommonParams())
```

#### 3) Flush manually

```swift
FKBusinessKit.shared.track.flush(completion: {
  print("flush done")
})
```

Or async:

```swift
Task { await FKBusinessKit.shared.track.flush() }
```

### Language Switch & Localization

#### 1) Add language resources

Create standard iOS localization resources in your app target:

- `en.lproj/Localizable.strings`
- `zh-Hans.lproj/Localizable.strings`

Example:

```text
/* Localizable.strings */
"home_title" = "Home";
```

#### 2) Observe and refresh UI

```swift
let token = FKBusinessKit.shared.i18n.observeLanguageChange { _ in
  // Re-render views, reload table/collection, reset root controller, etc.
}

FKBusinessKit.shared.i18n.setLanguageCode("en")
```

Also available:

- `FKBusinessI18nManager.languageDidChangeNotification`

### Lifecycle Listener

```swift
let token = FKBusinessKit.shared.lifecycle.observe { state in
  switch state {
  case .active:
    FKBusinessKit.shared.track.trackEvent("app_active", parameters: nil)
  case .background:
    FKBusinessKit.shared.track.flush(completion: nil)
  default:
    break
  }
}
```

### Deeplink Parser & Route

Register routes:

```swift
import FKCoreKit

FKBusinessKit.shared.deeplink.register(
  FKDeeplinkRoute(id: "product", host: "example.com", pathPattern: "/product/*") { context in
    // Query parameters are parsed into a dictionary.
    // Example URL: https://example.com/product/123?ref=ad
    print("params:", context.parameters)
    return true
  }
)
```

Route an URL:

```swift
let url = URL(string: "https://example.com/product/123?ref=ad")!
let handled = FKBusinessKit.shared.deeplink.route(url, source: .universalLink)
print("handled:", handled)
```

### Business Format Utils

#### Time (format + relative)

```swift
let now = Date()
let earlier = now.addingTimeInterval(-120)

let text = FKBusinessKit.shared.utils.time.relativeDescription(from: earlier, now: now)
print(text) // e.g. "2m ago" / "2分钟前"
```

#### Number (amount + compact)

```swift
let amount = FKBusinessKit.shared.utils.number.formatAmount(Decimal(string: "1234567.89")!, fractionDigits: 2)
print(amount) // "1,234,567.89" (locale-dependent)

let compact = FKBusinessKit.shared.utils.number.formatCompact(12345678, fractionDigits: 1)
print(compact) // "12.3M" or "1234.6万" depending on language code
```

#### Masking (phone / ID / email)

```swift
print(FKBusinessKit.shared.utils.mask.maskPhone("13800138000"))       // 138****8000
print(FKBusinessKit.shared.utils.mask.maskIDCard("110101199001011234")) // 110101********1234
print(FKBusinessKit.shared.utils.mask.maskEmail("name@example.com"))  // n***@example.com
```

#### Alert de-duplication

```swift
FKBusinessKit.shared.utils.alerts.presentOnce(
  id: "force_login",
  title: "Session Expired",
  message: "Please sign in again.",
  actions: [
    FKAlertAction(title: "OK", style: .default) {
      // Handle action
    }
  ],
  presenter: nil
)
```

#### Startup tasks (priority + delay)

```swift
FKBusinessKit.shared.utils.startup.register(
  FKStartupTask(id: "warmup_cache", priority: .low, delay: 1.0) {
    // Non-critical async work after launch
  }
)

FKBusinessKit.shared.utils.startup.runAll(completion: {
  print("startup tasks done")
})
```

---

## API Reference

Entry point:

- `FKBusinessKit.shared`

Configuration:

- `FKBusinessKitConfiguration`
- `FKBusinessEnvironment`
- `FKBusinessKit.shared.configuration`
- `FKBusinessKit.shared.updateConfiguration(_:)`

Version:

- `FKBusinessVersioning`
- `FKRemoteVersionProviding`
- `FKBusinessKit.shared.version.appMetadata()`
- `FKBusinessKit.shared.version.checkForUpdate(using:)` (async)
- `FKBusinessKit.shared.version.checkForUpdate(using:completion:)` (closure)
- `FKBusinessKit.shared.version.presentUpdatePromptIfNeeded(result:presenter:)`
- `FKAppStoreRemoteVersionProvider`

Tracking:

- `FKBusinessTracking`
- `FKAnalyticsUploading`
- `FKAnalyticsCommonParametersProviding`
- `FKBusinessKit.shared.track.trackPageView(_:parameters:)`
- `FKBusinessKit.shared.track.trackClick(_:page:parameters:)`
- `FKBusinessKit.shared.track.trackEvent(_:parameters:)`
- `FKBusinessKit.shared.track.flush()` / `flush(completion:)`

I18n:

- `FKBusinessLocalizing`
- `FKBusinessKit.shared.i18n.currentLanguageCode`
- `FKBusinessKit.shared.i18n.setLanguageCode(_:)`
- `FKBusinessKit.shared.i18n.localized(_:table:)`
- `FKBusinessKit.shared.i18n.observeLanguageChange(_:)`
- `FKBusinessI18nManager.languageDidChangeNotification`

Lifecycle:

- `FKBusinessLifecycleObserving`
- `FKBusinessKit.shared.lifecycle.state`
- `FKBusinessKit.shared.lifecycle.observe(_:)`

Deeplink:

- `FKBusinessDeeplinkRouting`
- `FKDeeplinkRoute`
- `FKDeeplinkContext`
- `FKBusinessKit.shared.deeplink.register(_:)`
- `FKBusinessKit.shared.deeplink.route(_:source:)`

Info:

- `FKBusinessInfoProviding`
- `FKBusinessKit.shared.info.bundleID / appVersion / buildNumber / systemVersion / deviceModelIdentifier / screenSize / channel / environment`

Utils:

- `FKBusinessUtilitiesProviding`
- `FKBusinessKit.shared.utils.time / number / mask / alerts / startup`

---

## Error Handling

`FKBusinessKit` uses a unified error type:

- `FKBusinessError`
  - `.invalidArgument(...)`
  - `.missingConfiguration(...)`
  - `.unsupported(...)`
  - `.networkFailed(...)`
  - `.persistenceFailed(...)`
  - `.cancelled`
  - `.unknown(...)`

Example:

```swift
FKBusinessKit.shared.version.checkForUpdate(using: provider) { result in
  if case let .failure(error) = result {
    switch error {
    case .networkFailed:
      // Retry or fallback
      break
    case .unsupported:
      // Platform limitation
      break
    default:
      break
    }
  }
}
```

---

## Best Practices

- **Install early**: configure channel/environment and analytics uploader during app launch.
- **Keep tracking non-blocking**: avoid heavy parameter computation inside tracking calls.
- **Batch upload**: implement `FKAnalyticsUploading` to upload in batch, and throw on failures to enable retry.
- **Avoid sensitive leakage**: use `utils.mask` before logging or analytics.
- **Handle language change**: observe language changes and refresh UI in a single place (root coordinator).
- **Deeplink safety**: validate route parameters (presence and format) before navigation.
- **Forced update**: use backend-provided force-update flags for critical fixes and security upgrades.

---

## Notes

- **Localization resources**: `FKBusinessKit` resolves strings from `Bundle.main` language bundles (standard `xx.lproj` folders). Make sure your app target includes these resources.
- **Analytics persistence**: events are stored under the app's caches directory (`Caches/FKBusinessKit/`). iOS may purge caches; design your backend accordingly.
- **Uploader responsibility**: `FKBusinessKit` does not ship a networking layer for analytics upload. Provide your own `FKAnalyticsUploading` implementation.
- **Package platform**: this repo currently declares `iOS 15+` in `Package.swift`. If your app targets iOS 13/14, align the package platform accordingly.

---

## License

`FKBusinessKit` is part of `FKKit` and follows the repository license.
See the root `LICENSE` file for details.

