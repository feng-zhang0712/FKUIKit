import UIKit

/// Haptics configuration for `FKButton`.
public struct FKButtonHapticsConfiguration: Sendable {
  /// When enabled, emits a light impact on press-down highlight.
  public var onPressDown: Bool
  /// When enabled, emits a light impact when a primary action is triggered.
  public var onPrimaryAction: Bool
  /// Impact intensity used by the built-in generators.
  public var impactStyle: UIImpactFeedbackGenerator.FeedbackStyle

  public init(
    onPressDown: Bool = false,
    onPrimaryAction: Bool = false,
    impactStyle: UIImpactFeedbackGenerator.FeedbackStyle = .light
  ) {
    self.onPressDown = onPressDown
    self.onPrimaryAction = onPrimaryAction
    self.impactStyle = impactStyle
  }
}

