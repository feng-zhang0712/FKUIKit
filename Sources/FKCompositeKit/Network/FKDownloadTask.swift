//
// FKDownloadTask.swift
//

import Foundation

public actor FKDownloadSession: NSObject {

  // MARK: - Types

  public typealias ProgressHandler = @Sendable (Double) -> Void
  public typealias CompletionHandler = @Sendable (Result<URL, FKNetworkError>) -> Void

  private struct PendingTask: Sendable {
    let onProgress: ProgressHandler?
    let onCompletion: CompletionHandler
    var resumeData: Data?
  }

  // MARK: - Properties

  private var session: URLSession!
  private var pendingTasks: [Int: PendingTask] = [:]
  private let configuration: FKNetworkConfiguration

  // MARK: - Init

  public init(configuration: FKNetworkConfiguration = FKNetworkConfiguration()) {
    self.configuration = configuration
    super.init()
    let cfg = URLSessionConfiguration.default
    cfg.timeoutIntervalForRequest = configuration.timeoutInterval
    // URLSession delegate must be set after super.init; use a bridge
    self.session = URLSession(configuration: cfg, delegate: FKDownloadDelegate(owner: self), delegateQueue: nil)
  }

  // MARK: - Download

  /// Start a download. Returns the local file URL on completion.
  public func download(
    url: String,
    headers: [String: String] = [:],
    onProgress: ProgressHandler? = nil
  ) async throws -> URL {
    guard let fullURL = URL(string: configuration.baseURL + url) ?? URL(string: url) else {
      throw FKNetworkError.invalidURL
    }
    var request = URLRequest(url: fullURL)
    configuration.defaultHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }
    headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

    return try await withCheckedThrowingContinuation { continuation in
      Task {
        let task = self.session.downloadTask(with: request)
        await self.register(taskID: task.taskIdentifier, pending: PendingTask(
          onProgress: onProgress,
          onCompletion: { result in continuation.resume(with: result) }
        ))
        task.resume()
      }
    }
  }

  /// Resume a previously cancelled download using its resume data.
  public func resumeDownload(
    resumeData: Data,
    onProgress: ProgressHandler? = nil
  ) async throws -> URL {
    return try await withCheckedThrowingContinuation { continuation in
      Task {
        let task = self.session.downloadTask(withResumeData: resumeData)
        await self.register(taskID: task.taskIdentifier, pending: PendingTask(
          onProgress: onProgress,
          onCompletion: { result in continuation.resume(with: result) }
        ))
        task.resume()
      }
    }
  }

  // MARK: - Internal (called by delegate)

  private func register(taskID: Int, pending: PendingTask) {
    pendingTasks[taskID] = pending
  }

  func didWriteData(taskID: Int, progress: Double) {
    pendingTasks[taskID]?.onProgress?(progress)
  }

  func didFinish(taskID: Int, location: URL) {
    guard let pending = pendingTasks.removeValue(forKey: taskID) else { return }
    // Move temp file to a stable location before the system deletes it
    let dest = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension(location.pathExtension)
    do {
      try FileManager.default.moveItem(at: location, to: dest)
      pending.onCompletion(.success(dest))
    } catch {
      pending.onCompletion(.failure(.networkFailure(error)))
    }
  }

  func didFail(taskID: Int, error: Error?, resumeData: Data?) {
    guard var pending = pendingTasks.removeValue(forKey: taskID) else { return }
    pending.resumeData = resumeData
    if let urlError = error as? URLError, urlError.code == .cancelled {
      pending.onCompletion(.failure(.cancelled))
    } else if let urlError = error as? URLError, urlError.code == .timedOut {
      pending.onCompletion(.failure(.timeout))
    } else {
      pending.onCompletion(.failure(error.map { .networkFailure($0) } ?? .unknown))
    }
  }
}

// MARK: - Delegate bridge (non-isolated)

private final class FKDownloadDelegate: NSObject, URLSessionDownloadDelegate, Sendable {
  private let owner: FKDownloadSession

  init(owner: FKDownloadSession) { self.owner = owner }

  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
    let id = downloadTask.taskIdentifier
    Task { await owner.didFinish(taskID: id, location: location) }
  }

  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                  didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
    guard totalBytesExpectedToWrite > 0 else { return }
    let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
    let id = downloadTask.taskIdentifier
    Task { await owner.didWriteData(taskID: id, progress: progress) }
  }

  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    guard error != nil else { return }
    let id = task.taskIdentifier
    let resumeData = (error as? URLError)?.userInfo[NSURLSessionDownloadTaskResumeData] as? Data
    Task { await owner.didFail(taskID: id, error: error, resumeData: resumeData) }
  }
}
