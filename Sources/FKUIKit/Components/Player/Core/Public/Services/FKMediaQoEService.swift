import Foundation

/// Aggregated QoE metrics derived from analytics plugins.
public struct FKMediaQoESnapshot: Sendable, Equatable {
  public var stallCount: Int
  public var errorCount: Int
  public var totalPlaySeconds: TimeInterval
  public var lastError: FKMediaError?

  public init(
    stallCount: Int = 0,
    errorCount: Int = 0,
    totalPlaySeconds: TimeInterval = 0,
    lastError: FKMediaError? = nil
  ) {
    self.stallCount = stallCount
    self.errorCount = errorCount
    self.totalPlaySeconds = totalPlaySeconds
    self.lastError = lastError
  }
}

/// Collects playback QoE metrics from coordinator analytics events.
public final class FKMediaQoEService: FKMediaAnalyticsPlugin, @unchecked Sendable {

  private let lock = NSLock()
  private var snapshot = FKMediaQoESnapshot()
  private var playStartedAt: Date?

  public init() {}

  public func currentSnapshot() -> FKMediaQoESnapshot {
    lock.lock()
    defer { lock.unlock() }
    return snapshot
  }

  public func track(event: FKMediaAnalyticsEvent) {
    lock.lock()
    defer { lock.unlock() }
    switch event {
    case .play:
      playStartedAt = Date()
    case .pause, .complete:
      accumulatePlayTime()
    case .stall:
      snapshot.stallCount += 1
    case let .error(_, error):
      snapshot.errorCount += 1
      snapshot.lastError = error
    default:
      break
    }
  }

  public func reset() {
    lock.lock()
    defer { lock.unlock() }
    snapshot = FKMediaQoESnapshot()
    playStartedAt = nil
  }

  private func accumulatePlayTime() {
    guard let playStartedAt else { return }
    snapshot.totalPlaySeconds += Date().timeIntervalSince(playStartedAt)
    self.playStartedAt = nil
  }
}
