//
// EdgeStripShadowPath.swift
//
// 沿矩形指定边生成窄条 `CGPath`，用于 `CALayer.shadowPath`，近似「仅某些边投射阴影」。
//

import UIKit

public enum EdgeStripShadowPath {
  /// 在 `bounds` 内，沿 `edges` 指定的边生成拼接后的路径（每条边为一条窄矩形带）。
  /// - Parameters:
  ///   - bounds: 通常为图层在自身坐标系下的 `bounds`。
  ///   - edges: 需要参与阴影的边；可组合，例如 `.bottom`、`.top.union(.left)`。
  ///   - shadowRadius: 与 `CALayer.shadowRadius` 对齐，用于估算条带厚度。
  ///   - shadowOffset: 与 `CALayer.shadowOffset` 对齐，参与厚度估算。
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
