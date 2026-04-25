import UIKit

/// Top-level configuration that describes what kind of presentation experience to build.
public struct FKPresentationConfiguration {
  /// Shadow appearance used by the presented container.
  public struct ShadowConfiguration {
    /// Shadow color.
    public var color: UIColor
    /// Shadow opacity.
    public var opacity: Float
    /// Shadow blur radius.
    public var radius: CGFloat
    /// Shadow offset.
    public var offset: CGSize

    /// Creates a shadow configuration.
    public init(
      color: UIColor = .black,
      opacity: Float = 0.18,
      radius: CGFloat = 16,
      offset: CGSize = .init(width: 0, height: 8)
    ) {
      self.color = color
      self.opacity = opacity
      self.radius = radius
      self.offset = offset
    }
  }

  /// Sheet-specific behavior and allowed heights.
  public struct SheetConfiguration {
    /// Backdrop tuning that reacts to detent state.
    public struct MultiStageBackdropConfiguration {
      /// Enables detent-based backdrop intensity updates.
      public var isEnabled: Bool
      /// Minimum backdrop alpha used at the smallest detent.
      public var minimumAlpha: CGFloat
      /// Maximum backdrop alpha used at the largest detent.
      public var maximumAlpha: CGFloat

      /// Creates multi-stage backdrop settings.
      public init(isEnabled: Bool = false, minimumAlpha: CGFloat = 0.15, maximumAlpha: CGFloat = 0.4) {
        self.isEnabled = isEnabled
        self.minimumAlpha = min(max(minimumAlpha, 0), 1)
        self.maximumAlpha = min(max(maximumAlpha, self.minimumAlpha), 1)
      }
    }

    /// Available stopping points for sheet modes.
    public var detents: [FKPresentationDetent]
    /// Initial detent index used on first display.
    public var initialDetentIndex: Int
    /// Maximum height ratio used when resolving `.fitContent`.
    public var maximumFitContentHeightFraction: CGFloat
    /// Enables a grabber/handle in the chrome area.
    public var showsGrabber: Bool
    /// Grabber size in points.
    public var grabberSize: CGSize
    /// Grabber top spacing in points.
    public var grabberTopInset: CGFloat
    /// Dismiss threshold in points beyond the min/max detent.
    public var dismissThreshold: CGFloat
    /// Velocity threshold for deciding finish/cancel in interactive transitions.
    public var dismissVelocityThreshold: CGFloat
    /// Scroll handoff strategy between content and sheet pan gestures.
    public var scrollTrackingStrategy: FKSheetScrollTrackingStrategy
    /// Enables magnetic snapping near detents.
    public var enablesMagneticSnapping: Bool
    /// Distance threshold (points) used by magnetic snapping.
    public var magneticSnapThreshold: CGFloat
    /// Optional minimum content height safety constraint.
    public var minimumContentHeight: CGFloat?
    /// Optional maximum content height safety constraint.
    public var maximumContentHeight: CGFloat?
    /// Detent-aware backdrop behavior.
    public var multiStageBackdrop: MultiStageBackdropConfiguration

    /// Creates a sheet configuration.
    public init(
      detents: [FKPresentationDetent] = [.fitContent, .full],
      initialDetentIndex: Int = 0,
      maximumFitContentHeightFraction: CGFloat = 0.9,
      showsGrabber: Bool = true,
      grabberSize: CGSize = .init(width: 36, height: 5),
      grabberTopInset: CGFloat = 8,
      dismissThreshold: CGFloat = 44,
      dismissVelocityThreshold: CGFloat = 1200,
      scrollTrackingStrategy: FKSheetScrollTrackingStrategy = .automatic,
      enablesMagneticSnapping: Bool = true,
      magneticSnapThreshold: CGFloat = 28,
      minimumContentHeight: CGFloat? = 180,
      maximumContentHeight: CGFloat? = nil,
      multiStageBackdrop: MultiStageBackdropConfiguration = .init()
    ) {
      self.detents = detents.isEmpty ? [.fitContent] : detents
      self.initialDetentIndex = max(0, min(initialDetentIndex, self.detents.count - 1))
      self.maximumFitContentHeightFraction = min(max(maximumFitContentHeightFraction, 0.2), 1)
      self.showsGrabber = showsGrabber
      self.grabberSize = grabberSize
      self.grabberTopInset = max(0, grabberTopInset)
      self.dismissThreshold = max(0, dismissThreshold)
      self.dismissVelocityThreshold = max(0, dismissVelocityThreshold)
      self.scrollTrackingStrategy = scrollTrackingStrategy
      self.enablesMagneticSnapping = enablesMagneticSnapping
      self.magneticSnapThreshold = max(0, magneticSnapThreshold)
      self.minimumContentHeight = minimumContentHeight
      self.maximumContentHeight = maximumContentHeight
      self.multiStageBackdrop = multiStageBackdrop
    }
  }

