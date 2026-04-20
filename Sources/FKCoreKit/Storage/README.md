# FKStorage

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Architecture](#architecture)
- [API Reference](#api-reference)
- [Basic Usage](#basic-usage)
- [Advanced Usage](#advanced-usage)
  - [UserDefaults Storage](#userdefaults-storage)
  - [Keychain Secure Storage](#keychain-secure-storage)
  - [File Manager \& Disk Cache](#file-manager--disk-cache)
  - [Codable Model Persistence](#codable-model-persistence)
  - [Auto Expire \& Cache Clean](#auto-expire--cache-clean)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)
- [License](#license)

---

## Overview

`FKStorage` is the native persistence module under `FKCoreKit`. It is built on **Foundation only**—`UserDefaults`, **Keychain Services**, `FileManager`, and **JSON (`Codable`)** encoding—with **zero third-party dependencies**.

It follows **protocol-oriented** design: a small set of protocols (`FKStorageBackend`, `FKCodableStorage`) is implemented by four pluggable backends. All public implementations are **thread-safe** (serial queues or locks) and expose optional **async/await** wrappers for work you prefer not to run on the calling thread.

Typical uses:

- Lightweight preferences and feature flags (`FKUserDefaultsStorage`)
- Secrets and tokens (`FKKeychainStorage`)
- Larger or structured offline data under the app sandbox (`FKFileStorage`)
- Fast, ephemeral caches (`FKMemoryStorage`)

---

## Features

- Pure Swift, system APIs only: `UserDefaults`, Keychain, `FileManager`, `Codable` (JSON)
- Protocol-first API: `FKCodableStorage` + `FKStorageBackend` for CRUD, bulk clear, existence checks, and key listing
- **Generic `Codable` values** (`String`, `Bool`, `Data`, and custom models) with unified encode/decode
- **TTL (time-to-live)** on stored values via `ExpiringRecord`; `purgeExpired()` for cleanup
- **Centralized keys** via `FKStorageKey` / `FKStorageStringKey` to avoid string collisions
- **UserDefaults namespacing**: automatic key prefix so `removeAll()` / `allKeys()` never wipe unrelated defaults
- **File storage**: Application Support subdirectory, per-key blob files, SHA256-based safe filenames (`CryptoKit`), `index.json` for key enumeration
- **Keychain**: generic-password items scoped by `service` + `account` (logical key)
- **Synchronized + async** APIs (`StorageAsync` extensions)
- Unified errors: `FKStorageError`

---

## Requirements

- **iOS** 13.0+ (API design); the **Swift Package** in this repository currently declares **iOS 15+** in `Package.swift`
- **macOS** 10.15+ (for `swift build` on Apple platforms; `Package.swift` includes `.macOS(.v10_15)`)
- **Swift** 5.9+ / **Swift 6** language mode (as configured by the package)
- **Xcode** 15+ recommended

---

## Installation

### Swift Package Manager

Add the `FKKit` package to your app and link the **`FKCoreKit`** product.

```swift
import FKCoreKit
```

### Source layout

Module sources live under:

`Sources/FKCoreKit/Storage`

No additional SPM dependencies are required.

---

## Architecture

Directory layout:

| Folder | Role |
|--------|------|
| `Core` | Protocols (`FKStorageBackend`, `FKCodableStorage`), key types (`FKStorageKey`), async extensions |
| `Model` | `FKStorageError`, internal `ExpiringRecord` (payload + optional expiry) |
| `Tool` | Shared `JSONEncoder` / `JSONDecoder`, filesystem-safe key hashing for file blobs |
| `Implementation` | `FKUserDefaultsStorage`, `FKKeychainStorage`, `FKFileStorage`, `FKMemoryStorage` |

**Data flow**

1. Callers pass a **logical key** (often `FKStorageKey.fullKey`).
2. Values are JSON-encoded with `StorageCodec`; when TTL is set, wrapped in `ExpiringRecord` and encoded again.
3. Backends persist `Data` (UserDefaults / Keychain / file) or hold raw bytes (memory).
4. Reads decode `ExpiringRecord` first (where used), reject expired entries, then decode the user type; decode failures surface as `FKStorageError.decodingFailed` (not a crash).

**Threading**

- `FKUserDefaultsStorage`, `FKKeychainStorage`, and `FKFileStorage` serialize access on private `DispatchQueue`s.
- `FKMemoryStorage` uses `NSLock`.
- Async methods schedule work via `Task` and await completion.

---

## API Reference

### Protocols

| Protocol | Purpose |
|----------|---------|
| `FKStorageBackend` | `remove(key:)`, `removeAll()`, `allKeys()`, `exists(key:)`, `purgeExpired()` |
| `FKCodableStorage` | `FKStorageBackend` + `set(_:key:ttl:)`, `value(key:as:)`; convenience `set(_:key:)` (no TTL) |

### Concrete types

| Type | Description |
|------|-------------|
| `FKUserDefaultsStorage` | `init(suiteName:keyPrefix:)` — default prefix `fk.storage.`; only keys with that prefix are enumerated or cleared |
| `FKKeychainStorage` | `init(service:)` — one Keychain service string for all items |
| `FKFileStorage` | `init(directoryName:fileManager:)` — Application Support / `directoryName` / blobs + `index.json` |
| `FKMemoryStorage` | `init()` — in-memory only, process lifetime |

### Keys

| Type | Usage |
|------|--------|
| `FKStorageKey` | `rawValue` + `namespace` → `fullKey` |
| `FKStorageStringKey` | `init(namespace:rawValue:)` |

### Errors

`FKStorageError`: `notFound`, `encodingFailed`, `decodingFailed`, `keychainFailed`, `fileSystemFailed`, `invalidKey`, `unsupported` — conforms to `LocalizedError`.

### Async

Extensions on `FKCodableStorage` and `FKStorageBackend` add `async` / `async throws` overloads for the same operations as the synchronous API.

---

## Basic Usage

The following examples compile against the public API. Adjust keys and types for your app.

```swift
import Foundation
import FKCoreKit

// 1) Choose a backend
let prefs = FKUserDefaultsStorage()
let secrets = FKKeychainStorage(service: "com.example.myapp.storage")
let disk = try FKFileStorage(directoryName: "MyAppCache")
let memory = FKMemoryStorage()

// 2) Centralize keys
enum AppKey: String, FKStorageKey {
  case userId
  case refreshToken
  var namespace: String { "com.example.myapp" }
}

// 3) Write / read (sync)
try prefs.set("guest", key: AppKey.userId.fullKey)
let name = try prefs.value(key: AppKey.userId.fullKey, as: String.self)

// 4) Async (e.g. from SwiftUI / async context)
Task {
  try await prefs.set("signed-in", key: AppKey.userId.fullKey)
  let id = try await prefs.value(key: AppKey.userId.fullKey, as: String.self)
  print(id)
}
```

---

## Advanced Usage

### UserDefaults Storage

- Use **`keyPrefix`** (default `fk.storage.`) so `removeAll()`, `allKeys()`, and `purgeExpired()` only affect keys owned by this storage instance—not every key in the suite.
- Pass **`suiteName`** for App Groups or isolated suites; invalid suite names trigger a runtime `fatalError` (validate suite names in app configuration).

```swift
let groupDefaults = FKUserDefaultsStorage(
  suiteName: "group.com.example.shared",
  keyPrefix: "fk.myfeature."
)

try groupDefaults.set(true, key: "onboarding.completed")
let done = try groupDefaults.value(key: "onboarding.completed", as: Bool.self)

// Clear only keys with prefix `fk.myfeature.`
try groupDefaults.removeAll()
```

### Keychain Secure Storage

- Items use **generic password** with `kSecAttrService` = `service` and `kSecAttrAccount` = your logical key.
- Stored bytes are still **JSON** (`ExpiringRecord` + payload); Keychain provides OS-level protection, not custom app-side encryption.
- `removeAll()` deletes all generic-password items for the given `service`.

```swift
struct Session: Codable, Sendable {
  let accessToken: String
  let expiresIn: TimeInterval
}

let keychain = FKKeychainStorage(service: Bundle.main.bundleIdentifier! + ".secrets")
let key = AppKey.refreshToken.fullKey

try keychain.set(Session(accessToken: "…", expiresIn: 3600), key: key)
let session = try keychain.value(key: key, as: Session.self)
```

### File Manager & Disk Cache

- Root: **`Application Support`** / `directoryName` (default `FKStorage`).
- Each value is a file named with a **SHA256** hash of the logical key (via `CryptoKit`) plus `.fkstore`.
- **`index.json`** lists logical keys for `allKeys()`; `directoryURL` exposes the folder for debugging.

```swift
let files = try FKFileStorage(directoryName: "ArticleCache")
try files.set(["a", "b"], key: "tags.list")

let root = files.directoryURL
print("FKStorage files under:", root.path)

try files.remove(key: "tags.list")
```

### Codable Model Persistence

- Types must be **`Codable` and `Sendable`** to match the generic constraints.
- Decoding uses a shared `JSONDecoder`; **unknown keys** or schema drift yield `FKStorageError.decodingFailed`—handle at the call site.

```swift
struct UserProfile: Codable, Sendable {
  var id: Int
  var displayName: String
}

let storage: any FKCodableStorage = try FKFileStorage(directoryName: "Profiles")

let profile = UserProfile(id: 1, displayName: "Ada")
try storage.set(profile, key: "user.main")

let loaded = try storage.value(key: "user.main", as: UserProfile.self)
```

### Auto Expire & Cache Clean

- Pass **`ttl`** in **seconds** from the call to `set(_:key:ttl:)`. Expiry is checked on read and in `purgeExpired()`.
- Expired entries behave like **missing** (`FKStorageError.notFound` on read); `exists` returns `false` and may delete the entry where implemented.

```swift
// Cache for 10 minutes
try memory.set(["news"], key: "feed.top", ttl: 600)

// Periodic cleanup (e.g. on app launch or background task)
try prefs.purgeExpired()
try disk.purgeExpired()
try keychain.purgeExpired()
```

---

## Error Handling

`FKStorage` maps failures to **`FKStorageError`**:

| Case | Typical cause |
|------|----------------|
| `notFound` | No value, or TTL expired |
| `encodingFailed` | `Codable` encoding failed |
| `decodingFailed` | Invalid JSON or type mismatch |
| `keychainFailed` | `SecItem*` returned non-success status |
| `fileSystemFailed` | I/O or `FileManager` error |
| `invalidKey` | Reserved for validators / future use |
| `unsupported` | Optional placeholder |

Example:

```swift
do {
  let token = try secrets.value(key: AppKey.refreshToken.fullKey, as: String.self)
  print(token)
} catch let error as FKStorageError {
  switch error {
  case .notFound:
    break // prompt login
  case .decodingFailed(let underlying):
    print("Schema mismatch:", underlying)
  case .keychainFailed(let status):
    print("Keychain status:", status)
  default:
    print(error.localizedDescription)
  }
} catch {
  print(error)
}
```

---

## Best Practices

- **Define keys in one place** using `FKStorageKey` or `FKStorageStringKey`; avoid scattering raw strings.
- **Secrets → Keychain**; **small flags → UserDefaults**; **larger blobs → File**; **session cache → Memory**.
- Use **separate `FKUserDefaultsStorage` instances** with different `keyPrefix` values if multiple subsystems share the same `UserDefaults` suite.
- Call **`purgeExpired()`** on a schedule appropriate for your app (launch, foreground, low-memory warnings for memory cache).
- **Do not store huge graphs in UserDefaults**; prefer `FKFileStorage` or a dedicated database if you outgrow JSON files.
- For **App Group** data, use `FKUserDefaultsStorage(suiteName:)` or file paths under the shared container—consistent with Apple sandbox rules.
- When using **async** APIs, remember they still perform the same I/O; use them to avoid blocking the main actor during heavy work, not as a substitute for choosing the right backend.

---

## License

This project is released under the **MIT License**. See the repository root `LICENSE` file for full text.
