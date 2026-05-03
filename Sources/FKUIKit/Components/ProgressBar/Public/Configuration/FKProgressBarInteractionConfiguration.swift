import UIKit

/// Indicator vs button, hit target, touch haptics, and dimming while disabled or highlighted.
public struct FKProgressBarInteractionConfiguration: Sendable {
  /// ``FKProgressBarInteractionMode/button`` enables ``UIControl`` target/action semantics.
  public var interactionMode: FKProgressBarInteractionMode
  /// Multiplier on track and fill opacity while highlighted in button mode (typically `0.88…1`).
  public var highlightedAlphaMultiplier: CGFloat
  /// Opacity for the drawing when ``UIControl/isEnabled`` is `false` in button mode.
  public var disabledAlpha: CGFloat
  /// In button mode, expands the hit test to at least this size (centered), per HIG touch targets.
  public var minimumTouchTargetSize: CGSize?
  public var touchHaptic: FKProgressBarTouchHaptic

  public init(
    interactionMode: FKProgressBarInteractionMode = .indicator,
    highlightedAlphaMultiplier: CGFloat = 0.9,
    disabledAlpha: CGFloat = 0.48,
    minimumTouchTargetSize: CGSize? = nil,
    touchHaptic: FKProgressBarTouchHaptic = .none
  ) {
    self.interactionMode = interactionMode
    self.highlightedAlphaMultiplier = min(max(0.2, highlightedAlphaMultiplier), 1)
    self.disabledAlpha = min(max(0.1, disabledAlpha), 1)
    self.minimumTouchTargetSize = minimumTouchTargetSize
    self.touchHaptic = touchHaptic
  }
}
