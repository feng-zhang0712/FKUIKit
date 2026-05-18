import AVFoundation
import Foundation

/// Base type for FairPlay integration. Subclass and override ``configure(asset:item:)``.
@MainActor
open class FKMediaFairPlayResourceLoader: FKMediaDRMPlugin {

  public init() {}

  open func configure(asset: AVURLAsset, item: FKMediaItem) throws {
    _ = asset
    _ = item
  }
}
