//
//  FKButton+Appearance.swift
//
//  Per-`UIControl.State` container styling: solid or gradient fill, border, shadow, corner radii, content insets,
//  and interaction tuning (highlight feedback, extra hit-testing slop).
//

import UIKit

// MARK: - Appearance model

public extension FKButton {

  // MARK: LinearGradient

  /// Linear gradient used as the button background when `backgroundGradient != nil`.
  struct LinearGradient: Equatable, Sendable {
    public var colors: [UIColor]
    public var locations: [CGFloat]?
    public var startPoint: CGPoint
    public var endPoint: CGPoint

    public init(
      colors: [UIColor],
      locations: [CGFloat]? = nil,
      startPoint: CGPoint = CGPoint(x: 0.5, y: 0),
      endPoint: CGPoint = CGPoint(x: 0.5, y: 1)
    ) {
      self.colors = colors
      self.locations = locations
      self.startPoint = startPoint
      self.endPoint = endPoint
    }
  }

  // MARK: Appearance

  /// Appearance for the button container layer and content insets for a specific state.
  struct Appearance: Equatable, Sendable {
    /// Corner styling (radius strategy + curve + masked corners).
    public var cornerStyle: CornerStyle

    /// Border style.
    public var border: Border
    
    /// Background color.
    public var backgroundColor: UIColor
    /// When non-`nil`, draws behind content as a linear gradient and ignores `backgroundColor` for fill.
    public var backgroundGradient: LinearGradient?
    /// Overall alpha (0...1).
    public var alpha: CGFloat

    /// Shadow configuration. `nil` disables shadow.
    public var shadow: Shadow?
    /// How shadow path should be generated.
    public var shadowPathStrategy: ShadowPathStrategy
    
    /// Content insets (applied to the internal title/image stack).
    public var contentInsets: NSDirectionalEdgeInsets
    /// Whether to clip subviews. When `nil`, uses an automatic strategy:
    /// with shadow: do not clip; without shadow: clip.
    public var clipsToBounds: Bool?
    /// Interactive behavior such as highlight feedback and hit-test outsets.
    public var interaction: Interaction

    public init(
      cornerStyle: CornerStyle = .default,
      border: Border = .default,
      backgroundColor: UIColor = .clear,
      backgroundGradient: LinearGradient? = nil,
      alpha: CGFloat = 1.0,
      shadow: Shadow? = nil,
      shadowPathStrategy: ShadowPathStrategy = .automatic,
      contentInsets: NSDirectionalEdgeInsets = .init(top: 7, leading: 12, bottom: 7, trailing: 12),
      clipsToBounds: Bool? = nil,
      interaction: Interaction = .default
    ) {
      self.cornerStyle = cornerStyle
      self.border = border
      self.backgroundColor = backgroundColor
      self.backgroundGradient = backgroundGradient
      self.alpha = max(0, min(1, alpha))
      self.shadow = shadow
      self.shadowPathStrategy = shadowPathStrategy
      self.contentInsets = contentInsets
      self.clipsToBounds = clipsToBounds
      self.interaction = interaction
    }

    /// Returns a new appearance by applying a partial override on top of the current value.
    public func merged(with override: AppearanceOverride) -> Appearance {
      let mergedGradient: LinearGradient?
      switch override.backgroundGradient {
      case nil:
        mergedGradient = backgroundGradient
      case .some(let inner):
        mergedGradient = inner
      }
      return Appearance(
        cornerStyle: override.cornerStyle ?? cornerStyle,
        border: override.border ?? border,
        backgroundColor: override.backgroundColor ?? backgroundColor,
        backgroundGradient: mergedGradient,
        alpha: override.alpha ?? alpha,
        shadow: override.shadow ?? shadow,
        shadowPathStrategy: override.shadowPathStrategy ?? shadowPathStrategy,
        contentInsets: override.contentInsets ?? contentInsets,
        clipsToBounds: override.clipsToBounds ?? clipsToBounds,
        interaction: override.interaction ?? interaction
      )
    }

    /// Solid-style preset with a filled background.
    public static func filled(
      backgroundColor: UIColor,
      borderColor: UIColor = .clear,
      cornerStyle: CornerStyle = .default
    ) -> Appearance {
      Appearance(
        cornerStyle: cornerStyle,
        border: Border(width: 0, color: borderColor),
        backgroundColor: backgroundColor,
        backgroundGradient: nil
      )
    }

    /// Outlined-style preset with transparent background and visible border.
    public static func outlined(
      borderColor: UIColor,
      borderWidth: CGFloat = 1,
      cornerStyle: CornerStyle = .default
    ) -> Appearance {
      Appearance(
        cornerStyle: cornerStyle,
        border: Border(width: borderWidth, color: borderColor),
        backgroundColor: .clear,
        backgroundGradient: nil
      )
    }

    /// Ghost-style preset with transparent background and no border.
    public static func ghost(cornerStyle: CornerStyle = .default) -> Appearance {
      Appearance(cornerStyle: cornerStyle, border: .clear, backgroundColor: .clear, backgroundGradient: nil)
    }
    
    /// Baseline appearance used when no per-state appearance is registered.
    public static let `default` = Appearance()
  }

  // MARK: StateAppearances

