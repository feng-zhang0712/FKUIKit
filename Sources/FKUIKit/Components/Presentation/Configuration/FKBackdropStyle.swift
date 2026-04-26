import UIKit

/// Backdrop style behind the presented container.
public enum FKBackdropStyle: Equatable {
  /// No backdrop.
  case none
  /// A dim overlay using dynamic system colors.
  case dim(color: UIColor = UIColor.black, alpha: CGFloat = 0.35)
  /// A blur effect. Optionally adds vibrancy.
  case blur(effect: UIBlurEffect.Style = .systemMaterial, alpha: CGFloat = 1, vibrancy: UIVibrancyEffectStyle? = nil)
  /// Best-effort liquid glass appearance.
  ///
  /// - Important: On systems where a true liquid glass style is unavailable, this will downgrade to blur + highlights.
  case liquidGlass(configuration: FKLiquidGlassConfiguration = .init())
}

/// Configuration for liquid-glass-like backdrop rendering with downgrade controls.
public struct FKLiquidGlassConfiguration: Equatable {
  /// Overall intensity (0...1).
  public var intensity: CGFloat
  /// Whether a subtle noise layer is rendered.
  public var showsNoise: Bool
  /// Whether highlight gradient is rendered.
  public var showsHighlight: Bool
  /// Downgrade to blur only when Reduce Transparency is enabled.
  public var downgradeWhenReduceTransparencyEnabled: Bool
  /// Disables extra layers on Low Power Mode.
  public var simplifyInLowPowerMode: Bool

  public init(
    intensity: CGFloat = 1,
    showsNoise: Bool = true,
    showsHighlight: Bool = true,
    downgradeWhenReduceTransparencyEnabled: Bool = true,
    simplifyInLowPowerMode: Bool = true
  ) {
    self.intensity = min(max(intensity, 0), 1)
    self.showsNoise = showsNoise
    self.showsHighlight = showsHighlight
    self.downgradeWhenReduceTransparencyEnabled = downgradeWhenReduceTransparencyEnabled
    self.simplifyInLowPowerMode = simplifyInLowPowerMode
  }
}

