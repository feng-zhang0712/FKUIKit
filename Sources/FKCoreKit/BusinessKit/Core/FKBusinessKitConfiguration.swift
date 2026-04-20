import Foundation

/// Global configuration for FKBusinessKit.
public struct FKBusinessKitConfiguration: Sendable, Equatable {
  /// App distribution channel (for example `AppStore`, `TestFlight`, `Enterprise`, `Web`).
  public var channel: String

  /// A custom build environment label.
  public var environment: FKBusinessEnvironment

  /// Default language used when no user selection is stored.
  public var defaultLanguageCode: String

  /// Analytics flush interval in seconds.
  public var analyticsFlushInterval: TimeInterval

  /// Analytics max batch size per upload.
  public var analyticsMaxBatchSize: Int

  /// Maximum number of retry attempts for a single batch.
  public var analyticsMaxRetryCount: Int

  /// Creates a configuration with sensible defaults.
  public init(
    channel: String = "AppStore",
    environment: FKBusinessEnvironment = .current,
    defaultLanguageCode: String = "en",
    analyticsFlushInterval: TimeInterval = 10,
    analyticsMaxBatchSize: Int = 20,
    analyticsMaxRetryCount: Int = 3
  ) {
    self.channel = channel
    self.environment = environment
    self.defaultLanguageCode = defaultLanguageCode
    self.analyticsFlushInterval = analyticsFlushInterval
    self.analyticsMaxBatchSize = analyticsMaxBatchSize
    self.analyticsMaxRetryCount = analyticsMaxRetryCount
  }
}

/// App runtime environment.
public enum FKBusinessEnvironment: String, Sendable, Equatable {
  /// Debug build environment, typically used for internal testing.
  case debug

  /// Release build environment, typically used for production distribution.
  case release

  /// Best-effort environment detection based on build flags.
  public static var current: FKBusinessEnvironment {
    #if DEBUG
    return .debug
    #else
    return .release
    #endif
  }
}

