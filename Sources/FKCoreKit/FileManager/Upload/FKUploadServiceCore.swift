import Foundation

/// URLSession-based multipart upload manager.
@MainActor
final class FKUploadServiceCore: NSObject, URLSessionTaskDelegate, URLSessionDataDelegate {
  private struct UploadContext {
    let progress: (@Sendable (FKTransferProgress) -> Void)?
    let completion: (@Sendable (Result<FKUploadResult, FKFileManagerError>) -> Void)?
    var buffer: Data
  }

  private var session: URLSession!
  private let persistenceStore: FKTransferPersistenceStore
  private var contexts: [Int: UploadContext] = [:]
  private var snapshots: [Int: FKPersistedTransfer] = [:]

  init(configuration: FKFileManagerConfiguration) {
    let config = URLSessionConfiguration.default
    config.waitsForConnectivity = true
    self.persistenceStore = FKTransferPersistenceStore(key: "\(configuration.persistenceKey).upload")
    super.init()
    self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    Task { @MainActor in
      await restoreSnapshots()
    }
  }

  @discardableResult
  func upload(
    _ request: FKUploadRequest,
    progress: (@Sendable (FKTransferProgress) -> Void)?,
    completion: (@Sendable (Result<FKUploadResult, FKFileManagerError>) -> Void)?
  ) async throws -> Int {
    var urlRequest = request.urlRequest
    let boundary = "FKBoundary-\(UUID().uuidString)"
    urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    let payload = try buildMultipartBody(for: request, boundary: boundary)
    let task = session.uploadTask(with: urlRequest, from: payload)

    contexts[task.taskIdentifier] = UploadContext(progress: progress, completion: completion, buffer: Data())
    snapshots[task.taskIdentifier] = FKPersistedTransfer(
      id: task.taskIdentifier,
      kind: .upload,
      state: .running,
      sourceURL: request.urlRequest.url ?? URL(string: "about:blank")!,
      destinationPath: nil,
      updatedAt: Date()
    )
    await persistSnapshots()
    progress?(FKTransferProgress(taskID: task.taskIdentifier, progress: 0, completedBytes: 0, totalBytes: Int64(payload.count)))
    task.resume()
    return task.taskIdentifier
  }

  func cancel(taskID: Int) async {
    let tasks = await withCheckedContinuation { continuation in
      session.getAllTasks { continuation.resume(returning: $0) }
    }
    tasks.first(where: { $0.taskIdentifier == taskID })?.cancel()
    contexts.removeValue(forKey: taskID)
    snapshots.removeValue(forKey: taskID)
    await persistSnapshots()
  }

  func cancelAll() async {
    let tasks = await withCheckedContinuation { continuation in
      session.getAllTasks { continuation.resume(returning: $0) }
    }
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
    task: URLSessionTask,
    didSendBodyData bytesSent: Int64,
    totalBytesSent: Int64,
    totalBytesExpectedToSend: Int64
  ) {
    Task { @MainActor in
      guard let context = self.contexts[task.taskIdentifier] else { return }
      let total = max(totalBytesExpectedToSend, 1)
      context.progress?(
        FKTransferProgress(
          taskID: task.taskIdentifier,
          progress: Double(totalBytesSent) / Double(total),
          completedBytes: totalBytesSent,
          totalBytes: totalBytesExpectedToSend
        )
      )
    }
  }

  nonisolated func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    Task { @MainActor in
      guard var context = self.contexts[dataTask.taskIdentifier] else { return }
      context.buffer.append(data)
      self.contexts[dataTask.taskIdentifier] = context
    }
  }

  nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    Task { @MainActor in
      guard let context = self.contexts[task.taskIdentifier] else { return }
      defer {
        self.contexts.removeValue(forKey: task.taskIdentifier)
        self.snapshots.removeValue(forKey: task.taskIdentifier)
        Task { await self.persistSnapshots() }
      }

      if let error {
        context.completion?(.failure(.transferFailed(error.localizedDescription)))
        return
      }

      context.completion?(
        .success(FKUploadResult(taskID: task.taskIdentifier, responseData: context.buffer, response: task.response))
      )
    }
  }

  private func buildMultipartBody(for request: FKUploadRequest, boundary: String) throws -> Data {
    var body = Data()
    for field in request.formFields {
      body.append("--\(boundary)\r\n".data(using: .utf8)!)
      body.append("Content-Disposition: form-data; name=\"\(field.key)\"\r\n\r\n".data(using: .utf8)!)
      body.append("\(field.value)\r\n".data(using: .utf8)!)
    }
    for file in request.files {
      let data = try Data(contentsOf: file.fileURL)
      body.append("--\(boundary)\r\n".data(using: .utf8)!)
      body.append("Content-Disposition: form-data; name=\"\(file.fieldName)\"; filename=\"\(file.fileName)\"\r\n".data(using: .utf8)!)
      body.append("Content-Type: \(file.mimeType)\r\n\r\n".data(using: .utf8)!)
      body.append(data)
      body.append("\r\n".data(using: .utf8)!)
    }
    body.append("--\(boundary)--\r\n".data(using: .utf8)!)
    return body
  }

  private func persistSnapshots() async {
    await persistenceStore.save(Array(snapshots.values))
  }

  private func restoreSnapshots() async {
    let stored = await persistenceStore.load().filter { $0.kind == .upload }
    snapshots = Dictionary(uniqueKeysWithValues: stored.map { ($0.id, $0) })
  }
}
