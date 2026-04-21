import Foundation

/// URLSession-based download manager with pause/resume and persistence support.
@MainActor
final class FKDownloadService: NSObject, URLSessionDownloadDelegate, URLSessionTaskDelegate {
  private struct DownloadContext {
    let request: FKDownloadRequest
    let progress: (@Sendable (FKTransferProgress) -> Void)?
    let completion: (@Sendable (Result<FKDownloadResult, FKFileManagerError>) -> Void)?
    var resumeDataURL: URL?
  }

  private let fileManager: Foundation.FileManager
  private let storageService: FKFileStorageCore
  private let persistenceStore: FKTransferPersistenceStore
  private let workingDirectory: URL
  private var foregroundSession: URLSession!
  private var backgroundSession: URLSession!
  private var contexts: [Int: DownloadContext] = [:]
  private var snapshots: [Int: FKPersistedTransfer] = [:]

  init(
    configuration: FKFileManagerConfiguration,
    storageService: FKFileStorageCore,
    fileManager: Foundation.FileManager = .default
  ) {
    self.fileManager = fileManager
    self.storageService = storageService
    let cacheURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    self.workingDirectory = cacheURL.appendingPathComponent(configuration.workingDirectoryName, isDirectory: true)
    self.persistenceStore = FKTransferPersistenceStore(key: configuration.persistenceKey)
    super.init()
    configureSessions(with: configuration.backgroundSessionIdentifier)
    try? fileManager.createDirectory(at: workingDirectory, withIntermediateDirectories: true)
    Task { @MainActor in
      await restoreSnapshots()
      await reconnectBackgroundTasks()
    }
  }

  func download(
    _ request: FKDownloadRequest,
    progress: (@Sendable (FKTransferProgress) -> Void)?,
    completion: (@Sendable (Result<FKDownloadResult, FKFileManagerError>) -> Void)?
  ) async throws -> Int {
    guard request.sourceURL.scheme != nil else {
      throw FKFileManagerError.invalidURL(request.sourceURL.absoluteString)
    }

    var urlRequest = URLRequest(url: request.sourceURL)
    urlRequest.httpMethod = "GET"
    let task: URLSessionDownloadTask
    if request.allowsBackground {
      task = backgroundSession.downloadTask(with: urlRequest)
    } else {
      task = foregroundSession.downloadTask(with: urlRequest)
    }

    contexts[task.taskIdentifier] = DownloadContext(
      request: request,
      progress: progress,
      completion: completion,
      resumeDataURL: resumeDataURL(for: task.taskIdentifier)
    )
    snapshots[task.taskIdentifier] = FKPersistedTransfer(
      id: task.taskIdentifier,
      kind: .download,
      state: .running,
      sourceURL: request.sourceURL,
      destinationPath: request.destinationDirectory.path,
      updatedAt: Date()
    )
    await persistSnapshots()
    task.resume()
    return task.taskIdentifier
  }

  func pause(taskID: Int) async {
    guard let task = await findTask(taskID: taskID) else { return }
    let data = await task.cancelByProducingResumeData()
    if let data {
      let url = resumeDataURL(for: taskID)
      try? data.write(to: url, options: .atomic)
      contexts[taskID]?.resumeDataURL = url
    }
    if var snapshot = snapshots[taskID] {
      snapshot = FKPersistedTransfer(
        id: snapshot.id,
        kind: snapshot.kind,
        state: .paused,
        sourceURL: snapshot.sourceURL,
        destinationPath: snapshot.destinationPath,
        updatedAt: Date()
      )
      snapshots[taskID] = snapshot
    }
    await persistSnapshots()
  }

  func resume(taskID: Int) async {
    guard var context = contexts[taskID], let resumeDataURL = context.resumeDataURL else { return }
    guard let data = try? Data(contentsOf: resumeDataURL) else { return }

    let task = foregroundSession.downloadTask(withResumeData: data)
    context.resumeDataURL = nil
    contexts.removeValue(forKey: taskID)
    contexts[task.taskIdentifier] = context
    snapshots[task.taskIdentifier] = FKPersistedTransfer(
      id: task.taskIdentifier,
      kind: .download,
      state: .running,
      sourceURL: context.request.sourceURL,
      destinationPath: context.request.destinationDirectory.path,
      updatedAt: Date()
    )
    snapshots.removeValue(forKey: taskID)
    try? fileManager.removeItem(at: resumeDataURL)
    await persistSnapshots()
    task.resume()
  }

  func cancel(taskID: Int) async {
    guard let task = await findTask(taskID: taskID) else { return }
    task.cancel()
    contexts.removeValue(forKey: taskID)
    snapshots[taskID] = nil
    try? fileManager.removeItem(at: resumeDataURL(for: taskID))
    await persistSnapshots()
  }

  func cancelAll() async {
    let tasks = await allDownloadTasks()
    tasks.forEach { $0.cancel() }
    contexts.removeAll()
    snapshots.removeAll()
    await persistSnapshots()
  }

  func persistedTransfers() -> [FKPersistedTransfer] {
    snapshots.values.sorted { $0.id < $1.id }
  }

