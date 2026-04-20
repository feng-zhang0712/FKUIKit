import Foundation

/// Unified file, download, and upload entry point for FKCoreKit.
@MainActor
public final class FKFileManager: FKFileOperating, FKFileContentStoring, FKTransferManaging {
  /// Shared singleton for global usage.
  public static let shared = FKFileManager()

  private let configuration: FKFileManagerConfiguration
  private let storageService: FKFileStorageCore
  private let downloadService: FKDownloadService
  private let uploadService: FKUploadServiceCore

  /// Creates manager with custom configuration.
  public init(configuration: FKFileManagerConfiguration = .init()) {
    self.configuration = configuration
    let storage = FKFileStorageCore()
    self.storageService = storage
    self.downloadService = FKDownloadService(configuration: configuration, storageService: storage)
    self.uploadService = FKUploadServiceCore(configuration: configuration)
  }

  // MARK: - Sandbox

  public func directoryURL(_ directory: FKSandboxDirectory) -> URL {
    storageService.directoryURL(directory)
  }

  // MARK: - File operations

  public func createDirectory(at url: URL, intermediate: Bool = true) async throws {
    try await storageService.createDirectory(at: url, intermediate: intermediate)
  }

  public func removeItem(at url: URL) async throws {
    try await storageService.removeItem(at: url)
  }

  public func moveItem(from sourceURL: URL, to destinationURL: URL) async throws {
    try await storageService.moveItem(from: sourceURL, to: destinationURL)
  }

  public func copyItem(from sourceURL: URL, to destinationURL: URL) async throws {
    try await storageService.copyItem(from: sourceURL, to: destinationURL)
  }

  public func renameItem(at url: URL, newName: String) async throws -> URL {
    try await storageService.renameItem(at: url, newName: newName)
  }

  public func fileInfo(at url: URL) async throws -> FKFileInfo {
    try await storageService.fileInfo(at: url)
  }

  public func exists(at url: URL) -> Bool {
    storageService.exists(at: url)
  }

  // MARK: - Content read / write

  public func writeContent(_ content: FKFileContent, to url: URL, atomically: Bool = true) async throws {
    try await storageService.writeContent(content, to: url, atomically: atomically)
  }

  public func writeModel<T: Codable & Sendable>(_ model: T, to url: URL) async throws {
    try await storageService.writeModel(model, to: url)
  }

  public func readData(from url: URL) async throws -> Data {
    try await storageService.readData(from: url)
  }

  public func readText(from url: URL, encoding: String.Encoding = .utf8) async throws -> String {
    try await storageService.readText(from: url, encoding: encoding)
  }

  public func readModel<T: Codable & Sendable>(_ type: T.Type, from url: URL) async throws -> T {
    try await storageService.readModel(type, from: url)
  }

  // MARK: - Directory utilities

  /// Calculates directory size in bytes.
  public func directorySize(at directoryURL: URL) async throws -> Int64 {
    try await storageService.sizeOfDirectory(at: directoryURL)
  }

  /// Clears all files in caches directory.
  public func clearCaches() async throws {
    try await storageService.clearDirectory(at: directoryURL(.caches))
  }

  /// Clears all files in temporary directory.
  public func clearTemporaryFiles() async throws {
    try await storageService.clearDirectory(at: directoryURL(.temporary))
  }

  /// Traverses files under a directory.
  public func enumerateFiles(at directoryURL: URL, options: FKFileTraversalOptions = .init()) async throws -> [URL] {
    try await storageService.enumerateFiles(at: directoryURL, options: options)
  }

  /// Compresses an item to a ZIP archive.
  public func zipItem(at sourceURL: URL, to destinationURL: URL) async throws {
    try await storageService.zipItem(at: sourceURL, to: destinationURL)
  }

  /// Decompresses a ZIP archive to target directory.
  public func unzipItem(at sourceURL: URL, to destinationURL: URL) async throws {
    try await storageService.unzipItem(at: sourceURL, to: destinationURL)
  }

  /// Checks available disk capacity and throws when below configuration threshold.
  public func ensureSufficientDiskSpace(requiredBytes: Int64? = nil) throws {
    let required = requiredBytes ?? configuration.minimumRequiredDiskSpace
    let homeURL = directoryURL(.home)
    let values = try? homeURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
    let available = Int64(values?.volumeAvailableCapacityForImportantUsage ?? 0)
    if available < required {
      throw FKFileManagerError.insufficientDiskSpace(required: required, available: available)
    }
  }

  /// Determines whether a URL points to an image file based on MIME type.
  public func isImageFile(_ url: URL) -> Bool {
    FKFileMimeResolver.mimeType(for: url.pathExtension).hasPrefix("image/")
  }

  // MARK: - Download

  public func download(
    _ request: FKDownloadRequest,
    progress: (@Sendable (FKTransferProgress) -> Void)? = nil,
    completion: (@Sendable (Result<FKDownloadResult, FKFileManagerError>) -> Void)? = nil
  ) async throws -> Int {
    try ensureSufficientDiskSpace()
    return try await downloadService.download(request, progress: progress, completion: completion)
  }

  public func download(
    _ request: FKDownloadRequest,
    progress: (@escaping @Sendable (FKTransferProgress) -> Void),
    completion: @escaping @Sendable (Result<FKDownloadResult, FKFileManagerError>) -> Void
  ) {
    Task { @MainActor in
      do {
        _ = try await self.download(request, progress: progress, completion: completion)
      } catch let error as FKFileManagerError {
        completion(.failure(error))
      } catch {
        completion(.failure(.unknown(error.localizedDescription)))
      }
    }
  }

  public func pauseDownload(taskID: Int) async {
    await downloadService.pause(taskID: taskID)
  }

  public func resumeDownload(taskID: Int) async {
    await downloadService.resume(taskID: taskID)
  }

  // MARK: - Upload

  public func upload(
    _ request: FKUploadRequest,
    progress: (@Sendable (FKTransferProgress) -> Void)? = nil,
    completion: (@Sendable (Result<FKUploadResult, FKFileManagerError>) -> Void)? = nil
  ) async throws -> Int {
    try ensureSufficientDiskSpace()
    return try await uploadService.upload(request, progress: progress, completion: completion)
  }

  public func upload(
    _ request: FKUploadRequest,
    progress: (@escaping @Sendable (FKTransferProgress) -> Void),
    completion: @escaping @Sendable (Result<FKUploadResult, FKFileManagerError>) -> Void
  ) {
    Task { @MainActor in
      do {
        _ = try await self.upload(request, progress: progress, completion: completion)
      } catch let error as FKFileManagerError {
        completion(.failure(error))
      } catch {
        completion(.failure(.unknown(error.localizedDescription)))
      }
    }
  }

  // MARK: - Shared task control

  public func cancel(taskID: Int) async {
    await downloadService.cancel(taskID: taskID)
    await uploadService.cancel(taskID: taskID)
  }

  public func cancelAll() async {
    await downloadService.cancelAll()
    await uploadService.cancelAll()
  }

  public func persistedTransfers() async -> [FKPersistedTransfer] {
    let downloads = downloadService.persistedTransfers()
    let uploads = uploadService.persistedTransfers()
    return (downloads + uploads).sorted { $0.updatedAt > $1.updatedAt }
  }
}
