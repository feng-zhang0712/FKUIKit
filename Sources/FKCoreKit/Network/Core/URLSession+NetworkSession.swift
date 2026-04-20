import Foundation

/// Default `NetworkSession` adapter backed by `URLSession`.
///
/// This adapter allows dependency injection for tests while preserving
/// production behavior of URLSession task APIs.
public final class URLSessionAdapter: NetworkSession {
  /// Backing URLSession instance.
  private let session: URLSession

  /// Creates session adapter.
  ///
  /// - Parameter session: Backing URLSession. Defaults to `.shared`.
  public init(session: URLSession = .shared) {
    self.session = session
  }

  /// Creates a data task.
  ///
  /// - Parameters:
  ///   - request: Built URL request.
  ///   - completionHandler: Task completion callback.
  /// - Returns: URLSession data task.
  public func dataTask(
    with request: URLRequest,
    completionHandler: @escaping DataTaskCompletion
  ) -> URLSessionDataTask {
    session.dataTask(with: request, completionHandler: completionHandler)
  }

  /// Creates an upload task from file URL.
  ///
  /// - Parameters:
  ///   - request: Upload request.
  ///   - fileURL: Local file URL.
  ///   - completionHandler: Task completion callback.
  /// - Returns: URLSession upload task.
  public func uploadTask(
    with request: URLRequest,
    fromFile fileURL: URL,
    completionHandler: @escaping DataTaskCompletion
  ) -> URLSessionUploadTask {
    session.uploadTask(with: request, fromFile: fileURL, completionHandler: completionHandler)
  }

  /// Creates a download task.
  ///
  /// - Parameter request: Download request.
  /// - Returns: URLSession download task.
  public func downloadTask(with request: URLRequest) -> URLSessionDownloadTask {
    session.downloadTask(with: request)
  }

  /// Creates a download task from resume data.
  ///
  /// - Parameter resumeData: Resume data captured from interrupted task.
  /// - Returns: URLSession download task.
  public func downloadTask(withResumeData resumeData: Data) -> URLSessionDownloadTask {
    session.downloadTask(withResumeData: resumeData)
  }
}

/// Weak task wrapper conforming to `Cancellable`.
///
/// This avoids retaining URLSessionTask strongly from higher-level APIs.
final class URLSessionTaskBox: Cancellable {
  /// Wrapped URLSession task.
  private weak var task: URLSessionTask?

  /// Creates cancellable wrapper.
  ///
  /// - Parameter task: Underlying URLSession task.
  init(task: URLSessionTask) {
    self.task = task
  }

  /// Cancels underlying task if it still exists.
  func cancel() {
    task?.cancel()
  }
}
