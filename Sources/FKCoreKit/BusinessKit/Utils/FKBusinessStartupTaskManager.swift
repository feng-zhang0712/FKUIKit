import Foundation

/// Default implementation of ``FKBusinessStartupTaskManaging``.
public final class FKBusinessStartupTaskManager: FKBusinessStartupTaskManaging, @unchecked Sendable {
  /// Serial queue that protects task registry and orchestration.
  private let queue = DispatchQueue(label: "com.fkkit.business.startup", qos: .utility)
  /// Registered startup tasks keyed by task identifier.
  private var tasks: [String: FKStartupTask] = [:]

  /// Creates startup task manager.
  public init() {}

  /// Registers or replaces startup task.
  ///
  /// - Parameter task: Startup task descriptor.
  public func register(_ task: FKStartupTask) {
    queue.async { [weak self] in
      self?.tasks[task.id] = task
    }
  }

  /// Async wrapper that executes all registered startup tasks.
  @available(iOS 13.0, *)
  public func runAll() async {
    await withCheckedContinuation { cont in
      runAll(completion: cont.resume)
    }
  }

  /// Executes all registered startup tasks with priority and delay.
  ///
  /// - Parameter completion: Completion callback after all tasks finish.
  public func runAll(completion: (@Sendable () -> Void)?) {
    if #available(iOS 13.0, *) {
      queue.async { [weak self] in
        guard let self else { completion?(); return }
        let current = Array(self.tasks.values).sorted {
          if $0.priority != $1.priority { return $0.priority < $1.priority }
          return $0.delay < $1.delay
        }
        Task(priority: .utility) {
          for task in current {
            if task.delay > 0 {
              try? await Task.sleep(nanoseconds: UInt64(task.delay * 1_000_000_000))
            }
            await task.work()
          }
          completion?()
        }
      }
    } else {
      completion?()
    }
  }
}

