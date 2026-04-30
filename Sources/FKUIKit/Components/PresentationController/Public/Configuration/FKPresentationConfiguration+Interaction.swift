import UIKit

public extension FKPresentationConfiguration {
  /// Unified dismissal behavior used across modal and anchor-hosted presentations.
  struct DismissBehavior {
    /// Whether tapping outside content can dismiss.
    public var allowsTapOutside: Bool
    /// Whether drag gestures can dismiss.
    public var allowsSwipe: Bool
    /// Whether backdrop tap specifically participates in dismissal.
    ///
    /// Set to `false` when you only want gesture-based outside dismissal logic.
    public var allowsBackdropTap: Bool

    public init(
      allowsTapOutside: Bool = true,
      allowsSwipe: Bool = true,
      allowsBackdropTap: Bool = true
    ) {
      self.allowsTapOutside = allowsTapOutside
      self.allowsSwipe = allowsSwipe
      self.allowsBackdropTap = allowsBackdropTap
    }
  }

  /// Background interaction policy (passthrough) for advanced overlays.
  struct BackgroundInteractionConfiguration {
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

  /// Keyboard avoidance behavior used while editing fields.
  struct KeyboardAvoidanceConfiguration {
    /// Enables keyboard tracking for container layout updates.
    public var isEnabled: Bool
    /// Avoidance strategy.
    public var strategy: FKKeyboardAvoidanceStrategy
    /// Extra spacing above keyboard.
    public var additionalBottomInset: CGFloat
    /// Optional explicit scroll view target for `.adjustContentInsets`.
    public var targetScrollView: FKWeakReference<UIScrollView>?

    /// Creates keyboard avoidance behavior.
    public init(
      isEnabled: Bool = true,
      strategy: FKKeyboardAvoidanceStrategy = .interactive,
      additionalBottomInset: CGFloat = 8,
      targetScrollView: FKWeakReference<UIScrollView>? = nil
    ) {
      self.isEnabled = isEnabled
      self.strategy = strategy
      self.additionalBottomInset = additionalBottomInset
      self.targetScrollView = targetScrollView
    }
  }
}
