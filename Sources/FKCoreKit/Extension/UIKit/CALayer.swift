#if canImport(UIKit)
import QuartzCore
import UIKit

public extension CALayer {
  /// Applies a continuous corner curve when available (iOS 13+), otherwise sets `cornerRadius` only.
  func fk_applyContinuousCornerRadius(_ radius: CGFloat) {
    cornerRadius = radius
    masksToBounds = true
    if #available(iOS 13.0, *) {
      cornerCurve = .continuous
    }
  }

  /// Adds a simple shadow without affecting the layer's `cornerRadius` path (uses separate shadow path when `rect` is provided).
  func fk_applyShadow(
    color: UIColor = .black,
    opacity: Float = 0.2,
    offset: CGSize = CGSize(width: 0, height: 2),
    radius: CGFloat = 4,
    shadowPath: CGPath? = nil
  ) {
    shadowColor = color.cgColor
    shadowOpacity = opacity
    shadowOffset = offset
    shadowRadius = radius
    self.shadowPath = shadowPath
  }
}

#endif
