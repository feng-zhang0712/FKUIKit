import Foundation

/// Clock abstraction used by refresh internals for deterministic tests.
public protocol FKRefreshClock: Sendable {
  /// Returns current absolute date.
  func now() -> Date
}

/// Default production clock.
public struct FKSystemRefreshClock: FKRefreshClock {
  public init() {}

  public func now() -> Date {
    Date()
  }
}

