//
//  FKButton+GlobalStyle.swift
//
//  Factory-wide defaults applied when each `FKButton` is created. Intended for AppDelegate / early setup.
//

import UIKit

public extension FKButton {
  /// Default values copied into new buttons in `commonInit` (per-instance copies thereafter).
  ///
  /// Stored properties are `nonisolated(unsafe)` so they remain mutable under Swift 6 strict concurrency;
  /// configure from the main thread only (typical for UIKit).
  enum GlobalStyle {
    /// Minimum time between accepted `touchUpInside` / `primaryActionTriggered` deliveries (seconds). `0` disables.
    public nonisolated(unsafe) static var minimumTapInterval: TimeInterval = 1.0

    /// Passed to `UILongPressGestureRecognizer.minimumPressDuration`.
    public nonisolated(unsafe) static var longPressMinimumDuration: TimeInterval = 0.5

    /// Interval between `onLongPressRepeatTick` callbacks after recognition begins. `0` disables repeat ticks.
    public nonisolated(unsafe) static var longPressRepeatTickInterval: TimeInterval = 0.1

    /// When `true`, multiplies alpha while `isEnabled == false` (skipped while `isLoading`).
    public nonisolated(unsafe) static var automaticallyDimsWhenDisabled: Bool = true

    /// Alpha multiplier on top of resolved appearance when disabled dimming is active.
    public nonisolated(unsafe) static var disabledDimmingAlpha: CGFloat = 0.55

    /// When set, `setAppearances(_:)` runs at the end of `commonInit` for every new instance.
    public nonisolated(unsafe) static var defaultAppearances: StateAppearances?

    /// Optional one-off customization after internal wiring (fonts, hit targets, etc.).
    public nonisolated(unsafe) static var applyPerNewButton: ((FKButton) -> Void)?
  }
}