  /// Border appearance for the presented container.
  public struct BorderConfiguration {
    /// Whether border is drawn.
    public var isEnabled: Bool
    /// Border color.
    public var color: UIColor
    /// Border width.
    public var width: CGFloat

    /// Creates a border configuration.
    public init(isEnabled: Bool = false, color: UIColor? = nil, width: CGFloat = 1) {
      self.isEnabled = isEnabled
      self.color = color ?? UIColor.separator
      self.width = max(0, width)
    }
  }

  /// Background interaction policy (passthrough) for advanced overlays.
  public struct BackgroundInteractionConfiguration {
    /// Whether background interaction is allowed while presented.
    public var isEnabled: Bool
    /// Whether the backdrop still renders when interaction is enabled.
    public var showsBackdropWhenEnabled: Bool

    /// Creates background interaction configuration.
    ///
    /// - Important: When enabled, touches may pass through the backdrop. This is disabled by default for safety.
    public init(isEnabled: Bool = false, showsBackdropWhenEnabled: Bool = true) {
      self.isEnabled = isEnabled
      self.showsBackdropWhenEnabled = showsBackdropWhenEnabled
    }
  }

  /// Sizing rules for the `.center` mode.
  public struct CenterConfiguration {
    /// Size strategy for centered presentation.
    public enum Size {
      /// Uses a fixed size.
      case fixed(CGSize)
      /// Uses content-fitting size clamped by maximum bounds.
      case fitted(maxSize: CGSize)
    }

    /// Size strategy.
    public var size: Size
    /// Minimum margins against container edges (useful for iPad / large screens).
    public var minimumMargins: NSDirectionalEdgeInsets
    /// Enables swipe-to-dismiss for center mode.
    public var allowsSwipeToDismiss: Bool

    /// Creates a center configuration.
    public init(
      size: Size = .fitted(maxSize: .init(width: 460, height: 640)),
      minimumMargins: NSDirectionalEdgeInsets = .init(top: 24, leading: 24, bottom: 24, trailing: 24),
      allowsSwipeToDismiss: Bool = false
    ) {
      self.size = size
      self.minimumMargins = minimumMargins
      self.allowsSwipeToDismiss = allowsSwipeToDismiss
    }
  }

  /// Anchor rules for popover-like layouts.
  public struct AnchorConfiguration {
    /// Geometry source used to position content.
    public enum Source {
      /// Anchors to a specific view.
      case view(UIView)
      /// Anchors to a rect in window coordinates.
      case rect(CGRect)
    }

    /// Preferred edges used to expand from the source.
    public var preferredEdges: [UIRectEdge]
    /// Spacing between source and presented content.
    public var offset: UIOffset
    /// Anchor source.
    public var source: Source

    /// Creates an anchor configuration.
    public init(
      source: Source,
      preferredEdges: [UIRectEdge] = [.bottom],
      offset: UIOffset = .zero
    ) {
      self.source = source
      self.preferredEdges = preferredEdges
      self.offset = offset
    }
  }

  /// Keyboard avoidance behavior used while editing fields.
  public struct KeyboardAvoidanceConfiguration {
    /// Enables keyboard tracking for container layout updates.
    public var isEnabled: Bool
    /// Avoidance strategy.
    public var strategy: FKKeyboardAvoidanceStrategy
    /// Extra spacing above keyboard.
    public var additionalBottomInset: CGFloat

    /// Creates keyboard avoidance behavior.
    public init(
      isEnabled: Bool = true,
      strategy: FKKeyboardAvoidanceStrategy = .interactive,
      additionalBottomInset: CGFloat = 8
    ) {
      self.isEnabled = isEnabled
      self.strategy = strategy
      self.additionalBottomInset = additionalBottomInset
    }
  }

  /// Rotation handling strategy used when interface orientation changes.
  public enum RotationHandling {
    /// Relayouts and animates to the new frame.
    case relayoutAnimated
    /// Relayouts without animation.
    case relayoutImmediate
    /// Ignores orientation updates and keeps current frame.
    case ignore
  }

  /// Preferred content size policy when modes support intrinsic content.
  public enum PreferredContentSizePolicy {
    /// Uses `preferredContentSize` when available.
    case automatic
    /// Always ignores `preferredContentSize`.
    case ignore
    /// Forces `preferredContentSize` as a primary sizing hint.
    case strict
  }

