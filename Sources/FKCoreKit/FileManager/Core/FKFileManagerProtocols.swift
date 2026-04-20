import Foundation

/// Contract for file-system operations.
@MainActor
public protocol FKFileOperating: AnyObject {
  /// Resolves URL for a common sandbox directory.
  func directoryURL(_ directory: FKSandboxDirectory) -> URL
  /// Creates directory if needed.
  func createDirectory(at url: URL, intermediate: Bool) async throws
  /// Removes file or directory.
  func removeItem(at url: URL) async throws
  /// Moves file or directory.
  func moveItem(from sourceURL: URL, to destinationURL: URL) async throws
  /// Copies file or directory.
  func copyItem(from sourceURL: URL, to destinationURL: URL) async throws
  /// Renames file or directory in the same parent directory.
  func renameItem(at url: URL, newName: String) async throws -> URL
  /// Reads file info for target URL.
  func fileInfo(at url: URL) async throws -> FKFileInfo
  /// Returns whether item exists.
  func exists(at url: URL) -> Bool
}

/// Contract for serialization and content storage operations.
@MainActor
public protocol FKFileContentStoring: AnyObject {
  /// Writes text/data/json content to file.
  func writeContent(_ content: FKFileContent, to url: URL, atomically: Bool) async throws
  /// Writes codable model as JSON file.
  func writeModel<T: Codable & Sendable>(_ model: T, to url: URL) async throws
  /// Reads file data.
  func readData(from url: URL) async throws -> Data
  /// Reads file text with encoding.
  func readText(from url: URL, encoding: String.Encoding) async throws -> String
  /// Reads and decodes model from JSON file.
  func readModel<T: Codable & Sendable>(_ type: T.Type, from url: URL) async throws -> T
}

/// Contract for transfer operations.
@MainActor
public protocol FKTransferManaging: AnyObject {
  /// Starts a download task.
  @discardableResult
  func download(
    _ request: FKDownloadRequest,
    progress: (@Sendable (FKTransferProgress) -> Void)?,
    completion: (@Sendable (Result<FKDownloadResult, FKFileManagerError>) -> Void)?
  ) async throws -> Int

  /// Starts a multipart upload task.
  @discardableResult
  func upload(
    _ request: FKUploadRequest,
    progress: (@Sendable (FKTransferProgress) -> Void)?,
    completion: (@Sendable (Result<FKUploadResult, FKFileManagerError>) -> Void)?
  ) async throws -> Int

  /// Pauses one download task.
  func pauseDownload(taskID: Int) async
  /// Resumes one paused download task.
  func resumeDownload(taskID: Int) async
  /// Cancels one transfer task.
  func cancel(taskID: Int) async
  /// Cancels all running transfer tasks.
  func cancelAll() async
  /// Returns persisted transfer snapshots.
  func persistedTransfers() async -> [FKPersistedTransfer]
}
