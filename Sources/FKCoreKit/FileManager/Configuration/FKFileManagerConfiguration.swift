import Foundation

/// Runtime configuration for FKFileManager.
public struct FKFileManagerConfiguration: Sendable, Equatable {
  /// Unique identifier used for URLSession background download container.
  public var backgroundSessionIdentifier: String
  /// Minimum required bytes before starting large operations.
  public var minimumRequiredDiskSpace: Int64
  /// UserDefaults key used for persisted transfer snapshots.
  public var persistenceKey: String
  /// Root folder under Caches used by FKFileManager for temporary artifacts.
  public var workingDirectoryName: String

  public init(
    backgroundSessionIdentifier: String = "com.fkkit.filemanager.background",
    minimumRequiredDiskSpace: Int64 = 50 * 1024 * 1024,
    persistenceKey: String = "com.fkkit.filemanager.transfers",
    workingDirectoryName: String = "FKFileManager"
  ) {
    self.backgroundSessionIdentifier = backgroundSessionIdentifier
    self.minimumRequiredDiskSpace = minimumRequiredDiskSpace
    self.persistenceKey = persistenceKey
    self.workingDirectoryName = workingDirectoryName
  }
}