  /// Haptics behavior around lifecycle transitions.
  public struct HapticsConfiguration {
    /// Whether haptics are generated.
    public var isEnabled: Bool
    /// Feedback style for completion events.
    public var feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle

    /// Creates a haptics configuration.
    public init(isEnabled: Bool = false, feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
      self.isEnabled = isEnabled
      self.feedbackStyle = feedbackStyle
    }
  }

  /// Accessibility behavior for announcements and focus.
  public struct AccessibilityConfiguration {
    /// Posts screen changed notifications after presentation.
    public var announcesScreenChange: Bool
    /// Optional label announced when content appears.
    public var announcement: String?

    /// Creates accessibility behavior.
    public init(announcesScreenChange: Bool = true, announcement: String? = nil) {
      self.announcesScreenChange = announcesScreenChange
      self.announcement = announcement
    }
  }

  /// Placement mode.
  public var mode: FKPresentationMode
  /// Safe area adaptation policy.
  public var safeAreaPolicy: FKSafeAreaPolicy
  /// Container corner radius.
  public var cornerRadius: CGFloat
  /// Container shadow appearance.
  public var shadow: ShadowConfiguration
  /// Container border appearance.
  public var border: BorderConfiguration
  /// Backdrop style and behavior.
  public var backdrop: BackdropConfiguration
  /// Background interaction policy.
  public var backgroundInteraction: BackgroundInteractionConfiguration
  /// Optional effects applied to the presenting view.
  public var presentingViewEffect: PresentingViewEffectConfiguration
  /// Enables tap-to-dismiss behavior.
  public var allowsTapToDismiss: Bool
  /// Enables swipe-to-dismiss behavior.
  public var allowsSwipeToDismiss: Bool
  /// Keyboard avoidance strategy.
  public var keyboardAvoidance: KeyboardAvoidanceConfiguration
  /// Rotation handling strategy.
  public var rotationHandling: RotationHandling
  /// Preferred content size policy.
  public var preferredContentSizePolicy: PreferredContentSizePolicy
  /// Sheet behavior.
  public var sheet: SheetConfiguration
  /// Center behavior.
  public var center: CenterConfiguration
  /// Optional anchor behavior for anchor modes.
  public var anchor: AnchorConfiguration?
  /// Animation behavior.
  public var animation: FKAnimationConfiguration
  /// Optional haptics behavior.
  public var haptics: HapticsConfiguration
  /// Optional accessibility behavior.
  public var accessibility: AccessibilityConfiguration

  /// Creates a production-ready configuration with extensible sub-configurations.
  public init(
    mode: FKPresentationMode = .bottomSheet,
    safeAreaPolicy: FKSafeAreaPolicy = .contentRespectsSafeArea,
    cornerRadius: CGFloat = 16,
    shadow: ShadowConfiguration = .init(),
    border: BorderConfiguration = .init(),
    backdrop: BackdropConfiguration = .init(),
    backgroundInteraction: BackgroundInteractionConfiguration = .init(),
    presentingViewEffect: PresentingViewEffectConfiguration = .init(),
    allowsTapToDismiss: Bool = true,
    allowsSwipeToDismiss: Bool = true,
    keyboardAvoidance: KeyboardAvoidanceConfiguration = .init(),
    rotationHandling: RotationHandling = .relayoutAnimated,
    preferredContentSizePolicy: PreferredContentSizePolicy = .automatic,
    sheet: SheetConfiguration = .init(),
    center: CenterConfiguration = .init(),
    anchor: AnchorConfiguration? = nil,
    animation: FKAnimationConfiguration = .init(),
    haptics: HapticsConfiguration = .init(),
    accessibility: AccessibilityConfiguration = .init()
  ) {
    self.mode = mode
    self.safeAreaPolicy = safeAreaPolicy
    self.cornerRadius = max(0, cornerRadius)
    self.shadow = shadow
    self.border = border
    self.backdrop = backdrop
    self.backgroundInteraction = backgroundInteraction
    self.presentingViewEffect = presentingViewEffect
    self.allowsTapToDismiss = allowsTapToDismiss
    self.allowsSwipeToDismiss = allowsSwipeToDismiss
    self.keyboardAvoidance = keyboardAvoidance
    self.rotationHandling = rotationHandling
    self.preferredContentSizePolicy = preferredContentSizePolicy
    self.sheet = sheet
    self.center = center
    self.anchor = anchor
    self.animation = animation
    self.haptics = haptics
    self.accessibility = accessibility
  }

  /// Sensible baseline that mirrors common bottom-sheet interactions.
  public nonisolated(unsafe) static let `default` = FKPresentationConfiguration()
}
