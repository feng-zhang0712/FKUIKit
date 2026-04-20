//
// FKCornerShadowShadow.swift
//
// Shadow model used by FKCornerShadow.
//

import UIKit

/// Selectable shadow edges for precise shadow coverage.
///
/// Use this option set to limit shadow rendering to specific sides and reduce visual noise
/// on dense layouts.
public struct FKCornerShadowSide: OptionSet, Hashable, Sendable {
  /// Raw bitmask value.
  public let rawValue: Int

  /// Creates a new side set.
  ///
  /// - Parameter rawValue: Bitmask representing one or multiple edges.
  public init(rawValue: Int) {
    self.rawValue = rawValue
  }

  /// Top edge.
  public static let top = FKCornerShadowSide(rawValue: 1 << 0)

  /// Left edge.
  public static let left = FKCornerShadowSide(rawValue: 1 << 1)

  /// Bottom edge.
  public static let bottom = FKCornerShadowSide(rawValue: 1 << 2)

  /// Right edge.
  public static let right = FKCornerShadowSide(rawValue: 1 << 3)

  /// All edges.
  public static let all: FKCornerShadowSide = [.top, .left, .bottom, .right]
}

/// Defines high-performance shadow attributes.
///
/// FKCornerShadow always builds explicit shadow paths from this model to avoid
/// implicit shadow rasterization cost.
public struct FKCornerShadowShadow {
  /// Shadow color.
  ///
  /// Default: `.black`.
  public var color: UIColor

  /// Shadow opacity in `[0, 1]`.
  ///
  /// Default: `0.14`.
  public var opacity: Float

  /// Shadow offset in points.
  ///
  /// Default: `(0, 4)`.
  public var offset: CGSize

  /// Blur radius used by Core Animation (`shadowRadius`).
  ///
  /// Default: `12`.
  public var blur: CGFloat

  /// Path spread radius. Positive values expand the path.
  ///
  /// Default: `0`.
  public var spread: CGFloat

  /// Edge selection for shadow rendering.
  ///
  /// Default: `.all`.
  public var sides: FKCornerShadowSide

  /// Creates a shadow descriptor.
  ///
  /// - Parameters:
  ///   - color: Shadow color.
  ///   - opacity: Shadow opacity in `[0, 1]`.
  ///   - offset: Shadow offset in points.
  ///   - blur: Shadow blur radius (`shadowRadius`).
  ///   - spread: Additional spread radius for `shadowPath`.
  ///   - sides: Edge selection for full-side or partial-side shadows.
  public init(
    color: UIColor = .black,
    opacity: Float = 0.14,
    offset: CGSize = CGSize(width: 0, height: 4),
    blur: CGFloat = 12,
    spread: CGFloat = 0,
    sides: FKCornerShadowSide = .all
  ) {
    self.color = color
    self.opacity = opacity
    self.offset = offset
    self.blur = blur
    self.spread = spread
    self.sides = sides
  }
}
