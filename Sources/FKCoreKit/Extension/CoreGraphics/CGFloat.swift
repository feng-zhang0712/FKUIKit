import CoreGraphics
import Foundation

public extension CGFloat {
  /// Rounds the value to the nearest pixel boundary for a non-zero display scale.
  ///
  /// - Parameter scale: Points-to-pixels scale (for example `UIScreen.main.scale` on iOS).
  func fk_roundedToPixel(scale: CGFloat) -> CGFloat {
    guard scale > 0 else { return self }
    return (self * scale).rounded() / scale
  }

  /// Linear interpolation between `a` and `b` by parameter `t` (not clamped).
  static func fk_lerp(_ a: CGFloat, _ b: CGFloat, t: CGFloat) -> CGFloat {
    a + (b - a) * t
  }

  /// Converts degrees to radians.
  static func fk_degreesToRadians(_ degrees: CGFloat) -> CGFloat {
    degrees * .pi / 180
  }

  /// Converts radians to degrees.
  static func fk_radiansToDegrees(_ radians: CGFloat) -> CGFloat {
    radians * 180 / .pi
  }
}
