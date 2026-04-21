# FKPermissions

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Supported Permissions](#supported-permissions)
- [Requirements](#requirements)
- [Installation](#installation)
- [Permission Status](#permission-status)
- [Basic Usage](#basic-usage)
- [Advanced Usage](#advanced-usage)
  - [Single Permission Request](#single-permission-request)
  - [Batch Permissions Request](#batch-permissions-request)
  - [Check Permission Status](#check-permission-status)
  - [Jump to System Settings](#jump-to-system-settings)
  - [Custom Permission Alert](#custom-permission-alert)
- [API Reference](#api-reference)
- [iOS Version Compatibility](#ios-version-compatibility)
- [Best Practices](#best-practices)
- [Privacy Info (Info.plist)](#privacy-info-infoplist)
- [Notes](#notes)
- [License](#license)

## Overview

`FKPermissions` is a pure native Swift permission manager built for large iOS codebases.
It provides a single, consistent API for checking and requesting system permissions, while keeping business code clean and framework-specific details isolated.

The component is protocol-oriented, supports both `async/await` and closure callbacks, and does not rely on any third-party libraries.

## Features

- Pure native implementation (`Foundation` / `UIKit` / Apple permission frameworks only)
- Protocol-oriented architecture for testability and extensibility
- Unified permission state model (`FKPermissionStatus`) across frameworks
- Unified request input/output models (`FKPermissionRequest`, `FKPermissionResult`)
- Single permission and batch permission requests
- Fast status check without triggering system prompts
- Optional pre-permission alert (`FKPermissionPrePrompt`)
- One-tap jump to app settings (`openAppSettings()`)
- Permission status observation via token-based API
- Main-thread-safe API design with `@MainActor`
- Built-in iOS version adaptation (for example photo access levels and temporary location accuracy)

## Supported Permissions

- Camera (`.camera`)
- Photo Library Read (`.photoLibraryRead`)
- Photo Library Add-Only (`.photoLibraryAddOnly`)
- Microphone (`.microphone`)
- Location When In Use (`.locationWhenInUse`)
- Location Always (`.locationAlways`)
- Location Temporary Full Accuracy (`.locationTemporaryFullAccuracy`)
- Notifications (`.notifications`)
- Bluetooth (`.bluetooth`)
- Calendar (`.calendar`)
- Reminders (`.reminders`)
- Media Library (`.mediaLibrary`)
- Speech Recognition (`.speechRecognition`)
- App Tracking Transparency (`.appTracking`)

## Requirements

- Swift 5.9+
- iOS 13.0+ for permission APIs
- No Objective-C dependency
- No third-party dependency

> Note: In this repository, `FKCoreKit` currently sets a higher platform floor in `Package.swift`. `FKPermissions` itself is implemented with iOS 13+ compatible APIs.

## Installation

`FKPermissions` is part of `FKCoreKit`.

### Swift Package Manager

Add `FKKit` to your package dependencies:

```swift
.package(url: "https://github.com/<your-org>/FKKit.git", from: "1.0.0")
```

Then import `FKCoreKit` where needed:

```swift
import FKCoreKit
```

## Permission Status

`FKPermissions` maps framework-specific statuses into a unified enum:

```swift
public enum FKPermissionStatus {
  case notDetermined
  case authorized
  case denied
  case restricted
  case limited
  case provisional
  case ephemeral
  case deviceDisabled
}
```

Use `FKPermissionResult.isGranted` to quickly evaluate whether the app can proceed.

## Basic Usage

Request a permission in one line:

```swift
let result = await FKPermissions.shared.request(.camera)
if result.isGranted {
  // Continue feature flow
} else {
  // Show fallback UI
}
```

## Advanced Usage

### Single Permission Request

```swift
let request = FKPermissionRequest(kind: .microphone)
let result = await FKPermissions.shared.request(request)
print(result.status)
```

Closure version:

```swift
FKPermissions.shared.request(FKPermissionRequest(kind: .microphone)) { result in
  print(result.status)
}
```

### Batch Permissions Request

```swift
let results = await FKPermissions.shared.request([
  .camera,
  .microphone,
  .photoLibraryRead
])

let cameraGranted = results[.camera]?.isGranted == true
```

Or with explicit request models:

```swift
let requests = [
  FKPermissionRequest(kind: .camera),
  FKPermissionRequest(kind: .notifications),
]
let resultMap = await FKPermissions.shared.request(requests)
```

### Check Permission Status

```swift
let status = await FKPermissions.shared.status(for: .notifications)
if status == .denied {
  // Present settings guidance
}
```

Closure version:

```swift
FKPermissions.shared.status(for: .notifications) { status in
  print(status)
}
```

### Jump to System Settings

```swift
if !FKPermissions.shared.openAppSettings() {
  // Handle failure to open settings URL
}
```

### Custom Permission Alert

Show a custom pre-permission explanation before the iOS system dialog:

```swift
let prePrompt = FKPermissionPrePrompt(
  title: "Camera Access Needed",
  message: "We use the camera to scan QR codes securely.",
  confirmTitle: "Continue",
  cancelTitle: "Not now"
)

let result = await FKPermissions.shared.request(
  .camera,
  prePrompt: prePrompt
)
```

Temporary full-accuracy location request with purpose key:

```swift
let result = await FKPermissions.shared.request(
  .locationTemporaryFullAccuracy,
  temporaryLocationPurposeKey: "RouteTrackingPurpose"
)
```

## API Reference

Core type:

- `FKPermissions.shared`

Status APIs:

- `status(for:) async -> FKPermissionStatus`
- `status(for:completion:)`

Request APIs:

- `request(_ request: FKPermissionRequest) async -> FKPermissionResult`
- `request(_ request: FKPermissionRequest, completion:)`
- `request(_ requests: [FKPermissionRequest]) async -> [FKPermissionKind: FKPermissionResult]`
- `request(_ requests: [FKPermissionRequest], completion:)`
- `request(_ kind: FKPermissionKind, ...) async -> FKPermissionResult`
- `request(_ kind: FKPermissionKind, ..., completion:)`
- `request(_ kinds: [FKPermissionKind]) async -> [FKPermissionKind: FKPermissionResult]`

Utilities:

- `openAppSettings() -> Bool`
- `observeStatusChanges(_:) -> FKPermissionObservationToken`

Models:

- `FKPermissionKind`
- `FKPermissionStatus`
- `FKPermissionRequest`
- `FKPermissionResult`
- `FKPermissionError`
- `FKPermissionPrePrompt`

## iOS Version Compatibility

- Base implementation targets iOS 13+
- Photo Library read/add-only split uses `PHAccessLevel` on iOS 14+
- Temporary full-accuracy location uses `requestTemporaryFullAccuracyAuthorization` on iOS 14+
- App Tracking Transparency uses `ATTrackingManager` on iOS 14+
- Notification statuses include `.provisional` and `.ephemeral` when available

## Best Practices

- Request permissions only when users are about to use the related feature (just-in-time request)
- Provide clear context with `FKPermissionPrePrompt` before the system alert
- Handle denied/restricted states gracefully with alternative UX
- Offer a settings shortcut after denial for better recovery
- Keep your `Info.plist` descriptions specific and user-friendly
- Retain `FKPermissionObservationToken` strongly while observing

## Privacy Info (Info.plist)

You **must** add corresponding usage descriptions before requesting permissions.

### Common Required Keys

- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`
- `NSPhotoLibraryAddUsageDescription`
- `NSMicrophoneUsageDescription`
- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysAndWhenInUseUsageDescription`
- `NSLocationTemporaryUsageDescriptionDictionary`
- `NSUserTrackingUsageDescription`
- `NSBluetoothAlwaysUsageDescription`
- `NSCalendarsUsageDescription`
- `NSRemindersUsageDescription`
- `NSAppleMusicUsageDescription`
- `NSSpeechRecognitionUsageDescription`
- `NSUserNotificationsUsageDescription` (optional in many cases, but recommended for clarity)

### Example

```xml
<key>NSCameraUsageDescription</key>
<string>We use your camera to scan QR codes.</string>
<key>NSMicrophoneUsageDescription</key>
<string>We use your microphone for voice messages.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>We use your location to show nearby services.</string>
<key>NSLocationTemporaryUsageDescriptionDictionary</key>
<dict>
  <key>RouteTrackingPurpose</key>
  <string>Precise location is used for accurate route guidance.</string>
</dict>
```

## Notes

- On non-iOS platforms, handlers gracefully return unavailable (`.deviceDisabled` / `.unavailable`).
- Batch requests are executed sequentially on the main actor for predictable UX.
- Some permissions depend on device capabilities and may return restricted/device-disabled states.

## License

This component is distributed under the same license as the `FKKit` repository.
