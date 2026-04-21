import Foundation

/// Runtime configuration for `FKLogger`.
public struct FKLoggerConfig: Sendable {
  /// Global enable switch for all logs.
  public var isEnabled: Bool
  /// Enabled levels that are allowed to be emitted.
  public var enabledLevels: Set<FKLogLevel>
  /// Prefix added to every line.
  public var prefix: String
  /// Includes timestamp section in output.
  public var includesTimestamp: Bool
  /// Includes source file in output.
  public var includesFileName: Bool
  /// Includes source function in output.
  public var includesFunctionName: Bool
  /// Includes source line in output.
  public var includesLineNumber: Bool
  /// Enables colorful ANSI output in debug logs.
  public var usesColorizedConsole: Bool
  /// Enables emoji markers by level.
  public var usesEmoji: Bool
  /// Persists logs into files.
  public var persistsToFile: Bool
  /// Maximum bytes for a single file before rotation.
  public var maxFileSizeInBytes: UInt64
  /// Maximum total bytes reserved for all log files.
  public var maxStorageSizeInBytes: UInt64
  /// Enables daily file split.
  public var rotatesDaily: Bool

  /// Creates a custom configuration.
  public init(
    isEnabled: Bool,
    enabledLevels: Set<FKLogLevel>,
    prefix: String,
    includesTimestamp: Bool,
    includesFileName: Bool,
    includesFunctionName: Bool,
    includesLineNumber: Bool,
    usesColorizedConsole: Bool,
    usesEmoji: Bool,
    persistsToFile: Bool,
    maxFileSizeInBytes: UInt64,
    maxStorageSizeInBytes: UInt64,
    rotatesDaily: Bool
  ) {
    self.isEnabled = isEnabled
    self.enabledLevels = enabledLevels
    self.prefix = prefix
    self.includesTimestamp = includesTimestamp
    self.includesFileName = includesFileName
    self.includesFunctionName = includesFunctionName
    self.includesLineNumber = includesLineNumber
    self.usesColorizedConsole = usesColorizedConsole
    self.usesEmoji = usesEmoji
    self.persistsToFile = persistsToFile
    self.maxFileSizeInBytes = maxFileSizeInBytes
    self.maxStorageSizeInBytes = maxStorageSizeInBytes
    self.rotatesDaily = rotatesDaily
  }

  /// Default config for debug builds.
  public static let debugDefault = FKLoggerConfig(
    isEnabled: true,
    enabledLevels: Set(FKLogLevel.allCases),
    prefix: "[FKLogger]",
    includesTimestamp: true,
    includesFileName: true,
    includesFunctionName: true,
    includesLineNumber: true,
    usesColorizedConsole: true,
    usesEmoji: true,
    persistsToFile: true,
    maxFileSizeInBytes: 1_048_576 * 5,
    maxStorageSizeInBytes: 1_048_576 * 100,
    rotatesDaily: true
  )

  /// Default config for release builds.
  public static let releaseDefault = FKLoggerConfig(
    isEnabled: false,
    enabledLevels: [.error],
    prefix: "[FKLogger]",
    includesTimestamp: true,
    includesFileName: true,
    includesFunctionName: true,
    includesLineNumber: true,
    usesColorizedConsole: false,
    usesEmoji: false,
    persistsToFile: false,
    maxFileSizeInBytes: 1_048_576 * 5,
    maxStorageSizeInBytes: 1_048_576 * 20,
    rotatesDaily: true
  )

  /// Build-aware default config.
  public static var `default`: FKLoggerConfig {
    #if DEBUG
    return .debugDefault
    #else
    return .releaseDefault
    #endif
  }
}
