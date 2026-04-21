import UIKit

/// Optional trailing action displayed on a top notification.
public struct FKTopNotificationAction: Sendable, Equatable {
  /// Action title.
  public var title: String
  /// Action title color.
  public var titleColor: UIColor

  /// Creates an action configuration.
  ///
  /// - Parameters:
  ///   - title: Action button title.
  ///   - titleColor: Action title color.
  public init(title: String, titleColor: UIColor = .white) {
    self.title = title
    self.titleColor = titleColor
  }
}

/// Visual style level for top notifications.
public enum FKTopNotificationStyle: Sendable, Equatable {
  /// Neutral style for generic informational feedback.
  case normal
  /// Positive style for success feedback.
  case success
  /// Negative style for failures and blocking errors.
  case error
  /// Caution style for warnings that require attention.
  case warning
  /// Informational style for secondary notices.
  case info

  /// Default SF Symbol name for this style.
  public var defaultSymbolName: String {
    switch self {
    case .normal: return "bell.fill"
    case .success: return "checkmark.circle.fill"
    case .error: return "xmark.octagon.fill"
    case .warning: return "exclamationmark.triangle.fill"
    case .info: return "info.circle.fill"
    }
  }

  /// Dynamic default background color for this style.
  public var defaultBackgroundColor: UIColor {
    switch self {
    case .normal:
      return UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(white: 0.16, alpha: 1.0) : UIColor(white: 0.08, alpha: 1.0)
      }
    case .success:
      return UIColor { trait in
        trait.userInterfaceStyle == .dark
          ? UIColor(red: 0.10, green: 0.42, blue: 0.24, alpha: 1.0)
          : UIColor(red: 0.14, green: 0.58, blue: 0.30, alpha: 1.0)
      }
    case .error:
      return UIColor { trait in
        trait.userInterfaceStyle == .dark
          ? UIColor(red: 0.52, green: 0.16, blue: 0.18, alpha: 1.0)
          : UIColor(red: 0.80, green: 0.22, blue: 0.25, alpha: 1.0)
      }
    case .warning:
      return UIColor { trait in
        trait.userInterfaceStyle == .dark
          ? UIColor(red: 0.48, green: 0.35, blue: 0.06, alpha: 1.0)
          : UIColor(red: 0.74, green: 0.52, blue: 0.10, alpha: 1.0)
      }
    case .info:
      return UIColor { trait in
        trait.userInterfaceStyle == .dark
          ? UIColor(red: 0.14, green: 0.34, blue: 0.56, alpha: 1.0)
          : UIColor(red: 0.16, green: 0.48, blue: 0.80, alpha: 1.0)
      }
    }
  }
}

/// Priority used by queue scheduling.
public enum FKTopNotificationPriority: Int, Sendable, Comparable {
  /// Lowest queue priority. Suitable for background or non-urgent notices.
  case low = 0
  /// Default queue priority for regular notifications.
  case normal = 1
  /// High queue priority that should be presented earlier than normal messages.
  case high = 2
  /// Highest queue priority used for critical interruption-level notices.
  case critical = 3

  /// Compares two priorities using their raw values.
  ///
  /// - Parameters:
  ///   - lhs: Left-hand priority.
  ///   - rhs: Right-hand priority.
  /// - Returns: `true` when `lhs` is lower than `rhs`.
  public static func < (lhs: FKTopNotificationPriority, rhs: FKTopNotificationPriority) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}

/// Built-in transition style.
public enum FKTopNotificationAnimationStyle: Sendable, Equatable {
  /// Alpha-only transition.
  case fade
  /// Vertical slide with alpha transition.
  case slide
}

/// Timing curve used by animation.
public enum FKTopNotificationAnimationCurve: Sendable, Equatable {
  /// Smooth ease-in-out curve.
  case easeInOut
  /// Fast start, slow end curve.
  case easeOut
  /// Slow start, fast end curve.
  case easeIn
  /// Constant-speed linear curve.
  case linear

  /// UIKit animation options mapped from this curve.
  var options: UIView.AnimationOptions {
    switch self {
    case .easeInOut: return [.curveEaseInOut, .beginFromCurrentState]
    case .easeOut: return [.curveEaseOut, .beginFromCurrentState]
    case .easeIn: return [.curveEaseIn, .beginFromCurrentState]
    case .linear: return [.curveLinear, .beginFromCurrentState]
    }
  }
}

/// Sound behavior for notification show event.
public enum FKTopNotificationSound: Sendable, Equatable {
  /// Do not play sound.
  case none
  /// Play system default mail sent sound.
  case `default`
  /// Play custom file URL.
  case custom(url: URL)
}

