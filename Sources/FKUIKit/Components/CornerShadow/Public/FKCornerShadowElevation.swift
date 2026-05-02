//
// FKCornerShadowElevation.swift
//

import UIKit

/// Rectangular edges used to limit drop-shadow rendering.
///
/// When fewer than all edges are selected, the renderer uses separate carrier layers so dense
/// layouts can avoid a full halo around the view.
public struct FKCornerShadowEdge: OptionSet, Hashable, Sendable {
  public let rawValue: Int

  public init(rawValue: Int) {
    self.rawValue = rawValue
  }

  public static let top = FKCornerShadowEdge(rawValue: 1 << 0)
  public static let left = FKCornerShadowEdge(rawValue: 1 << 1)
  public static let bottom = FKCornerShadowEdge(rawValue: 1 << 2)
  public static let right = FKCornerShadowEdge(rawValue: 1 << 3)

  /// Top, left, bottom, and right (full shadow on the host layer when combined with `.all` rendering mode).
  public static let all: FKCornerShadowEdge = [.top, .left, .bottom, .right]
}

/// Drop-shadow parameters rendered with an explicit `shadowPath` (and optional per-edge carriers).
///
/// This type replaces the older `FKCornerShadowShadow` name: same role, clearer vocabulary for
/// international teams (“elevation” / cast shadow, not a duplicate “CornerShadow” token).
public struct FKCornerShadowElevation {
  public var color: UIColor
  public var opacity: Float
  public var offset: CGSize
  /// Maps to `CALayer.shadowRadius`.
  public var blur: CGFloat
  /// Insets the shadow path negatively when positive (common “spread” control).
  public var spread: CGFloat
  /// When equal to `FKCornerShadowEdge.all`, the host view’s layer carries the shadow (fastest).
  public var edges: FKCornerShadowEdge

  public init(
    color: UIColor = .black,
    opacity: Float = 0.14,
    offset: CGSize = CGSize(width: 0, height: 4),
    blur: CGFloat = 12,
    spread: CGFloat = 0,
    edges: FKCornerShadowEdge = .all
  ) {
    self.color = color
    self.opacity = opacity
    self.offset = offset
    self.blur = blur
    self.spread = spread
    self.edges = edges
  }
}
