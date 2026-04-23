import UIKit

/// Text provider for localization-friendly default strings.
public struct FKToastLocalizedText: Sendable, Equatable {
  /// Default title for a dismiss action.
  public var dismissAction: String
  /// Default title for a retry action.
  public var retryAction: String
  /// Default text for loading states.
  public var loadingText: String

  /// Creates a localization payload that can be replaced by app-level strings.
  public init(dismissAction: String = "Dismiss", retryAction: String = "Retry", loadingText: String = "Loading…") {
    self.dismissAction = dismissAction
    self.retryAction = retryAction
    self.loadingText = loadingText
  }
}

/// Action descriptor for snackbar and custom toast interactions.
public struct FKToastAction: Sendable, Equatable {
  /// Action title rendered in the action button.
  public var title: String
  /// Foreground color for the action title.
  public var titleColor: UIColor
  /// Optional accessibility override announced by VoiceOver.
  public var accessibilityLabel: String?

  public init(title: String, titleColor: UIColor = .white, accessibilityLabel: String? = nil) {
    self.title = title
    self.titleColor = titleColor
    self.accessibilityLabel = accessibilityLabel
  }
}

/// Lifecycle callbacks for one request.
public struct FKToastLifecycleHooks: Sendable {
  /// Called right before entering animation.
  public var willShow: (@MainActor (UUID) -> Void)?
  /// Called when entering animation completes.
  public var didShow: (@MainActor (UUID) -> Void)?
  /// Called right before dismissal begins.
  public var willDismiss: (@MainActor (UUID, FKToastDismissReason) -> Void)?
  /// Called after dismissal cleanup completes.
  public var didDismiss: (@MainActor (UUID, FKToastDismissReason) -> Void)?

  public init(
    willShow: (@MainActor (UUID) -> Void)? = nil,
    didShow: (@MainActor (UUID) -> Void)? = nil,
    willDismiss: (@MainActor (UUID, FKToastDismissReason) -> Void)? = nil,
    didDismiss: (@MainActor (UUID, FKToastDismissReason) -> Void)? = nil
  ) {
    self.willShow = willShow
    self.didShow = didShow
    self.willDismiss = willDismiss
    self.didDismiss = didDismiss
  }
}

/// Queue behavior and deduplication tuning.
public struct FKToastQueueConfiguration: Sendable, Equatable {
  /// Maximum number of overlays shown at once.
  public var maxConcurrentDisplayCount: Int
  /// Policy used when a new request arrives during display.
  public var arrivalPolicy: FKToastArrivalPolicy
  /// Time window for duplicate coalescing.
  public var deduplicationWindow: TimeInterval
  /// Enables higher priority request preemption.
  public var allowPriorityPreemption: Bool

  public init(
    maxConcurrentDisplayCount: Int = 1,
    arrivalPolicy: FKToastArrivalPolicy = .queue,
    deduplicationWindow: TimeInterval = 2.5,
    allowPriorityPreemption: Bool = true
  ) {
    self.maxConcurrentDisplayCount = max(1, maxConcurrentDisplayCount)
    self.arrivalPolicy = arrivalPolicy
    self.deduplicationWindow = max(0, deduplicationWindow)
    self.allowPriorityPreemption = allowPriorityPreemption
  }
}

/// Per-request configuration for Toast/HUD/Snackbar.
public struct FKToastConfiguration: Sendable, Equatable {
  /// Overlay category.
  public var kind: FKToastKind
  /// Semantic style.
  public var style: FKToastStyle
  /// Priority in scheduling and preemption.
  public var priority: FKToastPriority
  /// Optional explicit position.
  public var position: FKToastPosition?
  /// Auto-dismiss duration.
  public var duration: TimeInterval
  /// Safety timeout, usually used by HUDs.
  public var timeout: TimeInterval?
  /// Transition animation duration.
  public var animationDuration: TimeInterval
  /// Transition animation style.
  public var animationStyle: FKToastAnimationStyle
  /// Maximum width ratio against window width.
  public var maxWidthRatio: CGFloat
  /// Exterior spacing from safe area.
  public var outerInsets: NSDirectionalEdgeInsets
  /// Content padding.
  public var contentInsets: NSDirectionalEdgeInsets
  /// Horizontal spacing between items.
  public var itemSpacing: CGFloat
  /// Subtitle/body font.
  public var font: UIFont
  /// Title font for title-subtitle payload.
  public var titleFont: UIFont
  /// Foreground text color.
  public var textColor: UIColor
  /// Background color override.
  public var backgroundColor: UIColor?
  /// Icon tint override.
  public var iconTintColor: UIColor?
  /// Optional semantic symbol override set.
  public var symbolSet: FKToastSymbolSet?
  /// Corner radius override.
  public var cornerRadius: CGFloat?
  /// Enables container shadow.
  public var showsShadow: Bool
  /// Shadow opacity.
  public var shadowOpacity: Float
  /// Shadow blur radius.
  public var shadowRadius: CGFloat
  /// Shadow offset.
  public var shadowOffset: CGSize
  /// Tap dismissal behavior.
  public var tapToDismiss: Bool
  /// Long-press dismissal behavior.
  public var longPressToDismiss: Bool
  /// Swipe dismissal behavior.
  public var swipeToDismiss: Bool
  /// Whether this request intercepts background touches.
  public var interceptTouches: Bool
  /// Passthrough rectangles when intercepting touches.
  public var passthroughRects: [CGRect]
  /// Additional Y offset.
  public var verticalOffset: CGFloat
  /// Top spacing when a visible navigation bar exists.
  public var topInsetWhenHasNavigationBar: CGFloat
  /// Top spacing when no visible navigation bar exists.
  public var topInsetFromSafeArea: CGFloat
  /// Bottom spacing when a visible tab bar exists.
  public var bottomInsetWhenHasTabBar: CGFloat
  /// Bottom spacing when no visible tab bar exists.
  public var bottomInsetFromSafeArea: CGFloat
  /// Primary action.
  public var action: FKToastAction?
  /// Secondary action.
  public var secondaryAction: FKToastAction?
  /// Queue policy for this request.
  public var queue: FKToastQueueConfiguration
  /// Whether to post VoiceOver announcements automatically.
  public var accessibilityAnnouncementEnabled: Bool
  /// Background visual effect policy.
  public var backgroundVisualEffect: FKToastBackgroundVisualEffect
  /// Opacity applied to visual-effect view.
  public var visualEffectOpacity: CGFloat
  /// Fallback to solid color when transparency should be reduced.
  public var fallbackToSolidColorWhenReduceTransparencyEnabled: Bool
  /// Disable visual effects while Low Power Mode is enabled.
  public var disableVisualEffectInLowPowerMode: Bool
  /// Localized fallback text payload.
  public var localizedText: FKToastLocalizedText

