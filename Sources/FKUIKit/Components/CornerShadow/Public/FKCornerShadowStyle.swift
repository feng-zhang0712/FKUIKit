//
// FKCornerShadowStyle.swift
//

import UIKit

/// Corner radius, fill, border, and shadow for one ``UIView``.
public struct FKCornerShadowStyle {
  public var corners: UIRectCorner
  public var cornerRadius: CGFloat
  public var fillColor: UIColor?
  public var fillGradient: FKCornerShadowGradient?
  public var border: FKCornerShadowBorder
  /// `nil` removes shadow layers and clears the host layer shadow.
  public var shadow: FKCornerShadowElevation?

  public init(
    corners: UIRectCorner = .allCorners,
    cornerRadius: CGFloat = 0,
    fillColor: UIColor? = nil,
    fillGradient: FKCornerShadowGradient? = nil,
    border: FKCornerShadowBorder = .none,
    shadow: FKCornerShadowElevation? = nil
  ) {
    self.corners = corners
    self.cornerRadius = cornerRadius
    self.fillColor = fillColor
    self.fillGradient = fillGradient
    self.border = border
    self.shadow = shadow
  }

  /// Empty template (no radius, no fill, no border, no shadow).
  public static var none: FKCornerShadowStyle {
    FKCornerShadowStyle()
  }
}
