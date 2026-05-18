import AVFoundation
import Foundation
import Photos

/// Default Photos-framework resolver for ``FKMediaSource/photoAsset``.
@MainActor
public final class FKMediaPhotoLibraryAssetResolver: FKMediaPhotoAssetResolver {

  public init() {}

  public func resolveAsset(localIdentifier: String) async throws -> AVURLAsset {
    let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
    guard let asset = assets.firstObject else {
      throw FKMediaError.invalidState("Photo asset not found: \(localIdentifier)")
    }
    guard asset.mediaType == .video else {
      throw FKMediaError.unsupportedFormat(
        FKMediaFormatDescriptor(
          container: .unknown,
          mediaType: .video,
          suggestedEngine: .avFoundation,
          delivery: .file,
          isLive: false,
          allowsAVFoundation: false,
          allowsExtended: false
        )
      )
    }

    return try await withCheckedThrowingContinuation { continuation in
      let options = PHVideoRequestOptions()
      options.isNetworkAccessAllowed = true
      options.deliveryMode = .highQualityFormat

      PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, info in
        if let error = info?[PHImageErrorKey] as? Error {
          continuation.resume(throwing: FKMediaErrorMapper.map(error, engine: .avFoundation))
          return
        }
        guard let urlAsset = avAsset as? AVURLAsset else {
          continuation.resume(
            throwing: FKMediaError.engineFailed(
              engine: .avFoundation,
              message: "Photo asset is not exported as AVURLAsset"
            )
          )
          return
        }
        continuation.resume(returning: urlAsset)
      }
    }
  }
}
