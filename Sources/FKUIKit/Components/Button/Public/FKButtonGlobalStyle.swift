import UIKit

/// Factory-wide defaults copied into each new `FKButton`.
public enum FKButtonGlobalStyle {
  /// Minimum accepted interval between primary actions.
  /// Default is `0` (no throttling) to avoid surprising behavior in global integrations.
  public nonisolated(unsafe) static var minimumTapInterval: TimeInterval = 0
  /// Passed to the long press recognizer.
  public nonisolated(unsafe) static var longPressMinimumDuration: TimeInterval = 0.5
  /// Long-press repeat callback interval.
  public nonisolated(unsafe) static var longPressRepeatTickInterval: TimeInterval = 0.1
  /// Whether disabled state applies dimming.
  public nonisolated(unsafe) static var automaticallyDimsWhenDisabled: Bool = true
  /// Dimming alpha multiplier while disabled.
  public nonisolated(unsafe) static var disabledDimmingAlpha: CGFloat = 0.55
  /// Default state appearances for newly created buttons.
  public nonisolated(unsafe) static var defaultAppearances: FKButtonStateAppearances?
  /// Per-instance hook called after `FKButton` setup.
  public nonisolated(unsafe) static var applyPerNewButton: ((FKButton) -> Void)?
}