/// Per-message configuration for top notifications.
public struct FKTopNotificationConfiguration: Sendable, Equatable {
  /// Visual style level used when no fully custom color is provided.
  public var style: FKTopNotificationStyle
  /// Queue priority level used by the scheduling center.
  public var priority: FKTopNotificationPriority
  /// Auto-dismiss duration in seconds. Set `<= 0` for persistent display.
  public var duration: TimeInterval
  /// Transition style for show/hide animations.
  public var animationStyle: FKTopNotificationAnimationStyle
  /// Animation duration in seconds.
  public var animationDuration: TimeInterval
  /// Animation timing curve.
  public var animationCurve: FKTopNotificationAnimationCurve
  /// Maximum notification width ratio relative to the host window.
  public var maxWidthRatio: CGFloat
  /// Outer insets from the safe area.
  public var outerInsets: NSDirectionalEdgeInsets
  /// Internal content padding.
  public var contentInsets: NSDirectionalEdgeInsets
  /// Spacing between icon, text block, and action button.
  public var itemSpacing: CGFloat
  /// Card corner radius.
  public var cornerRadius: CGFloat
  /// Font used by the title text.
  public var font: UIFont
  /// Font used by the subtitle text.
  public var subtitleFont: UIFont
  /// Color used by the title text.
  public var textColor: UIColor
  /// Color used by the subtitle text.
  public var subtitleColor: UIColor
  /// Optional card background override. Uses style background when `nil`.
  public var backgroundColor: UIColor?
  /// Optional icon tint override. Uses `textColor` when `nil`.
  public var iconTintColor: UIColor?
  /// Optional progress bar tint override.
  public var progressTintColor: UIColor?
  /// Optional progress bar track color override.
  public var progressTrackColor: UIColor?
  /// Whether card shadow is enabled.
  public var showsShadow: Bool
  /// Shadow opacity in range `0...1`.
  public var shadowOpacity: Float
  /// Shadow blur radius.
  public var shadowRadius: CGFloat
  /// Shadow offset.
  public var shadowOffset: CGSize
  /// Whether tapping the notification body dismisses it.
  public var tapToDismiss: Bool
  /// Whether upward swipe dismiss gesture is enabled.
  public var swipeToDismiss: Bool
  /// Sound behavior triggered when the notification is presented.
  public var sound: FKTopNotificationSound
  /// Optional trailing action button configuration.
  public var action: FKTopNotificationAction?

  /// Creates a notification configuration.
  ///
  /// - Parameters:
  ///   - style: Visual style level.
  ///   - priority: Queue scheduling priority.
  ///   - duration: Auto-dismiss duration in seconds. Set `<= 0` for persistent mode.
  ///   - animationStyle: Show/hide transition style.
  ///   - animationDuration: Transition duration in seconds.
  ///   - animationCurve: Animation timing curve.
  ///   - maxWidthRatio: Maximum width ratio relative to the host window.
  ///   - outerInsets: Insets from safe-area edges.
  ///   - contentInsets: Internal content padding.
  ///   - itemSpacing: Horizontal spacing between arranged elements.
  ///   - cornerRadius: Card corner radius.
  ///   - font: Title font.
  ///   - subtitleFont: Subtitle font.
  ///   - textColor: Title text color.
  ///   - subtitleColor: Subtitle text color.
  ///   - backgroundColor: Optional background override.
  ///   - iconTintColor: Optional icon tint override.
  ///   - progressTintColor: Optional progress tint override.
  ///   - progressTrackColor: Optional progress track color override.
  ///   - showsShadow: Whether shadow is enabled.
  ///   - shadowOpacity: Shadow opacity.
  ///   - shadowRadius: Shadow blur radius.
  ///   - shadowOffset: Shadow offset.
  ///   - tapToDismiss: Whether body tap dismisses the notification.
  ///   - swipeToDismiss: Whether upward swipe dismiss is enabled.
  ///   - sound: Sound behavior during presentation.
  ///   - action: Optional trailing action model.
  public init(
    style: FKTopNotificationStyle = .normal,
    priority: FKTopNotificationPriority = .normal,
    duration: TimeInterval = 2.5,
    animationStyle: FKTopNotificationAnimationStyle = .slide,
    animationDuration: TimeInterval = 0.28,
    animationCurve: FKTopNotificationAnimationCurve = .easeOut,
    maxWidthRatio: CGFloat = 0.94,
    outerInsets: NSDirectionalEdgeInsets = .init(top: 10, leading: 12, bottom: 0, trailing: 12),
    contentInsets: NSDirectionalEdgeInsets = .init(top: 12, leading: 14, bottom: 12, trailing: 14),
    itemSpacing: CGFloat = 10,
    cornerRadius: CGFloat = 14,
    font: UIFont = .preferredFont(forTextStyle: .subheadline),
    subtitleFont: UIFont = .preferredFont(forTextStyle: .caption1),
    textColor: UIColor = .white,
    subtitleColor: UIColor = UIColor(white: 1, alpha: 0.86),
    backgroundColor: UIColor? = nil,
    iconTintColor: UIColor? = nil,
    progressTintColor: UIColor? = nil,
    progressTrackColor: UIColor? = nil,
    showsShadow: Bool = true,
    shadowOpacity: Float = 0.20,
    shadowRadius: CGFloat = 14,
    shadowOffset: CGSize = .init(width: 0, height: 8),
    tapToDismiss: Bool = true,
    swipeToDismiss: Bool = true,
    sound: FKTopNotificationSound = .none,
    action: FKTopNotificationAction? = nil
  ) {
    self.style = style
    self.priority = priority
    self.duration = duration
    self.animationStyle = animationStyle
    self.animationDuration = max(0.05, animationDuration)
    self.animationCurve = animationCurve
    self.maxWidthRatio = min(max(0.4, maxWidthRatio), 1)
    self.outerInsets = outerInsets
    self.contentInsets = contentInsets
    self.itemSpacing = max(0, itemSpacing)
    self.cornerRadius = max(0, cornerRadius)
    self.font = font
    self.subtitleFont = subtitleFont
    self.textColor = textColor
    self.subtitleColor = subtitleColor
    self.backgroundColor = backgroundColor
    self.iconTintColor = iconTintColor
    self.progressTintColor = progressTintColor
    self.progressTrackColor = progressTrackColor
    self.showsShadow = showsShadow
    self.shadowOpacity = min(max(0, shadowOpacity), 1)
    self.shadowRadius = max(0, shadowRadius)
    self.shadowOffset = shadowOffset
    self.tapToDismiss = tapToDismiss
    self.swipeToDismiss = swipeToDismiss
    self.sound = sound
    self.action = action
  }
}
