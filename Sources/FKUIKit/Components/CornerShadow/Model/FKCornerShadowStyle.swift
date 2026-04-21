//
// FKCornerShadowStyle.swift
//
// Public style model for FKCornerShadow.
//

import UIKit

/// Defines how corner and shadow are rendered.
///
/// This is the primary style payload used by all public FKCornerShadow APIs.
/// It combines corner geometry, fill, border, and shadow into a single immutable-style
/// transfer object that can be safely copied and overridden.
public struct FKCornerShadowStyle {
  /// Rounded corners to apply.
  ///
  /// Default: `.allCorners`.
  public var corners: UIRectCorner

  /// Corner radius in points.
  ///
  /// Default: `0`.
  public var cornerRadius: CGFloat

  /// Optional fill color for the rounded path.
  ///
  /// Default: `nil`.
  public var fillColor: UIColor?

  /// Optional fill gradient for the rounded path.
  ///
  /// Default: `nil`.
  public var fillGradient: FKCornerShadowGradient?

  /// Border rendering descriptor.
  ///
  /// Default: `.none`.
  public var border: FKCornerShadowBorder

  /// Optional shadow descriptor.
  ///
  /// Default: `nil`.
  public var shadow: FKCornerShadowShadow?

  /// Creates a style descriptor.
  ///
  /// - Parameters:
  ///   - corners: Rounded corners to apply.
  ///   - cornerRadius: Corner radius in points.
  ///   - fillColor: Optional solid fill color.
  ///   - fillGradient: Optional gradient fill descriptor.
  ///   - border: Border style descriptor.
  ///   - shadow: Optional high-performance shadow descriptor.
  public init(
    corners: UIRectCorner = .allCorners,
    cornerRadius: CGFloat = 0,
    fillColor: UIColor? = nil,
    fillGradient: FKCornerShadowGradient? = nil,
    border: FKCornerShadowBorder = .none,
    shadow: FKCornerShadowShadow? = nil
  ) {
    self.corners = corners
    self.cornerRadius = cornerRadius
    self.fillColor = fillColor
    self.fillGradient = fillGradient
    self.border = border
    self.shadow = shadow
  }

  /// Returns an empty style template.
  ///
  /// This value intentionally uses a computed property to avoid static shared mutable-state
  /// concurrency warnings in strict compiler modes.
  public static var none: FKCornerShadowStyle {
    FKCornerShadowStyle()
  }
}