  /// Convenience bundle of four appearances matching the usual `UIControl.State` set used by `setAppearances(_:)`.
  /// Unspecified slots fall back to `.normal` (or from `.selected` to `.highlighted`) so you rarely need all four.
  struct StateAppearances: Equatable, Sendable {
    public let normal: Appearance
    public let selected: Appearance
    public let highlighted: Appearance
    public let disabled: Appearance

    public init(
      normal: Appearance,
      selected: Appearance? = nil,
      highlighted: Appearance? = nil,
      disabled: Appearance? = nil
    ) {
      self.normal = normal
      self.selected = selected ?? normal
      self.highlighted = highlighted ?? self.selected
      self.disabled = disabled ?? normal
    }

    /// Resolves the appearance for a specific control state.
    public func appearance(for state: UIControl.State) -> Appearance {
      switch state {
      case .selected:
        return selected
      case .highlighted:
        return highlighted
      case .disabled:
        return disabled
      default:
        return normal
      }
    }
  }

  // MARK: AppearanceOverride

  /// Partial override model for `Appearance.merged(with:)`.
  ///
  /// `shadow` and `clipsToBounds` use double optional to represent three states:
  /// - `nil`: do not override
  /// - `.some(nil)`: explicitly clear the value
  /// - `.some(.some(value))`: override with a concrete value
  struct AppearanceOverride: Equatable, Sendable {
    public var cornerStyle: CornerStyle?
    public var border: Border?
    public var backgroundColor: UIColor?
    public var backgroundGradient: LinearGradient??
    public var alpha: CGFloat?
    public var shadow: Shadow??
    public var shadowPathStrategy: ShadowPathStrategy?
    public var contentInsets: NSDirectionalEdgeInsets?
    public var clipsToBounds: Bool??
    public var interaction: Interaction?

    /// Creates a partial override where `nil` means "do not override this field".
    public init(
      cornerStyle: CornerStyle? = nil,
      border: Border? = nil,
      backgroundColor: UIColor? = nil,
      backgroundGradient: LinearGradient?? = nil,
      alpha: CGFloat? = nil,
      shadow: Shadow?? = nil,
      shadowPathStrategy: ShadowPathStrategy? = nil,
      contentInsets: NSDirectionalEdgeInsets? = nil,
      clipsToBounds: Bool?? = nil,
      interaction: Interaction? = nil
    ) {
      self.cornerStyle = cornerStyle
      self.border = border
      self.backgroundColor = backgroundColor
      self.backgroundGradient = backgroundGradient
      self.alpha = alpha
      self.shadow = shadow
      self.shadowPathStrategy = shadowPathStrategy
      self.contentInsets = contentInsets
      self.clipsToBounds = clipsToBounds
      self.interaction = interaction
    }
  }

  // MARK: CornerStyle

  struct CornerStyle: Equatable, Sendable {
    /// Radius strategy (`none` / fixed / capsule).
    public let corner: Corner
    /// Corner curve style (`.continuous` gives card-like corners).
    public let curve: CALayerCornerCurve
    /// Active corners for rounding.
    public let maskedCorners: CACornerMask

    public init(
      corner: Corner = .none,
      curve: CALayerCornerCurve = .continuous,
      maskedCorners: CACornerMask = [
        .layerMinXMinYCorner,
        .layerMaxXMinYCorner,
        .layerMinXMaxYCorner,
        .layerMaxXMaxYCorner,
      ]
    ) {
      self.corner = corner
      self.curve = curve
      self.maskedCorners = maskedCorners
    }

    public static let `default` = CornerStyle()
  }

  // MARK: Border

  struct Border: Equatable, Sendable {
    /// Border width in points. Negative input is clamped to `0`.
    public let width: CGFloat
    /// Border color.
    public let color: UIColor

    public init(width: CGFloat = 0, color: UIColor = .clear) {
      self.width = max(0, width)
      self.color = color
    }

    public static let `default` = Border()
    public static let clear = Border()
  }

  // MARK: Interaction

  struct Interaction: Equatable, Sendable {
    /// Highlight alpha multiplier when touching down.
    public let pressedAlpha: CGFloat
    /// Highlight scale multiplier when touching down.
    public let pressedScale: CGFloat
    /// Hit-test outsets used by `point(inside:with:)`.
    public let hitTestOutsets: UIEdgeInsets
    /// When `false`, ignores `pressedAlpha` / `pressedScale` so you can drive highlight visuals yourself.
    public let isHighlightFeedbackEnabled: Bool

    public init(
      pressedAlpha: CGFloat = 0.88,
      pressedScale: CGFloat = 1.0,
      hitTestOutsets: UIEdgeInsets = .init(top: 6, left: 0, bottom: 6, right: 0),
      isHighlightFeedbackEnabled: Bool = true
    ) {
      self.pressedAlpha = max(0, min(1, pressedAlpha))
      self.pressedScale = max(0.2, min(1.2, pressedScale))
      self.hitTestOutsets = hitTestOutsets
      self.isHighlightFeedbackEnabled = isHighlightFeedbackEnabled
    }

    public static let `default` = Interaction()
  }

  // MARK: Shadow

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

  // MARK: ShadowPathStrategy

  /// Shadow path generation strategy.
  ///
  /// - `automatic`: automatically generates a rounded `shadowPath` from current bounds/corners.
  /// - `none`: keeps `layer.shadowPath` as `nil`.
  enum ShadowPathStrategy: Equatable, Sendable {
    case automatic
    case none
  }

  // MARK: Corner

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
