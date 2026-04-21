import Foundation

public extension DispatchQueue {
  /// Submits `work` asynchronously; identical to `async(execute:)` but named for call-site clarity in MVVM layers.
  @inline(__always)
  func fk_async(_ work: @escaping @Sendable () -> Void) {
    async(execute: work)
  }

  /// Submits `work` after `delay` seconds.
  @inline(__always)
  func fk_asyncAfter(delay: TimeInterval, execute work: @escaping @Sendable () -> Void) {
    asyncAfter(deadline: .now() + max(0, delay), execute: work)
  }
}

public extension DispatchQueue {
  /// Executes `work` on the main queue asynchronously from any thread.
  static func fk_asyncOnMain(_ work: @escaping @Sendable () -> Void) {
    DispatchQueue.main.async(execute: work)
  }

  /// Runs `work` on the main thread immediately if already there; otherwise dispatches asynchronously.
  static func fk_runOnMain(_ work: @escaping @Sendable () -> Void) {
    if Thread.isMainThread {
      work()
    } else {
      DispatchQueue.main.async(execute: work)
    }
  }
}
