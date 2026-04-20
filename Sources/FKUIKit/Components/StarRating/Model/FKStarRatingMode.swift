//
// FKStarRatingMode.swift
//
// Rating mode and rendering models for FKStarRating.
//

import UIKit

/// Defines how rating values snap while user is editing.
public enum FKStarRatingMode: Hashable, Sendable {
  /// Only whole star values are allowed (1.0 step).
  case full
  /// Half star values are allowed (0.5 step).
  case half
  /// Any custom decimal step is allowed.
  ///
  /// - Important: `step` is clamped to `0.01...1.0`.
  case precise(step: CGFloat)

  /// Returns normalized step value for the mode.
  public var step: CGFloat {
    switch self {
    case .full:
      return 1
    case .half:
      return 0.5
    case .precise(let step):
      return max(0.01, min(1, step))
    }
  }
}

/// Defines how star visuals should be rendered.
public enum FKStarRatingRenderMode: Hashable, Sendable {
  /// Uses image assets to render stars.
  case image
  /// Uses template rendering with tint colors.
  case color
}

/// Visual style for each star item.
public struct FKStarRatingStarStyle {
  /// Corner radius applied to each star slot.
  public var cornerRadius: CGFloat
  /// Border width applied to each star slot.
  public var borderWidth: CGFloat
  /// Border color applied to each star slot.
  public var borderColor: UIColor
  /// Shadow color for each star slot.
  public var shadowColor: UIColor
  /// Shadow opacity for each star slot.
  public var shadowOpacity: Float
  /// Shadow radius for each star slot.
  public var shadowRadius: CGFloat
  /// Shadow offset for each star slot.
  public var shadowOffset: CGSize

  /// Creates style for star slot visual decoration.
  public init(
    cornerRadius: CGFloat = 0,
    borderWidth: CGFloat = 0,
    borderColor: UIColor = .clear,
    shadowColor: UIColor = .clear,
    shadowOpacity: Float = 0,
    shadowRadius: CGFloat = 0,
    shadowOffset: CGSize = .zero
  ) {
    self.cornerRadius = max(0, cornerRadius)
    self.borderWidth = max(0, borderWidth)
    self.borderColor = borderColor
    self.shadowColor = shadowColor
    self.shadowOpacity = max(0, min(1, shadowOpacity))
    self.shadowRadius = max(0, shadowRadius)
    self.shadowOffset = shadowOffset
  }

  /// Empty style with no corner, border, or shadow.
  ///
  /// A computed property is used to avoid sharing non-Sendable storage
  /// under strict Swift concurrency checks.
  public static var plain: FKStarRatingStarStyle {
    FKStarRatingStarStyle()
  }
}
