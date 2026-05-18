import Foundation

/// Resolves offline playback URLs from a ``FKMediaOfflineDownloadRegistry``.
public final class FKMediaOfflineRegistryPlaybackProvider: FKMediaOfflinePlaybackProviding, @unchecked Sendable {

  private let registry: FKMediaOfflineDownloadRegistry

  public init(registry: FKMediaOfflineDownloadRegistry) {
    self.registry = registry
  }

  public func playbackURL(forDownloadIdentifier identifier: String) -> URL? {
    registry.localURL(for: identifier)
  }
}
