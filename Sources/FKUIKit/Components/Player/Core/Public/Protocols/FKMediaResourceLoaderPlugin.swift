import Foundation

/// Refreshes or rewrites a media URL before loading (e.g. signed URL rotation).
public protocol FKMediaResourceLoaderPlugin: AnyObject {
  func resolveURL(
    for item: FKMediaItem,
    currentURL: URL
  ) async throws -> URL
}
