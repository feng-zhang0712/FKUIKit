import AVFoundation
import Foundation

/// Resolves a Photos library identifier into a playable `AVURLAsset`.
@MainActor
public protocol FKMediaPhotoAssetResolver: AnyObject {
  func resolveAsset(localIdentifier: String) async throws -> AVURLAsset
}
