import CoreGraphics
import UIKit

/// Shared stroke math for UIKit and SwiftUI so both renderers stay aligned.
struct FKDividerGeometry {
  private init() {}

  /// Horizontal segment inside `bounds`, shortened by `contentInsets.left` / `.right`. Returns `nil` if the segment collapses.
  static func horizontalSegment(in bounds: CGRect, contentInsets: UIEdgeInsets) -> (x1: CGFloat, x2: CGFloat, y: CGFloat)? {
    let w = bounds.width
    let h = bounds.height
    let y = h / 2
    let left = max(0, contentInsets.left)
    let right = max(0, contentInsets.right)
    let x1 = min(left, w)
    let x2 = max(x1, w - right)
    guard x2 - x1 > 0.000_1 else { return nil }
    return (x1, x2, y)
  }

  /// Vertical segment inside `bounds`, shortened by `contentInsets.top` / `.bottom`. Returns `nil` if the segment collapses.
  static func verticalSegment(in bounds: CGRect, contentInsets: UIEdgeInsets) -> (x: CGFloat, y1: CGFloat, y2: CGFloat)? {
    let w = bounds.width
    let h = bounds.height
    let x = w / 2
    let top = max(0, contentInsets.top)
    let bottom = max(0, contentInsets.bottom)
    let y1 = min(top, h)
    let y2 = max(y1, h - bottom)
    guard y2 - y1 > 0.000_1 else { return nil }
    return (x, y1, y2)
  }
}
