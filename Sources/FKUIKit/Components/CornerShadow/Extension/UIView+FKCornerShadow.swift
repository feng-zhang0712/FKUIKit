//
// UIView+FKCornerShadow.swift
//

import UIKit

@MainActor
extension UIView: FKCornerShadowStylable {
  /// Currently applied style, if any.
  public var fk_cornerShadowCurrentStyle: FKCornerShadowStyle? {
    fk_cornerShadowStyle
  }

  public func fk_applyCornerShadow(_ style: FKCornerShadowStyle) {
    fk_cornerShadowAssertMainThread()
    FKCornerShadowLayoutObserver.installIfNeeded()
    fk_cornerShadowStyle = style
    FKCornerShadowRenderer.apply(style: style, to: self)
  }

  public func fk_applyCornerShadowFromDefaults(_ configure: ((inout FKCornerShadowStyle) -> Void)?) {
    fk_cornerShadowAssertMainThread()
    var style = FKCornerShadowManager.shared.defaultStyle
    configure?(&style)
    fk_applyCornerShadow(style)
  }

  public func fk_resetCornerShadow() {
    fk_cornerShadowAssertMainThread()
    FKCornerShadowRenderer.reset(on: self)
    fk_cornerShadowClearAssociatedStyle()
  }

  public func fk_resetCorners() {
    fk_cornerShadowAssertMainThread()
    var style = fk_cornerShadowCurrentStyle ?? FKCornerShadowStyle.none
    style.cornerRadius = 0
    style.corners = .allCorners
    fk_applyCornerShadow(style)
  }

  public func fk_resetShadow() {
    fk_cornerShadowAssertMainThread()
    var style = fk_cornerShadowCurrentStyle ?? FKCornerShadowStyle.none
    style.shadow = nil
    fk_applyCornerShadow(style)
  }

  public func fk_resetBorder() {
    fk_cornerShadowAssertMainThread()
    var style = fk_cornerShadowCurrentStyle ?? FKCornerShadowStyle.none
    style.border = .none
    fk_applyCornerShadow(style)
  }

  public func fk_setCorners(
    _ corners: UIRectCorner = .allCorners,
    radius: CGFloat,
    fillColor: UIColor? = nil
  ) {
    fk_cornerShadowAssertMainThread()
    var style = fk_cornerShadowCurrentStyle ?? FKCornerShadowStyle.none
    style.corners = corners
    style.cornerRadius = radius
    if let fillColor {
      style.fillColor = fillColor
    }
    fk_applyCornerShadow(style)
  }

  /// Convenience overload for `FKCornerShadowElevation`; use `edges` to limit shadow to specific sides.
  public func fk_setShadow(
    color: UIColor = .black,
    opacity: Float = 0.14,
    offset: CGSize = CGSize(width: 0, height: 4),
    blur: CGFloat = 12,
    spread: CGFloat = 0,
    edges: FKCornerShadowEdge = .all
  ) {
    fk_cornerShadowAssertMainThread()
    var style = fk_cornerShadowCurrentStyle ?? FKCornerShadowStyle.none
    style.shadow = FKCornerShadowElevation(
      color: color,
      opacity: opacity,
      offset: offset,
      blur: blur,
      spread: spread,
      edges: edges
    )
    fk_applyCornerShadow(style)
  }

  public func fk_setBorder(_ border: FKCornerShadowBorder) {
    fk_cornerShadowAssertMainThread()
    var style = fk_cornerShadowCurrentStyle ?? FKCornerShadowStyle.none
    style.border = border
    fk_applyCornerShadow(style)
  }

  public func fk_applyCornerShadow(
    corners: UIRectCorner = .allCorners,
    cornerRadius: CGFloat,
    fillColor: UIColor? = nil,
    fillGradient: FKCornerShadowGradient? = nil,
    border: FKCornerShadowBorder = .none,
    shadow: FKCornerShadowElevation? = nil
  ) {
    fk_cornerShadowAssertMainThread()
    let style = FKCornerShadowStyle(
      corners: corners,
      cornerRadius: cornerRadius,
      fillColor: fillColor,
      fillGradient: fillGradient,
      border: border,
      shadow: shadow
    )
    fk_applyCornerShadow(style)
  }
}

extension FKCornerShadowStylable {
  /// Applies `FKCornerShadowManager.shared.defaultStyle` without overrides.
  public func fk_applyCornerShadowFromDefaults() {
    fk_applyCornerShadowFromDefaults(nil)
  }
}
