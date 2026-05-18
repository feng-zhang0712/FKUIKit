import Foundation

/// Fires a callback when the sleep timer elapses.
@MainActor
public final class FKAudioSleepTimer {

  public enum Action: Sendable {
    case pause
    case stop
  }

  public private(set) var fireDate: Date?
  public var action: Action = .pause

  private var task: Task<Void, Never>?

  public init() {}

  public func schedule(fireDate: Date?, handler: @escaping () -> Void) {
    task?.cancel()
    self.fireDate = fireDate
    guard let fireDate else { return }

    task = Task {
      let interval = fireDate.timeIntervalSinceNow
      guard interval > 0 else {
        handler()
        return
      }
      try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
      guard !Task.isCancelled else { return }
      self.fireDate = nil
      handler()
    }
  }

  public func cancel() {
    task?.cancel()
    task = nil
    fireDate = nil
  }
}