  /// Creates a configuration tuned for production overlays.
  ///
  /// - Important: UI mutations are always performed on the main actor, but this value type can be
  ///   prepared on any thread and passed safely into the queue.
  public init(
    kind: FKToastKind = .toast,
    style: FKToastStyle = .normal,
    priority: FKToastPriority = .normal,
    position: FKToastPosition? = nil,
    duration: TimeInterval = 2,
    timeout: TimeInterval? = nil,
    animationDuration: TimeInterval = 0.25,
    animationStyle: FKToastAnimationStyle = .slide,
    maxWidthRatio: CGFloat = 0.92,
    outerInsets: NSDirectionalEdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16),
    contentInsets: NSDirectionalEdgeInsets = .init(top: 12, leading: 14, bottom: 12, trailing: 14),
    itemSpacing: CGFloat = 10,
    font: UIFont = .preferredFont(forTextStyle: .subheadline),
    titleFont: UIFont = .preferredFont(forTextStyle: .headline),
    textColor: UIColor = .white,
    backgroundColor: UIColor? = nil,
    iconTintColor: UIColor? = nil,
    symbolSet: FKToastSymbolSet? = nil,
    cornerRadius: CGFloat? = nil,
    showsShadow: Bool = true,
    shadowOpacity: Float = 0.22,
    shadowRadius: CGFloat = 12,
    shadowOffset: CGSize = .init(width: 0, height: 6),
    tapToDismiss: Bool = true,
    longPressToDismiss: Bool = false,
    swipeToDismiss: Bool = true,
    interceptTouches: Bool = false,
    passthroughRects: [CGRect] = [],
    verticalOffset: CGFloat = 0,
    topInsetWhenHasNavigationBar: CGFloat = 8,
    topInsetFromSafeArea: CGFloat = 10,
    bottomInsetWhenHasTabBar: CGFloat = 8,
    bottomInsetFromSafeArea: CGFloat = 10,
    action: FKToastAction? = nil,
    secondaryAction: FKToastAction? = nil,
    queue: FKToastQueueConfiguration = .init(),
    accessibilityAnnouncementEnabled: Bool = true,
    backgroundVisualEffect: FKToastBackgroundVisualEffect = .none,
    visualEffectOpacity: CGFloat = 1,
    fallbackToSolidColorWhenReduceTransparencyEnabled: Bool = true,
    disableVisualEffectInLowPowerMode: Bool = false,
    localizedText: FKToastLocalizedText = .init()
  ) {
    self.kind = kind
    self.style = style
    self.priority = priority
    self.position = position
    self.duration = duration
    self.timeout = timeout
    self.animationDuration = max(0.05, animationDuration)
    self.animationStyle = animationStyle
    self.maxWidthRatio = min(max(maxWidthRatio, 0.4), 1)
    self.outerInsets = outerInsets
    self.contentInsets = contentInsets
    self.itemSpacing = max(0, itemSpacing)
    self.font = font
    self.titleFont = titleFont
    self.textColor = textColor
    self.backgroundColor = backgroundColor
    self.iconTintColor = iconTintColor
    self.symbolSet = symbolSet
    self.cornerRadius = cornerRadius
    self.showsShadow = showsShadow
    self.shadowOpacity = min(max(shadowOpacity, 0), 1)
    self.shadowRadius = max(0, shadowRadius)
    self.shadowOffset = shadowOffset
    self.tapToDismiss = tapToDismiss
    self.longPressToDismiss = longPressToDismiss
    self.swipeToDismiss = swipeToDismiss
    self.interceptTouches = interceptTouches
    self.passthroughRects = passthroughRects
    self.verticalOffset = verticalOffset
    self.topInsetWhenHasNavigationBar = topInsetWhenHasNavigationBar
    self.topInsetFromSafeArea = topInsetFromSafeArea
    self.bottomInsetWhenHasTabBar = bottomInsetWhenHasTabBar
    self.bottomInsetFromSafeArea = bottomInsetFromSafeArea
    self.action = action
    self.secondaryAction = secondaryAction
    self.queue = queue
    self.accessibilityAnnouncementEnabled = accessibilityAnnouncementEnabled
    self.backgroundVisualEffect = backgroundVisualEffect
    self.visualEffectOpacity = min(max(visualEffectOpacity, 0), 1)
    self.fallbackToSolidColorWhenReduceTransparencyEnabled = fallbackToSolidColorWhenReduceTransparencyEnabled
    self.disableVisualEffectInLowPowerMode = disableVisualEffectInLowPowerMode
    self.localizedText = localizedText
  }
}
