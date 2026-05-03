import UIKit

// MARK: - Gradient

/// Linear gradient fill for `FKButton` backgrounds (`FKButtonAppearance.backgroundGradient`).
public struct FKButtonLinearGradient: Equatable, Sendable {
  public var colors: [UIColor]
  public var locations: [CGFloat]?
  public var startPoint: CGPoint
  public var endPoint: CGPoint

  /// Creates a linear gradient.
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

/// Corner radius strategy for `FKButton`.
public enum FKButtonCorner: Equatable, Sendable {
  case none
  case fixed(CGFloat)
  case capsule
}

/// Shadow path generation strategy.
public enum FKButtonShadowPathStrategy: Equatable, Sendable {
  case automatic
  case none
}

/// Border style.
public struct FKButtonBorderStyle: Equatable, Sendable {
  public let width: CGFloat
  public let color: UIColor

  public init(width: CGFloat = 0, color: UIColor = .clear) {
    self.width = max(0, width)
    self.color = color
  }

  public static let `default` = FKButtonBorderStyle()
  public static let clear = FKButtonBorderStyle()
}

/// Corner style.
public struct FKButtonCornerStyle: Equatable, Sendable {
  public let corner: FKButtonCorner
  public let curve: CALayerCornerCurve
  public let maskedCorners: CACornerMask

  public init(
    corner: FKButtonCorner = .none,
    curve: CALayerCornerCurve = .continuous,
    maskedCorners: CACornerMask = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
  ) {
    self.corner = corner
    self.curve = curve
    self.maskedCorners = maskedCorners
  }

  public static let `default` = FKButtonCornerStyle()
}

/// Interaction visual feedback.
public struct FKButtonInteractionStyle: Equatable, Sendable {
  public let pressedAlpha: CGFloat
  public let pressedScale: CGFloat
  public let hitTestOutsets: UIEdgeInsets
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

  public static let `default` = FKButtonInteractionStyle()
}

/// Shadow parameters.
public struct FKButtonShadowStyle: Equatable, Sendable {
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

/// Per-state appearance model.
public struct FKButtonAppearance: Equatable, Sendable {
  public var cornerStyle: FKButtonCornerStyle
  public var border: FKButtonBorderStyle
  public var backgroundColor: UIColor
  public var backgroundGradient: FKButtonLinearGradient?
  public var alpha: CGFloat
  public var shadow: FKButtonShadowStyle?
  public var shadowPathStrategy: FKButtonShadowPathStrategy
  public var contentInsets: NSDirectionalEdgeInsets
  public var clipsToBounds: Bool?
  public var interaction: FKButtonInteractionStyle

  /// Creates an appearance.
  public init(
    cornerStyle: FKButtonCornerStyle = .default,
    border: FKButtonBorderStyle = .default,
    backgroundColor: UIColor = .clear,
    backgroundGradient: FKButtonLinearGradient? = nil,
    alpha: CGFloat = 1.0,
    shadow: FKButtonShadowStyle? = nil,
    shadowPathStrategy: FKButtonShadowPathStrategy = .automatic,
    contentInsets: NSDirectionalEdgeInsets = .init(top: 7, leading: 12, bottom: 7, trailing: 12),
    clipsToBounds: Bool? = nil,
    interaction: FKButtonInteractionStyle = .default
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

  /// Returns a merged appearance.
  public func merged(with override: FKButtonAppearanceOverride) -> FKButtonAppearance {
    let mergedGradient: FKButtonLinearGradient? = {
      switch override.backgroundGradient {
      case nil: return backgroundGradient
      case .some(let value): return value
      }
    }()

    return FKButtonAppearance(
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

  public static func filled(
    backgroundColor: UIColor,
    borderColor: UIColor = .clear,
    cornerStyle: FKButtonCornerStyle = .default
  ) -> FKButtonAppearance {
    FKButtonAppearance(
      cornerStyle: cornerStyle,
      border: FKButtonBorderStyle(width: 0, color: borderColor),
      backgroundColor: backgroundColor
    )
  }

  public static func outlined(
    borderColor: UIColor,
    borderWidth: CGFloat = 1,
    cornerStyle: FKButtonCornerStyle = .default
  ) -> FKButtonAppearance {
    FKButtonAppearance(
      cornerStyle: cornerStyle,
      border: FKButtonBorderStyle(width: borderWidth, color: borderColor),
      backgroundColor: .clear
    )
  }

  public static func ghost(cornerStyle: FKButtonCornerStyle = .default) -> FKButtonAppearance {
    FKButtonAppearance(cornerStyle: cornerStyle, border: .clear, backgroundColor: .clear)
  }

  public static let `default` = FKButtonAppearance()
}

/// Bundle of state appearances.
public struct FKButtonStateAppearances: Equatable, Sendable {
  public let normal: FKButtonAppearance
  public let selected: FKButtonAppearance
  public let highlighted: FKButtonAppearance
  public let disabled: FKButtonAppearance

  public init(
    normal: FKButtonAppearance,
    selected: FKButtonAppearance? = nil,
    highlighted: FKButtonAppearance? = nil,
    disabled: FKButtonAppearance? = nil
  ) {
    self.normal = normal
    self.selected = selected ?? normal
    self.highlighted = highlighted ?? self.selected
    self.disabled = disabled ?? normal
  }
}

/// Partial appearance override model.
public struct FKButtonAppearanceOverride: Equatable, Sendable {
  public var cornerStyle: FKButtonCornerStyle?
  public var border: FKButtonBorderStyle?
  public var backgroundColor: UIColor?
  public var backgroundGradient: FKButtonLinearGradient??
  public var alpha: CGFloat?
  public var shadow: FKButtonShadowStyle??
  public var shadowPathStrategy: FKButtonShadowPathStrategy?
  public var contentInsets: NSDirectionalEdgeInsets?
  public var clipsToBounds: Bool??
  public var interaction: FKButtonInteractionStyle?

  public init(
    cornerStyle: FKButtonCornerStyle? = nil,
    border: FKButtonBorderStyle? = nil,
    backgroundColor: UIColor? = nil,
    backgroundGradient: FKButtonLinearGradient?? = nil,
    alpha: CGFloat? = nil,
    shadow: FKButtonShadowStyle?? = nil,
    shadowPathStrategy: FKButtonShadowPathStrategy? = nil,
    contentInsets: NSDirectionalEdgeInsets? = nil,
    clipsToBounds: Bool?? = nil,
    interaction: FKButtonInteractionStyle? = nil
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
