import Foundation

/// Defines how pull-to-refresh and load-more interact when both are enabled.
public enum FKRefreshConcurrencyPolicy: Sendable, Equatable {
  /// Disallow concurrent work. New trigger is ignored while another action is running.
  case mutuallyExclusive
  /// Disallow concurrent work. New trigger is queued and runs automatically when current work ends.
  case queueing
  /// Allow pull-to-refresh and load-more to run at the same time.
  case parallel
}

/// Describes how an action was started.
public enum FKRefreshTriggerSource: Sendable, Equatable {
  /// Triggered by user gesture.
  case userInteraction
  /// Triggered by explicit API call.
  case programmatic
  /// Triggered by strategy logic (for example auto-fill first page).
  case automated
  /// Triggered from retry interaction.
  case retry
}

/// Describes auto-fill behavior for lists that do not fill the first screen.
public struct FKAutoFillPolicy: Sendable, Equatable {
  /// Enables automatic load-more while content is shorter than viewport.
  public var isEnabled: Bool
  /// Maximum automatic triggers per reset cycle to avoid infinite loops.
  public var maxTriggerCount: Int

  public init(isEnabled: Bool = false, maxTriggerCount: Int = 3) {
    self.isEnabled = isEnabled
    self.maxTriggerCount = max(0, maxTriggerCount)
  }

  public static let disabled = FKAutoFillPolicy()
}

/// Shared policy bag for one scroll view refresh pair.
public struct FKRefreshPolicy: Sendable, Equatable {
  /// Concurrency policy between pull-to-refresh and load-more.
  public var concurrency: FKRefreshConcurrencyPolicy
  /// Auto-fill behavior when data is shorter than one viewport.
  public var autoFill: FKAutoFillPolicy

  public init(
    concurrency: FKRefreshConcurrencyPolicy = .mutuallyExclusive,
    autoFill: FKAutoFillPolicy = .disabled
  ) {
    self.concurrency = concurrency
    self.autoFill = autoFill
  }

  public static let `default` = FKRefreshPolicy()
}

