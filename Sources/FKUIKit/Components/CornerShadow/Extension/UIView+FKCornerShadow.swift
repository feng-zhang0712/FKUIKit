//
// UIView+FKCornerShadow.swift
//
// Public APIs for applying FKCornerShadow on any UIView.
//

import UIKit

@MainActor
extension UIView: FKCornerShadowStylable {
  /// The currently applied FKCornerShadow style.
  ///
  /// Returns `nil` if no style was applied yet.
  public var fk_cornerShadowCurrentStyle: FKCornerShadowStyle? {
    fk_cornerShadowStyle
  }

  /// Applies corner + border + shadow style in one line.
  ///
  /// - Parameter style: Full style descriptor.
  ///
  /// - Performance: Internally uses explicit bezier paths and `shadowPath` to avoid
  ///   implicit shadow geometry calculation.
  /// - Important: This method must be called on the main thread.
  public func fk_applyCornerShadow(_ style: FKCornerShadowStyle) {
    fk_cornerShadowAssertMainThread()
    FKCornerShadowLayoutObserver.installIfNeeded()
    fk_cornerShadowStyle = style
    FKCornerShadowRenderer.apply(style: style, to: self)
  }

  /// Applies the global default style and allows local overrides.
  ///
  /// - Parameter configure: Optional in-place mutation to override global defaults.
  ///
  /// This API is ideal for design-system driven projects where most views share
  /// a baseline style.
  public func fk_applyCornerShadowFromGlobal(configure: ((inout FKCornerShadowStyle) -> Void)? = nil) {
    fk_cornerShadowAssertMainThread()
    var style = FKCornerShadowManager.shared.defaultStyle
    configure?(&style)
    fk_applyCornerShadow(style)
  }

  /// Resets all corner/shadow layers and style state.
  ///
  /// Use this in cell reuse workflows to prevent stale visual layers.
  public func fk_resetCornerShadow() {
    fk_cornerShadowAssertMainThread()
    FKCornerShadowRenderer.reset(on: self)
    fk_cornerShadowClearAssociatedStyle()
  }

  /// Resets rounded corners while keeping border/shadow settings.
  public func fk_resetCorners() {
    fk_cornerShadowAssertMainThread()
    var style = fk_cornerShadowCurrentStyle ?? FKCornerShadowStyle.none
    style.cornerRadius = 0
    style.corners = .allCorners
    fk_applyCornerShadow(style)
  }

  /// Resets shadow settings while keeping corners/border settings.
  public func fk_resetShadow() {
    fk_cornerShadowAssertMainThread()
    var style = fk_cornerShadowCurrentStyle ?? FKCornerShadowStyle.none
    style.shadow = nil
    fk_applyCornerShadow(style)
  }

  /// Resets border settings while keeping corners/shadow settings.
  public func fk_resetBorder() {
    fk_cornerShadowAssertMainThread()
    var style = fk_cornerShadowCurrentStyle ?? FKCornerShadowStyle.none
    style.border = .none
    fk_applyCornerShadow(style)
  }

  /// Convenience API for quickly setting rounded corners.
  ///
  /// - Parameters:
  ///   - corners: Corners to round.
  ///   - radius: Corner radius in points.
  ///   - fillColor: Optional solid fill color.
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

  /// Convenience API for quickly setting a high-performance shadow.
  ///
  /// - Parameters:
  ///   - color: Shadow color.
  ///   - opacity: Shadow opacity in `[0, 1]`.
  ///   - offset: Shadow offset in points.
  ///   - blur: Shadow blur radius (`shadowRadius`).
  ///   - spread: Spread radius used to grow/shrink `shadowPath`.
  ///   - sides: Edge selection for full or partial side shadow.
  ///
  /// - Performance: Uses explicit `shadowPath` to reduce offscreen rendering pressure.
  public func fk_setShadow(
    color: UIColor = .black,
    opacity: Float = 0.14,
    offset: CGSize = CGSize(width: 0, height: 4),
    blur: CGFloat = 12,
    spread: CGFloat = 0,
    sides: FKCornerShadowSide = .all
  ) {
    fk_cornerShadowAssertMainThread()
    var style = fk_cornerShadowCurrentStyle ?? FKCornerShadowStyle.none
    style.shadow = FKCornerShadowShadow(
      color: color,
      opacity: opacity,
      offset: offset,
      blur: blur,
      spread: spread,
      sides: sides
    )
    fk_applyCornerShadow(style)
  }

  /// Convenience API for quickly setting border.
  ///
  /// - Parameter border: Border mode descriptor.
  public func fk_setBorder(_ border: FKCornerShadowBorder) {
    fk_cornerShadowAssertMainThread()
    var style = fk_cornerShadowCurrentStyle ?? FKCornerShadowStyle.none
    style.border = border
    fk_applyCornerShadow(style)
  }

  /// One-line quick apply with explicit parameters.
  ///
  /// - Parameters:
  ///   - corners: Corners to round.
  ///   - cornerRadius: Corner radius in points.
  ///   - fillColor: Optional solid fill color.
  ///   - fillGradient: Optional fill gradient.
  ///   - border: Border mode.
  ///   - shadow: Optional shadow descriptor.
  ///
  /// This overload is the recommended zero-learning-cost entry point.
  public func fk_applyCornerShadow(
    corners: UIRectCorner = .allCorners,
    cornerRadius: CGFloat,
    fillColor: UIColor? = nil,
    fillGradient: FKCornerShadowGradient? = nil,
    border: FKCornerShadowBorder = .none,
    shadow: FKCornerShadowShadow? = nil
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
