import UIKit

/// Appearance, motion, accessibility hints, and optional label behavior for ``FKProgressBar``.
///
/// Configuration is grouped into ``layout``, ``appearance``, ``motion``, ``label``, ``accessibility``, and ``interaction`` for easier navigation and reuse.
///
/// - Note: Marked `@unchecked Sendable` because nested types may carry `UIColor`, `UIFont`, or `NumberFormatter`.
public struct FKProgressBarConfiguration: @unchecked Sendable {
  public var layout: FKProgressBarLayoutConfiguration
  public var appearance: FKProgressBarAppearanceConfiguration
  public var motion: FKProgressBarMotionConfiguration
  public var label: FKProgressBarLabelConfiguration
  public var accessibility: FKProgressBarAccessibilityConfiguration
  public var interaction: FKProgressBarInteractionConfiguration

  public init(
    layout: FKProgressBarLayoutConfiguration = .init(),
    appearance: FKProgressBarAppearanceConfiguration = .init(),
    motion: FKProgressBarMotionConfiguration = .init(),
    label: FKProgressBarLabelConfiguration = .init(),
    accessibility: FKProgressBarAccessibilityConfiguration = .init(),
    interaction: FKProgressBarInteractionConfiguration = .init()
  ) {
    self.layout = layout
    self.appearance = appearance
    self.motion = motion
    self.label = label
    self.accessibility = accessibility
    self.interaction = interaction
  }
}

// MARK: - Global defaults

/// Namespace for shared defaults applied to new ``FKProgressBar`` instances.
@MainActor
public enum FKProgressBarDefaults {
  /// Baseline copied at initialization until the host replaces ``FKProgressBar/configuration``.
  public static var configuration = FKProgressBarConfiguration()
}
