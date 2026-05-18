import AVFoundation
import Foundation

/// Describes where media bytes come from.
///
/// `asset` and `photoAsset` cases are not strictly `Sendable`; the coordinator uses them on the main actor only.
public enum FKMediaSource: @unchecked Sendable, Equatable {
  case url(URL, fallbackURLs: [URL] = [], headers: [String: String] = [:])
  case asset(AVURLAsset)
  case photoAsset(localIdentifier: String)
  case offline(downloadIdentifier: String)
}

extension FKMediaSource {

  /// Primary URL when the source is URL-based; `nil` for other cases.
  public var primaryURL: URL? {
    switch self {
    case let .url(url, _, _):
      return url
    case .asset, .photoAsset, .offline:
      return nil
    }
  }

  /// All candidate URLs in playback order (primary, then fallbacks).
  public var candidateURLs: [URL] {
    switch self {
    case let .url(url, fallbacks, _):
      return [url] + fallbacks
    case .asset, .photoAsset, .offline:
      return []
    }
  }

  /// HTTP headers applied when building `AVURLAsset` for remote URLs.
  public var httpHeaders: [String: String] {
    switch self {
    case let .url(_, _, headers):
      return headers
    case .asset, .photoAsset, .offline:
      return [:]
    }
  }

  /// URL from an `AVURLAsset` when available.
  public var assetURL: URL? {
    switch self {
    case let .asset(asset):
      return asset.url
    case .url, .photoAsset, .offline:
      return nil
    }
  }
}

extension FKMediaSource {

  public static func == (lhs: FKMediaSource, rhs: FKMediaSource) -> Bool {
    switch (lhs, rhs) {
    case let (.url(lURL, lFallback, lHeaders), .url(rURL, rFallback, rHeaders)):
      return lURL == rURL && lFallback == rFallback && lHeaders == rHeaders
    case let (.asset(lAsset), .asset(rAsset)):
      return lAsset.url == rAsset.url
    case let (.photoAsset(lID), .photoAsset(rID)):
      return lID == rID
    case let (.offline(lID), .offline(rID)):
      return lID == rID
    default:
      return false
    }
  }
}
