import Foundation

// MARK: - FKAsync (singleton)

/// Application-wide GCD helper: main-thread hops, global queues, serial/concurrent batches, and thread checks.
///
/// Use ``shared`` for default behavior, or create instances with a custom coordination queue for tests or isolated subsystems.
public final class FKAsync: FKAsyncMainExecuting, FKAsyncBackgroundExecuting, @unchecked Sendable {
  /// Shared instance with a default private coordination queue.
  public static let shared = FKAsync()

  private let coordinationQueue: DispatchQueue

  /// Creates an `FKAsync` hub with a dedicated serial queue used by batch helpers.
  ///
  /// - Parameter coordinationQueueLabel: Label for the internal serial queue (reverse-DNS).
  public init(coordinationQueueLabel: String = "com.fkkit.async.coordination") {
    coordinationQueue = FKAsyncQueues.serial(label: coordinationQueueLabel, qos: .utility)
  }

  // MARK: Thread state

  /// `true` when the caller runs on the main thread (same as `Thread.isMainThread`).
  public static var isMainThread: Bool {
    Thread.isMainThread
  }

  /// Returns whether the current execution context is the main thread.
  public nonisolated static func currentIsMainThread() -> Bool {
    Thread.isMainThread
  }

  // MARK: FKAsyncMainExecuting

  /// Always posts to the main queue asynchronously (never blocks; safe from any thread including main).
  public func asyncOnMain(_ work: @escaping @Sendable () -> Void) {
    DispatchQueue.main.async(execute: work)
  }

  /// Runs immediately when already on the main thread; otherwise schedules asynchronously on main.
  public func runOnMain(_ work: @escaping @Sendable () -> Void) {
    if Thread.isMainThread {
      work()
    } else {
      DispatchQueue.main.async(execute: work)
    }
  }

  /// Same as ``asyncOnMain`` — explicit alias for “defer to next main run loop turn”.
  public func asyncMainDeferred(_ work: @escaping @Sendable () -> Void) {
    asyncOnMain(work)
  }

  // MARK: FKAsyncBackgroundExecuting

  public func asyncGlobal(qos: DispatchQoS, execute work: @escaping @Sendable () -> Void) {
    FKAsyncQueues.global(qos: qos).async(execute: work)
  }

  /// Convenience: default global QoS.
  public func asyncBackground(execute work: @escaping @Sendable () -> Void) {
    asyncGlobal(qos: .default, execute: work)
  }

  // MARK: Serial batch

  /// Runs `operations` one after another on `queue`, then invokes `completion` on `notifyQueue`.
  public func runSerial(
    _ operations: [@Sendable () -> Void],
    on queue: DispatchQueue,
    notifyQueue: DispatchQueue = .main,
    completion: @escaping @Sendable () -> Void
  ) {
    queue.async {
      for op in operations {
        op()
      }
      notifyQueue.async(execute: completion)
    }
  }

  /// Runs `operations` sequentially on the instance ``coordinationQueue``.
  public func runSerialOnCoordinationQueue(
    _ operations: [@Sendable () -> Void],
    notifyQueue: DispatchQueue = .main,
    completion: @escaping @Sendable () -> Void
  ) {
    runSerial(operations, on: coordinationQueue, notifyQueue: notifyQueue, completion: completion)
  }

  // MARK: Concurrent batch

  /// Runs each operation on a global concurrent queue; `completion` fires on `notifyQueue` when all finish.
  public func runConcurrent(
    _ operations: [@Sendable () -> Void],
    qos: DispatchQoS = .default,
    notifyQueue: DispatchQueue = .main,
    completion: @escaping @Sendable () -> Void
  ) {
    let group = FKAsyncTaskGroup()
    let bg = FKAsyncQueues.global(qos: qos)
    for op in operations {
      group.enter()
      bg.async {
        op()
        group.leave()
      }
    }
    group.notify(queue: notifyQueue, execute: completion)
  }

  /// Exposes the internal coordination queue for advanced composition.
  public var underlyingCoordinationQueue: DispatchQueue { coordinationQueue }
}
