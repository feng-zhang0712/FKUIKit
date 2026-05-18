import AVFoundation
import Foundation

/// Configures DRM (e.g. FairPlay) on an asset before playback begins.
@MainActor
public protocol FKMediaDRMPlugin: AnyObject {
  func configure(asset: AVURLAsset, item: FKMediaItem) throws
}
