//
// EdgeStripShadowPath.swift
//
// Generates narrow strip `CGPath` segments along specified rectangle edges, used as `CALayer.shadowPath`,
// approximating "shadows on only some edges".
//

import UIKit

public enum EdgeStripShadowPath {
  /// Generates a concatenated path along the specified `edges` within `bounds`.
  /// Each edge contributes a narrow rectangular strip.
  /// - Parameters:
  ///   - bounds: Usually the layer's `bounds` in its own coordinate space.
  ///   - edges: Edges that participate in shadowing; can be combined (e.g. `.bottom`, `.top.union(.left)`).
  ///   - shadowRadius: Aligned with `CALayer.shadowRadius` for estimating strip thickness.
  ///   - shadowOffset: Aligned with `CALayer.shadowOffset` for thickness estimation.
  public static func cgPath(
    in bounds: CGRect,
    edges: UIRectEdge,
    shadowRadius: CGFloat,
    shadowOffset: CGSize
  ) -> CGPath {
    let pad = max(shadowRadius * 2, 8) + max(abs(shadowOffset.width), abs(shadowOffset.height))
    let maxThickness = min(bounds.width, bounds.height) * 0.45
    let t = min(max(pad * 0.5, 4), maxThickness)

    let b = bounds
    let path = UIBezierPath()
    if edges.contains(.top) {
      path.append(UIBezierPath(rect: CGRect(x: b.minX, y: b.minY, width: b.width, height: t)))
    }
    if edges.contains(.bottom) {
      path.append(UIBezierPath(rect: CGRect(x: b.minX, y: b.maxY - t, width: b.width, height: t)))
    }
    if edges.contains(.left) {
      path.append(UIBezierPath(rect: CGRect(x: b.minX, y: b.minY, width: t, height: b.height)))
    }
    if edges.contains(.right) {
      path.append(UIBezierPath(rect: CGRect(x: b.maxX - t, y: b.minY, width: t, height: b.height)))
    }
    return path.cgPath
  }
}
