import Foundation

/// Maps offline download identifiers to on-disk playback URLs.
public protocol FKMediaOfflinePlaybackProviding: AnyObject, Sendable {
  func playbackURL(forDownloadIdentifier identifier: String) -> URL?
}
