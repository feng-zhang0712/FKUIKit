import CoreGraphics
import Foundation

public extension CGPoint {
  /// Euclidean distance to `other`.
  func fk_distance(to other: CGPoint) -> CGFloat {
    let dx = x - other.x
    let dy = y - other.y
    return sqrt(dx * dx + dy * dy)
  }

  /// Adds corresponding components.
  static func fk_add(_ lhs: CGPoint, _ rhs: CGPoint) -> CGPoint {
    CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
  }

  /// Subtracts corresponding components.
  static func fk_subtract(_ lhs: CGPoint, _ rhs: CGPoint) -> CGPoint {
    CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
  }

  /// Multiplies both components by `scalar`.
  func fk_scaled(by scalar: CGFloat) -> CGPoint {
    CGPoint(x: x * scalar, y: y * scalar)
  }
}
