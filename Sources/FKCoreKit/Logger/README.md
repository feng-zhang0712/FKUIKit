# FKLogger

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Log Levels](#log-levels)
- [Basic Configuration](#basic-configuration)
- [Usage Guide](#usage-guide)
  - [Basic Log Printing](#basic-log-printing)
  - [Formatted Log Output](#formatted-log-output)
  - [File Logging](#file-logging)
  - [Log Management](#log-management)
  - [Custom Configuration](#custom-configuration)
- [Advanced Usage](#advanced-usage)
  - [Crash Log Capture](#crash-log-capture)
  - [Multi-thread Safety](#multi-thread-safety)
  - [Environment Control](#environment-control)
- [API Reference](#api-reference)
- [Best Practices](#best-practices)
- [Notes](#notes)
- [License](#license)

## Overview

`FKLogger` is a lightweight, protocol-oriented logging and debugging component in `FKCoreKit`.

It is implemented with native system APIs only (`Foundation` and `Darwin`), with zero third-party dependencies and no Objective-C bridge dependency in public APIs.

The component is designed for medium and large iOS projects that need:

- Clear and consistent logs across modules
- Runtime-configurable log behavior
- File persistence with rotation and storage limits
- Practical debugging helpers for complex data

## Features

- Five log levels: `verbose`, `debug`, `info`, `warning`, `error`
- Per-level switch control at runtime
- Build-aware defaults:
  - `DEBUG`: logging enabled by default
  - `RELEASE`: logging disabled by default
- Rich formatted output with:
  - timestamp
  - level label
  - file / function / line
  - prefix and metadata
- Console beautification:
  - ANSI colorized output
  - emoji level markers
- Asynchronous file logging:
  - daily rotation
  - size-based split
  - total storage cap cleanup
- Log file management APIs:
  - list files
  - clear files
  - export merged archive file
- Global crash/debug capture helpers:
  - uncaught exception handler
  - common fatal signal capture
  - custom exception capture
  - network event capture
- Debug helpers:
  - pretty print dictionaries/arrays/objects
  - pretty print `Encodable` models as JSON
- Thread-safe state updates and non-blocking log writes

## Requirements

- Swift 5.9+
- iOS 13.0+ (API design target)
- Xcode 15+

> This repository currently declares iOS 15+ in `Package.swift`.  
> `FKLogger` itself is implemented with iOS 13+ compatible APIs.

## Installation

### Swift Package Manager

Add `FKKit` as a dependency, then import `FKCoreKit`:

```swift
import FKCoreKit
```

If your project already uses this monorepo, `FKLogger` is available under:

- `Sources/FKCoreKit/Logger`

## Log Levels

`FKLogger` supports five severity levels:

- `FKLogLevel.verbose` - deep diagnostics and tracing
- `FKLogLevel.debug` - development-time debugging messages
- `FKLogLevel.info` - normal business flow events
- `FKLogLevel.warning` - recoverable or risky states
- `FKLogLevel.error` - failures and error conditions

You can enable or disable a specific level at runtime:

```swift
FKLogger.shared.setLevel(.verbose, isEnabled: false)
FKLogger.shared.setLevel(.error, isEnabled: true)
```

## Basic Configuration

Use the shared singleton for most projects:

```swift
let logger = FKLogger.shared
```

Update configuration atomically:

```swift
logger.updateConfig { config in
  config.prefix = "[MyApp]"
  config.includesTimestamp = true
  config.includesFileName = true
  config.includesFunctionName = true
  config.includesLineNumber = true
  config.usesColorizedConsole = true
  config.usesEmoji = true
  config.persistsToFile = true
  config.maxFileSizeInBytes = 5 * 1024 * 1024
  config.maxStorageSizeInBytes = 100 * 1024 * 1024
  config.rotatesDaily = true
}
```

You can also replace the entire config:

```swift
FKLogger.shared.config = .debugDefault
```

## Usage Guide

### Basic Log Printing

Use the global one-line helpers:

```swift
FKLogV("verbose message")
FKLogD("debug message")
FKLogI("info message")
FKLogW("warning message")
FKLogE("error message")
```

Or call the singleton directly:

```swift
let logger = FKLogger.shared
logger.debug("Login started")
logger.info("User profile loaded")
logger.warning("Cache miss for key: profile_123")
logger.error("Profile request failed")
```

Attach metadata for structured diagnostics:

```swift
logger.error(
  "Payment request failed",
  metadata: [
    "order_id": "A1024",
    "api": "/v1/payment",
    "retry_count": "1"
  ]
)
```

### Formatted Log Output

By default, each line can include:

- custom prefix
- timestamp (`yyyy-MM-dd HH:mm:ss.SSS`)
- emoji + level label
- source file, function, line
- message and sorted metadata

Use debug helpers for complex values:

```swift
let payload: [String: Any] = [
  "user": "frank",
  "roles": ["admin", "reviewer"],
  "active": true
]
FKLogger.shared.dumpValue(payload)
```

For strongly typed models:

```swift
struct UserProfile: Encodable {
  let id: Int
  let name: String
}

FKLogger.shared.dumpEncodable(UserProfile(id: 1, name: "Frank"))
```

### File Logging

Enable file persistence:

```swift
FKLogger.shared.updateConfig { config in
  config.persistsToFile = true
  config.maxFileSizeInBytes = 5 * 1024 * 1024
  config.maxStorageSizeInBytes = 100 * 1024 * 1024
  config.rotatesDaily = true
}
```

Behavior:

- Writes are asynchronous to avoid blocking the main thread
- Log files rotate by date (optional) and by file size
- Total storage is capped; old files are removed first

### Log Management

List local log files:

```swift
let files = FKLogger.shared.allLogFiles()
files.forEach { print($0.path) }
```

Export all logs into one temporary archive file:

```swift
if let exportURL = FKLogger.shared.exportLogArchive() {
  print("Exported: \(exportURL.path)")
  // Present share sheet in your app UI if needed.
}
```

Clear all persisted logs:

```swift
FKLogger.shared.clearLogFiles()
```

### Custom Configuration

Create a fully custom config:

```swift
let customConfig = FKLoggerConfig(
  isEnabled: true,
  enabledLevels: [.info, .warning, .error],
  prefix: "[Checkout]",
  includesTimestamp: true,
  includesFileName: false,
  includesFunctionName: true,
  includesLineNumber: false,
  usesColorizedConsole: true,
  usesEmoji: true,
  persistsToFile: true,
  maxFileSizeInBytes: 2 * 1024 * 1024,
  maxStorageSizeInBytes: 20 * 1024 * 1024,
  rotatesDaily: true
)

FKLogger.shared.config = customConfig
```

You can also access logger from namespace:

```swift
FKCoreKit.logger.info("Namespace-based access")
```

## Advanced Usage

### Crash Log Capture

Install global crash capture early in app startup (for example `application(_:didFinishLaunchingWithOptions:)`):

```swift
FKLogger.shared.installCrashCapture()
```

Capture custom exception-style events:

```swift
FKLogger.shared.captureException(
  name: "BusinessInvariantViolation",
  reason: "Cart total became negative",
  metadata: ["module": "Checkout"]
)
```

Capture network diagnostics:

```swift
var request = URLRequest(url: URL(string: "https://api.example.com/profile")!)
request.httpMethod = "GET"

FKLogger.shared.captureNetwork(
  request: request,
  response: nil,
  data: nil,
  error: NSError(domain: "network", code: -1009)
)
```

### Multi-thread Safety

`FKLogger` is designed for concurrent usage:

- State mutations are synchronized on an internal state queue
- Log processing is dispatched asynchronously on a background work queue
- File operations are isolated on a dedicated file queue

When you need to guarantee all pending logs are written (for example before termination), call:

```swift
FKLogger.shared.flushSynchronously()
```

### Environment Control

`FKLoggerConfig.default` is build-aware:

- Debug build -> `debugDefault` (enabled, rich output, file logging on)
- Release build -> `releaseDefault` (disabled by default)

This means most teams do not need manual toggles when switching build configurations.

## API Reference

Core type:

- `FKLogger.shared`

Logging methods:

- `verbose(_:metadata:file:function:line:)`
- `debug(_:metadata:file:function:line:)`
- `info(_:metadata:file:function:line:)`
- `warning(_:metadata:file:function:line:)`
- `error(_:metadata:file:function:line:)`

Config and level control:

- `config`
- `updateConfig(_:)`
- `setLevel(_:isEnabled:)`

Crash and diagnostics:

- `installCrashCapture()`
- `captureException(name:reason:metadata:)`
- `captureNetwork(request:response:data:error:)`

File management:

- `allLogFiles()`
- `exportLogArchive()`
- `clearLogFiles()`
- `flushSynchronously()`

Global shortcuts:

- `FKLogV(_:)`
- `FKLogD(_:)`
- `FKLogI(_:)`
- `FKLogW(_:)`
- `FKLogE(_:)`

Debug dump helpers:

- `dumpValue(_:level:file:function:line:)`
- `dumpEncodable(_:level:file:function:line:)`

## Best Practices

- Install crash capture as early as possible in app startup.
- Keep `release` logs minimal unless you have a strong observability need.
- Add metadata (`request_id`, `user_id`, `scene`) to make logs searchable.
- Use `updateConfig(_:)` for runtime toggles from debug settings pages.
- Tune `maxStorageSizeInBytes` based on app size and device disk strategy.
- Call `flushSynchronously()` before critical shutdown points when needed.

## Notes

- Console color output uses ANSI escape sequences and is mainly useful in debug consoles.
- In release builds, default configuration disables logging output and file persistence.
- Signal/exception capture improves diagnostics but cannot guarantee full recovery from fatal crashes.
- `exportLogArchive()` creates a merged temporary `.log` file that you can share through your app UI.

## License

`FKLogger` is part of `FKKit` and follows the repository license.
See the root [LICENSE](../../../LICENSE) file for details.
