# FKAsync

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Architecture](#architecture)
- [Basic Usage](#basic-usage)
- [Advanced Usage](#advanced-usage)
  - [Main Thread Safety](#main-thread-safety)
  - [Delay & Cancelable Tasks](#delay--cancelable-tasks)
  - [Debounce](#debounce)
  - [Throttle](#throttle)
  - [Dispatch Group](#dispatch-group)
  - [Serial/Concurrent Tasks](#serialconcurrent-tasks)
- [API Reference](#api-reference)
- [Best Practices](#best-practices)
- [Thread Safety Notes](#thread-safety-notes)
- [License](#license)

## Overview

`FKAsync` is the native thread and asynchronous scheduling module under `FKCoreKit`.
It is implemented with **system GCD APIs only** (`DispatchQueue`, `DispatchGroup`, `DispatchWorkItem`) and has **zero third-party dependencies**.

The module is designed for medium and large iOS projects with a simple, protocol-oriented API surface:

- Safe main-thread dispatch for UI updates
- Global/background queue helpers
- Cancelable delayed work
- Debounce and throttle utilities for high-frequency events
- Dispatch-group based task coordination
- Serial and concurrent executors
- Reusable queue extensions for one-line scheduling

---

## Features

- Pure Swift + GCD implementation (no Objective-C wrappers, no third-party libraries)
- Protocol-oriented abstractions:
  - `FKAsyncMainExecuting`
  - `FKAsyncBackgroundExecuting`
  - `FKAsyncCancellable`
  - `FKAsyncDebouncing`
  - `FKAsyncThrottling`
- Main-thread safety:
  - `runOnMain(_:)` runs immediately on main, otherwise dispatches to main async
  - `asyncOnMain(_:)` / `asyncMainDeferred(_:)` always dispatch asynchronously
- Queue factory helpers: global, serial, concurrent
- Cancelable delayed task object: `FKCancellableDelayedWork`
- Debouncer: `FKDebouncer`
- Throttler (leading-edge): `FKThrottler`
- Dispatch group wrapper: `FKAsyncTaskGroup`
- Dedicated executors:
  - `FKAsyncSerialExecutor`
  - `FKAsyncConcurrentExecutor`
- Batch orchestration:
  - `runSerial(...)`
  - `runConcurrent(...)`
- DispatchQueue extensions for concise MVVM-friendly call sites

---

## Requirements

- iOS 13.0+ (API design compatibility)
- Swift 5.9+
- Xcode 15+

> Note: this repository currently declares `iOS 15+` in `Package.swift`.

---

## Installation

Integrate `FKKit` via Swift Package Manager and import:

```swift
import FKCoreKit
```

Module source location:

`Sources/FKCoreKit/Async`

---

## Architecture

Module layout:

- `Core`
  - `AsyncProtocols.swift`: protocol contracts for dispatch, cancellation, debounce/throttle
  - `FKAsync.swift`: singleton-style orchestration hub (`FKAsync.shared`)
- `Queue`
  - `AsyncQueues.swift`: queue factory helpers (`global`, `serial`, `concurrent`)
- `Task`
  - `CancellableWork.swift`: cancelable delayed work wrapper
  - `AsyncTaskGroup.swift`: `DispatchGroup` wrapper
- `DebounceThrottle`
  - `Debouncer.swift`: idle-window coalescing
  - `Throttler.swift`: fixed-rate limiting
- `Executor`
  - `AsyncExecutors.swift`: serial and concurrent executors
- `Extension`
  - `DispatchQueue+FKAsync.swift`: utility extensions for shorter scheduling calls

Design principles:

- **Protocol-oriented**: easier to mock and unit-test
- **Thread-safe** internals using serial queues and `NSLock`
- **Small, composable objects** (queue helpers, debouncer, throttler, group, executors)
- **No business coupling**: reusable in MVVM, UIKit, and service layers

---

## Basic Usage

```swift
import FKCoreKit

// Global shared async hub
let async = FKAsync.shared

// 1) Main-thread safe execution
async.runOnMain {
  // UI-safe update
}

// 2) Background execution (global queue)
async.asyncGlobal(qos: .userInitiated) {
  // CPU / I/O work
}

// 3) Thread state check
if FKAsync.isMainThread {
  // Already on main thread
}
```

---

## Advanced Usage

### Main Thread Safety

Use `runOnMain` when you want immediate execution if already on main, and fallback dispatch otherwise:

```swift
func renderViewModel() {
  FKAsync.shared.runOnMain {
    // Safe for UI regardless of caller thread
    // e.g. self.tableView.reloadData()
  }
}
```

Use `asyncOnMain` / `asyncMainDeferred` when you always want to defer execution to the next main queue turn:

```swift
FKAsync.shared.asyncOnMain {
  // Always async to main
}
```

### Delay & Cancelable Tasks

Use `FKCancellableDelayedWork` for delayed operations that may be invalidated (search request, tooltip, retry):

```swift
final class SearchViewModel {
  private let delayed = FKCancellableDelayedWork(queue: .main)

  func scheduleHint() {
    delayed.schedule(after: 0.8) { [weak self] in
      self?.showHint()
    }
  }

  func cancelHint() {
    delayed.cancel()
  }

  private func showHint() {}
}
```

### Debounce

Use `FKDebouncer` to merge frequent events and execute once after inactivity:

```swift
final class SearchInputHandler {
  private let debouncer = FKDebouncer(interval: 0.35, queue: .main)

  func didChangeText(_ text: String) {
    debouncer.signal { [weak self] in
      self?.performSearch(keyword: text)
    }
  }

  private func performSearch(keyword: String) {}
}
```

### Throttle

Use `FKThrottler` to limit high-frequency actions (scroll callbacks, analytics, lightweight polling):

```swift
final class ScrollReporter {
  private let throttler = FKThrottler(interval: 0.5, queue: .main)

  func scrollViewDidScroll() {
    throttler.throttle { [weak self] in
      self?.sendVisibleRange()
    }
  }

  private func sendVisibleRange() {}
}
```

### Dispatch Group

Use `FKAsyncTaskGroup` when multiple async branches must finish before a single callback:

```swift
let group = FKAsyncTaskGroup()

group.enter()
DispatchQueue.global().async {
  // Task A
  group.leave()
}

group.enter()
DispatchQueue.global().async {
  // Task B
  group.leave()
}

group.notify(queue: .main) {
  // Runs after A + B complete
}
```

### Serial/Concurrent Tasks

Batch orchestration with `FKAsync`:

```swift
let async = FKAsync.shared

// Serial: strict ordering
async.runSerial(
  [
    { print("Step 1") },
    { print("Step 2") },
    { print("Step 3") }
  ],
  on: FKAsyncQueues.serial(label: "com.example.pipeline"),
  notifyQueue: .main
) {
  print("Serial pipeline done")
}

// Concurrent: run in parallel, notify once
async.runConcurrent(
  [
    { print("Load profile") },
    { print("Load settings") },
    { print("Load feed") }
  ],
  qos: .userInitiated,
  notifyQueue: .main
) {
  print("Concurrent batch done")
}
```

Dedicated executors:

```swift
let serialExecutor = FKAsyncSerialExecutor(label: "com.example.serial")
serialExecutor.async { /* ordered task */ }

let concurrentExecutor = FKAsyncConcurrentExecutor(label: "com.example.concurrent")
concurrentExecutor.async { /* parallel task */ }
```

---

## API Reference

### Core Hub

- `FKAsync.shared`
- `FKAsync.isMainThread`
- `FKAsync.currentIsMainThread()`
- `asyncOnMain(_:)`
- `runOnMain(_:)`
- `asyncMainDeferred(_:)`
- `asyncGlobal(qos:execute:)`
- `asyncBackground(execute:)`
- `runSerial(_:on:notifyQueue:completion:)`
- `runSerialOnCoordinationQueue(_:notifyQueue:completion:)`
- `runConcurrent(_:qos:notifyQueue:completion:)`

### Queue Helpers

- `FKAsyncQueues.global(qos:)`
- `FKAsyncQueues.serial(label:qos:)`
- `FKAsyncQueues.concurrent(label:qos:)`

### Cancelable / Timing

- `FKCancellableDelayedWork.schedule(after:execute:)`
- `FKCancellableDelayedWork.cancel()`
- `FKDebouncer.signal(_:)`
- `FKDebouncer.cancelPending()`
- `FKThrottler.throttle(_:)`
- `FKThrottler.reset()`

### Task Coordination

- `FKAsyncTaskGroup.enter()`
- `FKAsyncTaskGroup.leave()`
- `FKAsyncTaskGroup.notify(queue:execute:)`
- `FKAsyncTaskGroup.wait(timeout:)`

### Executors

- `FKAsyncSerialExecutor.async(execute:)`
- `FKAsyncSerialExecutor.asyncAfter(deadline:execute:)`
- `FKAsyncConcurrentExecutor.async(execute:)`
- `FKAsyncConcurrentExecutor.asyncAfter(deadline:execute:)`

### DispatchQueue Extensions

- `queue.fk_async { ... }`
- `queue.fk_asyncAfter(delay:execute:)`
- `DispatchQueue.fk_asyncOnMain { ... }`
- `DispatchQueue.fk_runOnMain { ... }`

---

## Best Practices

- Prefer `runOnMain` for UI-safe updates from unknown threads.
- Use `asyncOnMain` when you intentionally defer work to the next run-loop cycle.
- Keep heavy CPU and blocking I/O off the main queue (`asyncGlobal`, custom serial queues).
- Debounce user input (search fields), throttle telemetry/scroll callbacks.
- For delayed work, keep the `FKCancellableDelayedWork` instance as a property and call `cancel()` in lifecycle cleanup.
- In `DispatchGroup` flows, always pair every `enter()` with exactly one `leave()` (including failure branches).
- Use explicit queue labels (`com.company.feature.task`) for diagnostics and profiling.

---

## Thread Safety Notes

- `FKAsync` uses immutable queue references and GCD scheduling; no blocking `sync` to main queue is used.
- `FKCancellableDelayedWork`, `FKDebouncer`, and `FKThrottler` protect mutable state with `NSLock`.
- `FKAsyncTaskGroup` is a thin wrapper around thread-safe `DispatchGroup`.
- `FKAsyncSerialExecutor` guarantees execution order on its private serial queue.
- `FKAsyncConcurrentExecutor` allows parallel execution; ordering is not guaranteed.
- `@unchecked Sendable` is used on reference types that enforce thread safety through internal synchronization.

---

## License

This project is released under the MIT License. See the repository root `LICENSE` file for details.