  nonisolated func urlSession(
    _ session: URLSession,
    downloadTask: URLSessionDownloadTask,
    didWriteData bytesWritten: Int64,
    totalBytesWritten: Int64,
    totalBytesExpectedToWrite: Int64
  ) {
    Task { @MainActor in
      guard let context = self.contexts[downloadTask.taskIdentifier] else { return }
      let total = max(totalBytesExpectedToWrite, 1)
      let progress = FKTransferProgress(
        taskID: downloadTask.taskIdentifier,
        progress: Double(totalBytesWritten) / Double(total),
        completedBytes: totalBytesWritten,
        totalBytes: totalBytesExpectedToWrite
      )
      context.progress?(progress)
    }
  }

  nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
    Task { @MainActor in
      guard let context = self.contexts[downloadTask.taskIdentifier] else { return }
      do {
        let destination = try self.buildDestinationURL(for: context, sourceURL: downloadTask.originalRequest?.url)
        if self.fileManager.fileExists(atPath: destination.path) {
          try self.fileManager.removeItem(at: destination)
        }
        try self.fileManager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        try self.fileManager.moveItem(at: location, to: destination)
        context.completion?(.success(FKDownloadResult(taskID: downloadTask.taskIdentifier, fileURL: destination, sourceURL: context.request.sourceURL)))
        self.contexts.removeValue(forKey: downloadTask.taskIdentifier)
        self.snapshots.removeValue(forKey: downloadTask.taskIdentifier)
        await self.persistSnapshots()
      } catch {
        context.completion?(.failure(.transferFailed(error.localizedDescription)))
      }
    }
  }

  nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    guard let error else { return }
    Task { @MainActor in
      guard let context = self.contexts[task.taskIdentifier] else { return }
      if let nsError = error as NSError?,
         let resumeData = nsError.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
        let url = self.resumeDataURL(for: task.taskIdentifier)
        try? resumeData.write(to: url, options: .atomic)
        self.contexts[task.taskIdentifier]?.resumeDataURL = url
      }
      context.completion?(.failure(.transferFailed(error.localizedDescription)))
      self.snapshots[task.taskIdentifier] = FKPersistedTransfer(
        id: task.taskIdentifier,
        kind: .download,
        state: .failed,
        sourceURL: context.request.sourceURL,
        destinationPath: context.request.destinationDirectory.path,
        updatedAt: Date()
      )
      await self.persistSnapshots()
    }
  }

  private func configureSessions(with identifier: String) {
    let foregroundConfig = URLSessionConfiguration.default
    foregroundConfig.waitsForConnectivity = true
    foregroundSession = URLSession(configuration: foregroundConfig, delegate: self, delegateQueue: nil)

    let backgroundConfig = URLSessionConfiguration.background(withIdentifier: identifier)
    backgroundConfig.waitsForConnectivity = true
    backgroundSession = URLSession(configuration: backgroundConfig, delegate: self, delegateQueue: nil)
  }

  private func buildDestinationURL(for context: DownloadContext, sourceURL: URL?) throws -> URL {
    let fileName = context.request.fileName ?? sourceURL?.lastPathComponent ?? UUID().uuidString
    guard fileName.isEmpty == false else {
      throw FKFileManagerError.transferFailed("Cannot infer destination file name.")
    }
    return context.request.destinationDirectory.appendingPathComponent(fileName, isDirectory: false)
  }

  private func resumeDataURL(for taskID: Int) -> URL {
    workingDirectory.appendingPathComponent("resume-\(taskID).data")
  }

  private func allDownloadTasks() async -> [URLSessionDownloadTask] {
    let foreground = foregroundSession!
    let background = backgroundSession!
    return await withCheckedContinuation { continuation in
      foreground.getAllTasks { foregroundTasks in
        background.getAllTasks { backgroundTasks in
          let tasks = (foregroundTasks + backgroundTasks).compactMap { $0 as? URLSessionDownloadTask }
          continuation.resume(returning: tasks)
        }
      }
    }
  }

  private func findTask(taskID: Int) async -> URLSessionDownloadTask? {
    let tasks = await allDownloadTasks()
    return tasks.first { $0.taskIdentifier == taskID }
  }

  private func persistSnapshots() async {
    await persistenceStore.save(Array(snapshots.values))
  }

  private func restoreSnapshots() async {
    let stored = await persistenceStore.load().filter { $0.kind == .download }
    snapshots = Dictionary(uniqueKeysWithValues: stored.map { ($0.id, $0) })
  }

  private func reconnectBackgroundTasks() async {
    let tasks = await withCheckedContinuation { continuation in
      backgroundSession.getAllTasks { continuation.resume(returning: $0) }
    }
    for task in tasks.compactMap({ $0 as? URLSessionDownloadTask }) {
      guard let url = task.originalRequest?.url else { continue }
      if snapshots[task.taskIdentifier] == nil {
        snapshots[task.taskIdentifier] = FKPersistedTransfer(
          id: task.taskIdentifier,
          kind: .download,
          state: .running,
          sourceURL: url,
          destinationPath: nil,
          updatedAt: Date()
        )
      }
    }
    await persistSnapshots()
  }
}
