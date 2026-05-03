import UIKit
import CoreImage

extension UIView {
  /// Captures the current view content and returns a blurred image synchronously.
  ///
  /// - Parameters:
  ///   - parameters: Custom blur parameters.
  ///   - downsampleFactor: Downsample factor used during blur processing (`1` = full resolution, `2/4/8` = faster).
  ///   - scale: Snapshot scale. When `nil`, the best available screen scale is used.
  ///   - context: Optional `CIContext` to reuse across calls for better performance.
  /// - Returns: A blurred snapshot image, or `nil` if capture or processing fails.
  ///
  /// - Important: Must be called on the main thread because UIKit view rendering is not thread-safe.
  public func fk_blurredSnapshot(
    parameters: FKBlurConfiguration.CustomParameters,
    downsampleFactor: CGFloat = 1,
    scale: CGFloat? = nil,
    context: CIContext? = nil
  ) -> UIImage? {
    precondition(Thread.isMainThread, "fk_blurredSnapshot(parameters:downsampleFactor:scale:context:) must be called on the main thread.")
    guard let snapshot = fk_snapshotImage(scale: scale) else { return nil }
    guard let ciImage = snapshot.cgImage.map(CIImage.init(cgImage:)) ?? snapshot.ciImage else { return nil }

    return FKBlurImageProcessor.blur(
      ciImage: ciImage,
      targetScale: snapshot.scale,
      parameters: parameters,
      downsampleFactor: downsampleFactor,
      context: context
    )
  }

  /// Captures the current view content and generates a blurred image asynchronously.
  ///
  /// - Parameters:
  ///   - parameters: Custom blur parameters.
  ///   - downsampleFactor: Downsample factor used during blur processing (`1` = full resolution, `2/4/8` = faster).
  ///   - scale: Snapshot scale. When `nil`, the best available screen scale is used.
  ///   - context: Optional `CIContext` to reuse across calls for better performance.
  ///   - callbackQueue: Queue where `completion` is executed. Defaults to `.main`.
  ///   - completion: Completion block with blurred image result.
  ///
  /// - Important: The view snapshot is captured on the main thread, then image filtering is moved off-main.
  public func fk_blurredSnapshotAsync(
    parameters: FKBlurConfiguration.CustomParameters,
    downsampleFactor: CGFloat = 1,
    scale: CGFloat? = nil,
    context: CIContext? = nil,
    callbackQueue: DispatchQueue = .main,
    completion: @escaping @Sendable (UIImage?) -> Void
  ) {
    let captureOnMain: () -> Void = { [weak self] in
      guard let self else {
        callbackQueue.async { completion(nil) }
        return
      }

      // UIKit capture must run on main.
      guard let snapshot = self.fk_snapshotImage(scale: scale) else {
        callbackQueue.async { completion(nil) }
        return
      }

      // Core Image processing can run in background.
      DispatchQueue.global(qos: .userInitiated).async {
        let ci = snapshot.cgImage.map(CIImage.init(cgImage:)) ?? snapshot.ciImage
        let result = ci.flatMap {
          FKBlurImageProcessor.blur(
            ciImage: $0,
            targetScale: snapshot.scale,
            parameters: parameters,
            downsampleFactor: downsampleFactor,
            context: context
          )
        }
        callbackQueue.async {
          completion(result)
        }
      }
    }

    if Thread.isMainThread {
      captureOnMain()
    } else {
      Task { @MainActor in
        captureOnMain()
      }
    }
  }

  private func fk_snapshotImage(scale: CGFloat?) -> UIImage? {
    let resolvedScale: CGFloat = {
      if let scale, scale > 0 { return scale }
      if let windowScreenScale = window?.screen.scale { return windowScreenScale }
      return UIScreen.main.scale
    }()

    let format = UIGraphicsImageRendererFormat()
    format.scale = resolvedScale
    format.opaque = isOpaque

    let renderer = UIGraphicsImageRenderer(bounds: bounds, format: format)
    return renderer.image { ctx in
      // `drawHierarchy` generally provides better visual parity with on-screen compositing.
      if !drawHierarchy(in: bounds, afterScreenUpdates: false) {
        layer.render(in: ctx.cgContext)
      }
    }
  }
}

