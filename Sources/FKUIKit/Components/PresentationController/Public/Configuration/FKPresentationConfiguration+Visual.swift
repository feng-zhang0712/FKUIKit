import UIKit

public extension FKPresentationConfiguration {
  /// Shadow appearance used by the presented container.
  struct ShadowConfiguration {
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

  /// Border appearance for the presented container.
  struct BorderConfiguration {
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

  /// Haptics behavior around lifecycle transitions.
  struct HapticsConfiguration {
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
  struct AccessibilityConfiguration {
    /// Posts screen changed notifications after presentation.
    public var announcesScreenChange: Bool
    /// Optional label announced when content appears.
    public var announcement: String?
    /// Backdrop accessibility label.
    public var dismissLabel: String
    /// Backdrop accessibility action title.
    public var dismissActionName: String
    /// Grabber accessibility label.
    public var grabberLabel: String
    /// Grabber accessibility hint.
    public var grabberHint: String

    /// Creates accessibility behavior.
    public init(
      announcesScreenChange: Bool = true,
      announcement: String? = nil,
      dismissLabel: String = "Dismiss",
      dismissActionName: String = "Dismiss",
      grabberLabel: String = "Handle",
      grabberHint: String = "Swipe up or down to adjust."
    ) {
      self.announcesScreenChange = announcesScreenChange
      self.announcement = announcement
      self.dismissLabel = dismissLabel
      self.dismissActionName = dismissActionName
      self.grabberLabel = grabberLabel
      self.grabberHint = grabberHint
    }
  }
}
