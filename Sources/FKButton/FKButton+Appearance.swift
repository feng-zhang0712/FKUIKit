//
//  FKButton+Appearance.swift
//
// Appearance model applied to `FKButton` for `UIControl.State`: corners, shadow, border, background, and insets.
//

import UIKit

public extension FKButton {
  /// Appearance for the button container layer and content insets for a specific state.
  struct Appearance {
    /// Corner strategy (none / fixed radius / capsule).
    public let corner: Corner
    /// Corner curve style (`.continuous` matches iOS card-like rounding).
    public let cornerCurve: CALayerCornerCurve
    /// Specifies which corners are active; default is all corners.
    public let maskedCorners: CACornerMask

    /// Shadow configuration. `nil` disables shadow.
    public let shadow: Shadow?
    
    /// Border width.
    public let borderWidth: CGFloat
    /// Border color.
    public let borderColor: UIColor
    
    /// Background color.
    public let backgroundColor: UIColor
    /// Overall alpha (0...1).
    public let alpha: CGFloat
    
    /// Content insets (applied to the internal title/image stack).
    public let contentInsets: NSDirectionalEdgeInsets
    /// Whether to clip subviews. When `nil`, uses an automatic strategy:
    /// with shadow: do not clip; without shadow: clip.
    public let clipsToBounds: Bool?

    public init(
      corner: Corner = .none,
      cornerCurve: CALayerCornerCurve = .continuous,
      maskedCorners: CACornerMask = [
        .layerMinXMinYCorner,
        .layerMaxXMinYCorner,
        .layerMinXMaxYCorner,
        .layerMaxXMaxYCorner,
      ],
      shadow: Shadow? = nil,
      borderWidth: CGFloat = 0,
      borderColor: UIColor = .clear,
      backgroundColor: UIColor = .clear,
      alpha: CGFloat = 1.0,
      contentInsets: NSDirectionalEdgeInsets = .init(top: 7, leading: 12, bottom: 7, trailing: 12),
      clipsToBounds: Bool? = nil
    ) {
      self.corner = corner
      self.cornerCurve = cornerCurve
      self.maskedCorners = maskedCorners
      self.shadow = shadow
      self.borderWidth = borderWidth
      self.borderColor = borderColor
      self.backgroundColor = backgroundColor
      self.alpha = alpha
      self.contentInsets = contentInsets
      self.clipsToBounds = clipsToBounds
    }
    
    public nonisolated(unsafe) static let `default` = Appearance()
  }
  
  /// Shadow parameters paired with `Appearance`.
  struct Shadow: Equatable, Sendable {
    public let color: UIColor
    public let opacity: Float
    public let offset: CGSize
    public let radius: CGFloat
    
    public init(
      color: UIColor = .black,
      opacity: Float = 0.18,
      offset: CGSize = CGSize(width: 0, height: 2),
      radius: CGFloat = 4
    ) {
      self.color = color
      self.opacity = opacity
      self.offset = offset
      self.radius = radius
    }
  }

  /// Corner strategy mapped to `FKButton.layer.cornerRadius` / `maskedCorners`.
  ///
  /// - `none`: no rounded corners.
  /// - `fixed(CGFloat)`: fixed corner radius in points.
  /// - `capsule`: capsule corners computed as `min(width, height) / 2`.
  enum Corner: Equatable, Sendable {
    case none
    case fixed(CGFloat)
    case capsule
  }
}
