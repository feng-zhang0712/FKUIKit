import UIKit

/// Optional action button configuration for snackbar/toast.
public struct FKToastAction: Sendable, Equatable {
  /// Action title.
  public var title: String
  /// Action title color.
  public var titleColor: UIColor

  /// Creates a toast action model.
  ///
  /// - Parameters:
  ///   - title: Action button title.
  ///   - titleColor: Action text color. Defaults to white.
  public init(title: String, titleColor: UIColor = .white) {
    self.title = title
    self.titleColor = titleColor
  }
}

/// Per-message configuration for FKToast display.
public struct FKToastConfiguration: Sendable, Equatable {
  /// Presentation form (`toast` or `snackbar`).
  public var kind: FKToastKind
  /// Visual style.
  public var style: FKToastStyle
  /// Optional explicit position. If `nil`, FKToast chooses by `kind`.
  ///
  /// - Note: When `nil`, FKToast defaults to `.center` for `.toast` and `.bottom` for `.snackbar`.
  public var position: FKToastPosition?
  /// Auto-dismiss duration. Set `<= 0` to keep visible until user interaction.
  ///
  /// - Note: Persistent messages should typically enable either `tapToDismiss`, `swipeToDismiss`,
  ///   or provide an `action` to avoid trapping the user.
  public var duration: TimeInterval
  /// Entrance/exit animation duration.
  public var animationDuration: TimeInterval
  /// Transition style.
  public var animationStyle: FKToastAnimationStyle
  /// Maximum width ratio against window width.
  public var maxWidthRatio: CGFloat
  /// Outer margin to screen safe area.
  public var outerInsets: NSDirectionalEdgeInsets
  /// Internal content padding.
  public var contentInsets: NSDirectionalEdgeInsets
  /// Space between icon/text/action.
  public var itemSpacing: CGFloat
  /// Base text font.
  public var font: UIFont
  /// Text color.
  public var textColor: UIColor
  /// Optional background override. Uses style color when `nil`.
  public var backgroundColor: UIColor?
  /// Optional icon tint override. Uses text color when `nil`.
  public var iconTintColor: UIColor?
  /// Optional explicit corner radius. Uses adaptive defaults when `nil`.
  public var cornerRadius: CGFloat?
  /// Whether to enable drop shadow.
  public var showsShadow: Bool
  /// Shadow opacity.
  public var shadowOpacity: Float
  /// Shadow blur radius.
  public var shadowRadius: CGFloat
  /// Shadow offset.
  public var shadowOffset: CGSize
  /// Tap to dismiss behavior.
  public var tapToDismiss: Bool
  /// Swipe to dismiss behavior.
  public var swipeToDismiss: Bool
  /// Additional vertical offset relative to computed position.
  public var verticalOffset: CGFloat
  /// Optional snackbar action.
  ///
  /// - Important: Supplying an action without providing an `actionHandler` means the button will
  ///   still dismiss the toast but will not execute additional app logic.
  public var action: FKToastAction?

  /// Creates a toast configuration.
  ///
  /// Default values are tuned for iOS-like toast/snackbar presentation and adapt to safe areas.
  ///
  /// - Parameters:
  ///   - kind: Presentation form.
  ///   - style: Preset style level.
  ///   - position: Optional explicit placement. Defaults by `kind` when `nil`.
  ///   - duration: Auto-dismiss duration in seconds. Set `<= 0` for persistent display.
  ///   - animationDuration: Entrance/exit animation duration.
  ///   - animationStyle: Transition style.
  ///   - maxWidthRatio: Max width ratio relative to the window width.
  ///   - outerInsets: Margins relative to the safe area.
  ///   - contentInsets: Internal padding for the content.
  ///   - itemSpacing: Spacing between icon, text, and action.
  ///   - font: Message font.
  ///   - textColor: Message text color.
  ///   - backgroundColor: Optional background override.
  ///   - iconTintColor: Optional icon tint override.
  ///   - cornerRadius: Optional corner radius override.
  ///   - showsShadow: Whether to render drop shadow.
  ///   - shadowOpacity: Shadow opacity (0...1).
  ///   - shadowRadius: Shadow blur radius.
  ///   - shadowOffset: Shadow offset.
  ///   - tapToDismiss: Whether tapping the toast dismisses it.
  ///   - swipeToDismiss: Whether swiping the toast dismisses it.
  ///   - verticalOffset: Additional vertical offset applied to the resolved position.
  ///   - action: Optional action button model.
  public init(
    kind: FKToastKind = .toast,
    style: FKToastStyle = .normal,
    position: FKToastPosition? = nil,
    duration: TimeInterval = 2.0,
    animationDuration: TimeInterval = 0.25,
    animationStyle: FKToastAnimationStyle = .slide,
    maxWidthRatio: CGFloat = 0.92,
    outerInsets: NSDirectionalEdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16),
    contentInsets: NSDirectionalEdgeInsets = .init(top: 12, leading: 14, bottom: 12, trailing: 14),
    itemSpacing: CGFloat = 10,
    font: UIFont = .preferredFont(forTextStyle: .subheadline),
    textColor: UIColor = .white,
    backgroundColor: UIColor? = nil,
    iconTintColor: UIColor? = nil,
    cornerRadius: CGFloat? = nil,
    showsShadow: Bool = true,
    shadowOpacity: Float = 0.22,
    shadowRadius: CGFloat = 12,
    shadowOffset: CGSize = .init(width: 0, height: 6),
    tapToDismiss: Bool = true,
    swipeToDismiss: Bool = true,
    verticalOffset: CGFloat = 0,
    action: FKToastAction? = nil
  ) {
    self.kind = kind
    self.style = style
    self.position = position
    self.duration = duration
    self.animationDuration = max(0.05, animationDuration)
    self.animationStyle = animationStyle
    self.maxWidthRatio = min(max(maxWidthRatio, 0.4), 1.0)
    self.outerInsets = outerInsets
    self.contentInsets = contentInsets
    self.itemSpacing = max(0, itemSpacing)
    self.font = font
    self.textColor = textColor
    self.backgroundColor = backgroundColor
    self.iconTintColor = iconTintColor
    self.cornerRadius = cornerRadius
    self.showsShadow = showsShadow
    self.shadowOpacity = min(max(shadowOpacity, 0), 1)
    self.shadowRadius = max(0, shadowRadius)
    self.shadowOffset = shadowOffset
    self.tapToDismiss = tapToDismiss
    self.swipeToDismiss = swipeToDismiss
    self.verticalOffset = verticalOffset
    self.action = action
  }
}
