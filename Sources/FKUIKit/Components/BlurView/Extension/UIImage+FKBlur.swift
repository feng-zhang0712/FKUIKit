import UIKit
import CoreImage

extension UIImage {
  /// Returns a blurred image using Core Image with fully custom parameters.
  ///
  /// - Parameters:
  ///   - parameters: Custom blur parameters.
  ///   - downsampleFactor: Downsample factor (1 = full res, 2/4/8 = faster).
  ///   - context: Optional CIContext to reuse across calls for performance.
  /// - Returns: Blurred image, or `nil` if processing fails.
  public func fk_blurred(
    parameters: FKBlurConfiguration.CustomParameters,
    downsampleFactor: CGFloat = 1,
    context: CIContext? = nil
  ) -> UIImage? {
    let source = self

    guard let cgImage = source.cgImage else {
      // Some UIImage instances are backed by CIImage only (no CGImage). Support both.
      guard let ciImage = source.ciImage else { return nil }
      return FKBlurImageProcessor.blur(
        ciImage: ciImage,
        targetScale: source.scale,
        parameters: parameters,
        downsampleFactor: downsampleFactor,
        context: context
      )
    }

    let ciImage = CIImage(cgImage: cgImage)
    return FKBlurImageProcessor.blur(
      ciImage: ciImage,
      targetScale: source.scale,
      parameters: parameters,
      downsampleFactor: downsampleFactor,
      context: context
    )
  }
}

