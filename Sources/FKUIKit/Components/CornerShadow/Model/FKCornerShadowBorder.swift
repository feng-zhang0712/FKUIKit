//
// FKCornerShadowBorder.swift
//
// Border models used by FKCornerShadow.
//

import UIKit

/// Defines border rendering modes.
///
/// The border follows the same rounded bezier path as corners to keep edges aligned.
public enum FKCornerShadowBorder {
  /// No border is rendered.
  case none

  /// Renders a solid border.
  ///
  /// - Parameters:
  ///   - color: Stroke color.
  ///   - width: Stroke width in points.
  case solid(color: UIColor, width: CGFloat)

  /// Renders a gradient border.
  ///
  /// - Parameters:
  ///   - gradient: Linear gradient descriptor used as border texture.
  ///   - width: Stroke width in points.
  case gradient(gradient: FKCornerShadowGradient, width: CGFloat)
}
