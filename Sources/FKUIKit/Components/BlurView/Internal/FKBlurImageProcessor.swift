import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Metal

/// Internal image-processing utilities shared by blur extensions.
///
/// Centralizes the Core Image blur pipeline so `UIImage.fk_blurred` and `UIView.fk_blurredSnapshot` stay consistent.
enum FKBlurImageProcessor {
  /// Shared CI context used when no custom context is provided by the caller.
  ///
  /// The implementation prefers a Metal-backed context for better throughput.
  static let sharedContext: CIContext = {
    if let device = MTLCreateSystemDefaultDevice() {
      return CIContext(mtlDevice: device, options: [
        .cacheIntermediates: true,
        .priorityRequestLow: false,
      ])
    }
    return CIContext(options: [
      .cacheIntermediates: true,
      .priorityRequestLow: false,
    ])
  }()

  /// Applies a configurable blur pipeline to the input image.
  ///
  /// - Parameters:
  ///   - ciImage: Source CI image.
  ///   - targetScale: Result image scale.
  ///   - parameters: Blur tuning parameters.
  ///   - downsampleFactor: Processing downsample factor (`>= 1`).
  ///   - context: Optional CI context. Uses `sharedContext` when `nil`.
  /// - Returns: Blurred image, or `nil` when rendering fails.
  static func blur(
    ciImage: CIImage,
    targetScale: CGFloat,
    parameters: FKBlurConfiguration.CustomParameters,
    downsampleFactor: CGFloat,
    context: CIContext?
  ) -> UIImage? {
    let factor = max(1, downsampleFactor)

    // Reduce pixel count first to keep dynamic/large-image processing fast.
    let scaledInput: CIImage = {
      guard factor > 1 else { return ciImage }
      let scale = 1 / factor
      return ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    }()

    // 1) Gaussian blur
    let blur = CIFilter.gaussianBlur()
    blur.inputImage = scaledInput
    blur.radius = Float(max(0, parameters.blurRadius / factor))
    var output = blur.outputImage ?? scaledInput

    // Blur output can become infinite-extent; crop to keep bounds deterministic.
    output = output.cropped(to: scaledInput.extent)

    // 2) Saturation / brightness tuning
    let controls = CIFilter.colorControls()
    controls.inputImage = output
    controls.saturation = Float(parameters.saturation)
    controls.brightness = Float(parameters.brightness)
    output = controls.outputImage ?? output

    // 3) Optional tint overlay
    if let tint = parameters.tintColor, parameters.tintOpacity > 0 {
      let tintCI = CIImage(color: CIColor(color: tint.withAlphaComponent(parameters.tintOpacity)))
        .cropped(to: output.extent)
      let composite = CIFilter.sourceOverCompositing()
      composite.inputImage = tintCI
      composite.backgroundImage = output
      output = composite.outputImage ?? output
    }

    let ctx = context ?? sharedContext
    guard let cgOut = ctx.createCGImage(output, from: output.extent) else { return nil }

    // Memory optimization:
    // Keep the downsampled pixel buffer as output and recover the same logical display size via `UIImage.scale`.
    // This avoids the expensive "upsample-to-full-pixels" intermediate image, which can cause large memory spikes.
    let outputScale = max(0.01, targetScale / factor)
    return UIImage(cgImage: cgOut, scale: outputScale, orientation: .up)
  }
}

