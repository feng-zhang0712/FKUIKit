import AVFoundation
import Foundation

/// Attaches a FairPlay resource-loader delegate from ``FKMediaFairPlayContentKeyProviding``.
@MainActor
public final class FKMediaFairPlayDRMPlugin: FKMediaDRMPlugin {

  public weak var contentKeyProvider: FKMediaFairPlayContentKeyProviding?
  public var fairPlayConfiguration: FKMediaFairPlayConfiguration?

  public init(
    contentKeyProvider: FKMediaFairPlayContentKeyProviding? = nil,
    configuration: FKMediaFairPlayConfiguration? = nil
  ) {
    self.contentKeyProvider = contentKeyProvider
    self.fairPlayConfiguration = configuration
  }

  public func configure(asset: AVURLAsset, item: FKMediaItem) throws {
    _ = fairPlayConfiguration ?? item.fairPlayConfiguration
    guard let provider = contentKeyProvider,
          let delegate = provider.resourceLoaderDelegate(for: item, asset: asset) else {
      return
    }
    asset.resourceLoader.setDelegate(delegate, queue: DispatchQueue(label: "com.fkkit.media.fairplay.loader"))
  }
}
