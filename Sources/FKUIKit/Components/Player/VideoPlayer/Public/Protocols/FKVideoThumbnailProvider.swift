import UIKit

/// Supplies preview thumbnails while the user scrubs the progress bar.
@MainActor
public protocol FKVideoThumbnailProvider: AnyObject {
  func thumbnail(at time: TimeInterval) async -> UIImage?
}
