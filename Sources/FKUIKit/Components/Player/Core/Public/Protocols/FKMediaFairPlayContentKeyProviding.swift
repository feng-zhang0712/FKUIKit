import AVFoundation
import Foundation

/// Supplies a FairPlay ``AVAssetResourceLoaderDelegate`` for encrypted streams.
@MainActor
public protocol FKMediaFairPlayContentKeyProviding: AnyObject {
  func resourceLoaderDelegate(for item: FKMediaItem, asset: AVURLAsset) -> AVAssetResourceLoaderDelegate?
}
