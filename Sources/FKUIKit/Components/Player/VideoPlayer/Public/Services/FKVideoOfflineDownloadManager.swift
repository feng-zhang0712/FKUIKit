import Foundation

/// Facade over Core HLS offline download for video apps.
@MainActor
public final class FKVideoOfflineDownloadManager: NSObject {

  public let downloadService: FKMediaHLSDownloadService
  public let offlineRegistry: FKMediaOfflineDownloadRegistry
  public let offlinePlaybackProvider: FKMediaOfflinePlaybackProviding

  public weak var delegate: FKMediaHLSDownloadServiceDelegate?

  public init(
    registry: FKMediaOfflineDownloadRegistry = FKMediaUserDefaultsOfflineDownloadRegistry(),
    downloadService: FKMediaHLSDownloadService? = nil
  ) {
    self.offlineRegistry = registry
    self.offlinePlaybackProvider = FKMediaOfflineRegistryPlaybackProvider(registry: registry)
    self.downloadService = downloadService ?? FKMediaHLSDownloadService()
    super.init()
    self.downloadService.offlineRegistry = registry
    self.downloadService.offlineProvider = offlinePlaybackProvider
    self.downloadService.onDownloadCompleted = { [weak self] id, url in
      self?.offlineRegistry.register(downloadIdentifier: id, localURL: url)
    }
  }

  @discardableResult
  public func startDownload(
    from url: URL,
    title: String,
    downloadIdentifier: String = UUID().uuidString,
    headers: [String: String] = [:]
  ) -> String {
    downloadService.delegate = delegate
    return downloadService.startDownload(
      from: url,
      title: title,
      downloadIdentifier: downloadIdentifier,
      headers: headers
    )
  }

  public func cancelDownload(downloadIdentifier: String) {
    downloadService.cancelDownload(downloadIdentifier: downloadIdentifier)
  }

  public func makeOfflineItem(
    downloadIdentifier: String,
    title: String
  ) -> FKVideoItem? {
    guard offlineRegistry.localURL(for: downloadIdentifier) != nil else { return nil }
    return FKVideoItem(
      id: downloadIdentifier,
      source: .offline(downloadIdentifier: downloadIdentifier),
      title: title
    )
  }
}
