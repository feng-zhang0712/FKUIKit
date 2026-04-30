import UIKit

/// Top-level configuration that describes what kind of presentation experience to build.
public struct FKPresentationConfiguration {
  /// Placement and mode-specific sizing behavior.
  public var layout: Layout
  /// Safe area adaptation policy.
  public var safeAreaPolicy: FKSafeAreaPolicy
  /// Container corner radius.
  public var cornerRadius: CGFloat
  /// Container shadow appearance.
  public var shadow: ShadowConfiguration
  /// Container border appearance.
  public var border: BorderConfiguration
  /// Backdrop visual style.
  public var backdropStyle: FKBackdropStyle
  /// Background interaction policy.
  public var backgroundInteraction: BackgroundInteractionConfiguration
  /// Optional effects applied to the presenting view.
  public var presentingViewEffect: PresentingViewEffectConfiguration
  /// Dismiss behavior toggles for taps and gestures.
  public var dismissBehavior: DismissBehavior
  /// Keyboard avoidance strategy.
  public var keyboardAvoidance: KeyboardAvoidanceConfiguration
  /// Rotation handling strategy.
  public var rotationHandling: RotationHandling
  /// Preferred content size policy.
  public var preferredContentSizePolicy: PreferredContentSizePolicy
  /// Sheet behavior. For non-sheet layouts, a default sheet configuration is synthesized.
  public var sheet: SheetConfiguration {
    get {
      switch layout {
      case let .bottomSheet(configuration), let .topSheet(configuration):
        return configuration
      default:
        return .init()
      }
    }
    set {
      switch layout {
      case .topSheet(_):
        layout = .topSheet(newValue)
      default:
        layout = .bottomSheet(newValue)
      }
    }
  }
  /// Center behavior. For non-center layouts, a default center configuration is synthesized.
  public var center: CenterConfiguration {
    get {
      if case let .center(configuration) = layout {
        return configuration
      }
      return .init()
    }
    set {
      layout = .center(newValue)
    }
  }
  /// Animation behavior.
  public var animation: FKAnimationConfiguration
  /// Insets applied around the presented content view inside the container.
  ///
  /// This controls the padding between the container chrome and your content view, and is useful for:
  /// - Menu-like overlays that should not touch the container edges
  /// - Forms/lists that want consistent internal padding
  ///
  /// - Note: This is applied in addition to safe-area handling determined by `safeAreaPolicy`.
  public var contentInsets: NSDirectionalEdgeInsets
  /// Optional haptics behavior.
  public var haptics: HapticsConfiguration
  /// Optional accessibility behavior.
  public var accessibility: AccessibilityConfiguration

  /// Creates a production-ready configuration with extensible sub-configurations.
  public init(
    layout: Layout = .bottomSheet(.init()),
    safeAreaPolicy: FKSafeAreaPolicy = .contentRespectsSafeArea,
    cornerRadius: CGFloat = 16,
    shadow: ShadowConfiguration = .init(),
    border: BorderConfiguration = .init(),
    backdropStyle: FKBackdropStyle = .dim(alpha: 0.35),
    backgroundInteraction: BackgroundInteractionConfiguration = .init(),
    presentingViewEffect: PresentingViewEffectConfiguration = .init(),
    dismissBehavior: DismissBehavior = .init(),
    keyboardAvoidance: KeyboardAvoidanceConfiguration = .init(),
    rotationHandling: RotationHandling = .relayoutAnimated,
    preferredContentSizePolicy: PreferredContentSizePolicy = .automatic,
    animation: FKAnimationConfiguration = .init(),
    contentInsets: NSDirectionalEdgeInsets = .zero,
    haptics: HapticsConfiguration = .init(),
    accessibility: AccessibilityConfiguration = .init()
  ) {
    self.layout = layout
    self.safeAreaPolicy = safeAreaPolicy
    self.cornerRadius = max(0, cornerRadius)
    self.shadow = shadow
    self.border = border
    self.backdropStyle = backdropStyle
    self.backgroundInteraction = backgroundInteraction
    self.presentingViewEffect = presentingViewEffect
    self.dismissBehavior = dismissBehavior
    self.keyboardAvoidance = keyboardAvoidance
    self.rotationHandling = rotationHandling
    self.preferredContentSizePolicy = preferredContentSizePolicy
    self.animation = animation
    self.contentInsets = contentInsets
    self.haptics = haptics
    self.accessibility = accessibility
  }

  /// Sensible baseline that mirrors common bottom-sheet interactions.
  public nonisolated(unsafe) static let `default` = FKPresentationConfiguration()
}

extension UIEdgeInsets {
  init(_ directional: NSDirectionalEdgeInsets) {
    self.init(top: directional.top, left: directional.leading, bottom: directional.bottom, right: directional.trailing)
  }
}
