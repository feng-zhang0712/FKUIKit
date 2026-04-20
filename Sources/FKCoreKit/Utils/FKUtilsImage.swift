import Foundation

#if canImport(UIKit)
import UIKit

/// Static image processing helpers.
public enum FKUtilsImage {
  /// Compresses image to max byte size by adjusting JPEG quality.
  public static func compress(_ image: UIImage, maxBytes: Int, minQuality: CGFloat = 0.2) -> Data? {
    guard maxBytes > 0 else { return nil }
    var quality: CGFloat = 1.0
    guard var data = image.jpegData(compressionQuality: quality) else { return nil }
    if data.count <= maxBytes { return data }
    while data.count > maxBytes, quality > minQuality {
      quality -= 0.1
      guard let next = image.jpegData(compressionQuality: quality) else { break }
      data = next
    }
    return data.count <= maxBytes ? data : nil
  }

  /// Crops image with pixel-safe rect.
  public static func crop(_ image: UIImage, to rect: CGRect) -> UIImage? {
    let scaled = CGRect(
      x: rect.origin.x * image.scale,
      y: rect.origin.y * image.scale,
      width: rect.width * image.scale,
      height: rect.height * image.scale
    )
    guard let cg = image.cgImage?.cropping(to: scaled) else { return nil }
    return UIImage(cgImage: cg, scale: image.scale, orientation: image.imageOrientation)
  }

  /// Applies rounded corners to image.
  public static func rounded(_ image: UIImage, radius: CGFloat) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: image.size)
    return renderer.image { _ in
      let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: image.size), cornerRadius: radius)
      path.addClip()
      image.draw(in: CGRect(origin: .zero, size: image.size))
    }
  }

  /// Creates a solid color image.
  public static func solidColor(_ color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { context in
      color.setFill()
      context.fill(CGRect(origin: .zero, size: size))
    }
  }

  /// Converts image to Base64 string.
  public static func base64(from image: UIImage, compressionQuality: CGFloat = 1) -> String? {
    image.jpegData(compressionQuality: compressionQuality)?.base64EncodedString()
  }

  /// Converts Base64 string to image.
  public static func image(fromBase64 text: String) -> UIImage? {
    guard let data = Data(base64Encoded: text) else { return nil }
    return UIImage(data: data)
  }
}
#endif
