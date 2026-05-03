#if canImport(UIKit)
import CoreGraphics
import UIKit

public extension UIImage {
  /// Returns a new image scaled to `size` using a high-quality bitmap renderer.
  func fk_resized(to size: CGSize) -> UIImage? {
    guard size.width > 0, size.height > 0 else { return nil }
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = scale
    format.opaque = false
    let renderer = UIGraphicsImageRenderer(size: size, format: format)
    return renderer.image { _ in
      draw(in: CGRect(origin: .zero, size: size))
    }
  }

  /// Returns a new image filled with `color` while preserving the alpha mask of the original.
  func fk_tinted(with color: UIColor) -> UIImage {
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = scale
    format.opaque = false
    let rect = CGRect(origin: .zero, size: size)
    let renderer = UIGraphicsImageRenderer(size: size, format: format)
    return renderer.image { _ in
      color.setFill()
      UIRectFill(rect)
      draw(in: rect, blendMode: .destinationIn, alpha: 1)
    }
  }

  /// Rounds corners with the given radii; uses the image's current scale.
  func fk_roundingCorners(_ radius: CGFloat, corners: UIRectCorner = .allCorners) -> UIImage? {
    let rect = CGRect(origin: .zero, size: size)
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = scale
    format.opaque = false
    let renderer = UIGraphicsImageRenderer(size: size, format: format)
    return renderer.image { _ in
      let path = UIBezierPath(
        roundedRect: rect,
        byRoundingCorners: corners,
        cornerRadii: CGSize(width: radius, height: radius)
      )
      path.addClip()
      draw(in: rect)
    }
  }
}

#endif
