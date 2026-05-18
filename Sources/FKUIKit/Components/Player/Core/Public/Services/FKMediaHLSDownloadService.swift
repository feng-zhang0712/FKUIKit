import AVFoundation
import Foundation

/// Delegate for HLS offline download lifecycle events.
public protocol FKMediaHLSDownloadServiceDelegate: AnyObject {
  func hlsDownloadService(
    _ service: FKMediaHLSDownloadService,
    didUpdateProgress progress: Float,
    for downloadIdentifier: String
  )
  func hlsDownloadService(
    _ service: FKMediaHLSDownloadService,
    didFinish downloadIdentifier: String,
    localURL: URL
  )
  func hlsDownloadService(
    _ service: FKMediaHLSDownloadService,
    didFail downloadIdentifier: String,
    error: Error
  )
}

/// Manages FairPlay-free HLS offline downloads via `AVAssetDownloadURLSession`.
public final class FKMediaHLSDownloadService: NSObject, @unchecked Sendable {

  public weak var delegate: FKMediaHLSDownloadServiceDelegate?
  public weak var offlineProvider: FKMediaOfflinePlaybackProviding?
  public var offlineRegistry: FKMediaOfflineDownloadRegistry?
  /// Called when a download finishes; register the URL with your ``FKMediaOfflinePlaybackProviding`` implementation.
  public var onDownloadCompleted: ((String, URL) -> Void)?

  private var session: AVAssetDownloadURLSession!
  private var tasks: [String: AVAssetDownloadTask] = [:]

  public override init() {
    super.init()
    let configuration = URLSessionConfiguration.background(withIdentifier: "com.fkkit.media.hls.download")
    configuration.allowsCellularAccess = true
    session = AVAssetDownloadURLSession(
      configuration: configuration,
      assetDownloadDelegate: self,
      delegateQueue: .main
    )
  }

  /// Starts downloading an HLS asset. The returned identifier can be used with ``FKMediaSource/offline``.
  @discardableResult
  public func startDownload(
    from url: URL,
    title: String,
    downloadIdentifier: String = UUID().uuidString,
    headers: [String: String] = [:]
  ) -> String {
    var options: [String: Any] = [:]
    if !headers.isEmpty {
      options["AVURLAssetHTTPHeaderFieldsKey"] = headers
    }
    let asset = AVURLAsset(url: url, options: options)
    guard let task = session.makeAssetDownloadTask(
      asset: asset,
      assetTitle: title,
      assetArtworkData: nil,
      options: nil
    ) else {
      return downloadIdentifier
    }
    task.taskDescription = downloadIdentifier
    tasks[downloadIdentifier] = task
    task.resume()
    return downloadIdentifier
  }

  public func cancelDownload(downloadIdentifier: String) {
    tasks[downloadIdentifier]?.cancel()
    tasks.removeValue(forKey: downloadIdentifier)
  }

  public func localURL(for downloadIdentifier: String) -> URL? {
    offlineProvider?.playbackURL(forDownloadIdentifier: downloadIdentifier)
  }
}

extension FKMediaHLSDownloadService: AVAssetDownloadDelegate {

  public func urlSession(
    _ session: URLSession,
    assetDownloadTask: AVAssetDownloadTask,
    didFinishDownloadingTo location: URL
  ) {
    guard let identifier = assetDownloadTask.taskDescription else { return }
    tasks.removeValue(forKey: identifier)
    offlineRegistry?.register(downloadIdentifier: identifier, localURL: location)
    if let provider = offlineProvider as? FKMediaInMemoryOfflinePlaybackProvider {
      provider.register(downloadIdentifier: identifier, localURL: location)
    }
    onDownloadCompleted?(identifier, location)
    notifyOnMain { $0.hlsDownloadService(self, didFinish: identifier, localURL: location) }
  }

  public func urlSession(
    _ session: URLSession,
    assetDownloadTask: AVAssetDownloadTask,
    didLoad timeRange: CMTimeRange,
    totalTimeRangesLoaded loadedTimeRanges: [NSValue],
    timeRangeExpectedToLoad: CMTimeRange
  ) {
    guard let identifier = assetDownloadTask.taskDescription else { return }
    let loaded = loadedTimeRanges
      .map { $0.timeRangeValue.duration }
      .reduce(CMTime.zero, CMTimeAdd)
    let expected = timeRangeExpectedToLoad.duration
    let progress: Float
    if expected.seconds > 0 {
      progress = Float(loaded.seconds / expected.seconds)
    } else {
      progress = 0
    }
    let clamped = min(1, max(0, progress))
    notifyOnMain { $0.hlsDownloadService(self, didUpdateProgress: clamped, for: identifier) }
  }

  public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    guard let error, let identifier = task.taskDescription else { return }
    tasks.removeValue(forKey: identifier)
    notifyOnMain { $0.hlsDownloadService(self, didFail: identifier, error: error) }
  }

  private func notifyOnMain(_ action: @escaping @MainActor (FKMediaHLSDownloadServiceDelegate) -> Void) {
    guard let delegate else { return }
    Task { @MainActor in
      action(delegate)
    }
  }
}
