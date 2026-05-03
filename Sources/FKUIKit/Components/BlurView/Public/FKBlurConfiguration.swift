import UIKit

/// Type-safe configuration for `FKBlurView` and `UIImage` blur utilities.
public struct FKBlurConfiguration: Sendable, Equatable {
  /// Rendering mode.
  public enum Mode: Sendable, Equatable {
    /// Blur is produced once and then reused. Best for static backgrounds.
    case `static`
    /// Blur is refreshed when the background changes. Best for scroll/animations.
    case dynamic
  }

  /// Blur backend.
  public enum Backend: Sendable, Equatable {
    /// Uses system hardware-accelerated materials via `UIVisualEffectView`.
    case system(style: SystemStyle)
    /// Uses Core Image with fully custom parameters (radius/saturation/brightness/tint).
    case custom(parameters: CustomParameters)
  }

  /// System blur styles supported by `UIBlurEffect`.
  public enum SystemStyle: Int, Sendable, Equatable, CaseIterable {
    /// Matches `UIBlurEffect.Style.extraLight`.
    case extraLight
    /// Matches `UIBlurEffect.Style.light`.
    case light
    /// Matches `UIBlurEffect.Style.dark`.
    case dark
    /// Matches `UIBlurEffect.Style.regular`.
    case regular
    /// Matches `UIBlurEffect.Style.prominent`.
    case prominent

    /// Matches `UIBlurEffect.Style.systemUltraThinMaterial`.
    case systemUltraThinMaterial
    /// Matches `UIBlurEffect.Style.systemThinMaterial`.
    case systemThinMaterial
    /// Matches `UIBlurEffect.Style.systemMaterial`.
    case systemMaterial
    /// Matches `UIBlurEffect.Style.systemThickMaterial`.
    case systemThickMaterial
    /// Matches `UIBlurEffect.Style.systemChromeMaterial`.
    case systemChromeMaterial

    /// Matches `UIBlurEffect.Style.systemUltraThinMaterialLight`.
    case systemUltraThinMaterialLight
    /// Matches `UIBlurEffect.Style.systemThinMaterialLight`.
    case systemThinMaterialLight
    /// Matches `UIBlurEffect.Style.systemMaterialLight`.
    case systemMaterialLight
    /// Matches `UIBlurEffect.Style.systemThickMaterialLight`.
    case systemThickMaterialLight
    /// Matches `UIBlurEffect.Style.systemChromeMaterialLight`.
    case systemChromeMaterialLight

    /// Matches `UIBlurEffect.Style.systemUltraThinMaterialDark`.
    case systemUltraThinMaterialDark
    /// Matches `UIBlurEffect.Style.systemThinMaterialDark`.
    case systemThinMaterialDark
    /// Matches `UIBlurEffect.Style.systemMaterialDark`.
    case systemMaterialDark
    /// Matches `UIBlurEffect.Style.systemThickMaterialDark`.
    case systemThickMaterialDark
    /// Matches `UIBlurEffect.Style.systemChromeMaterialDark`.
    case systemChromeMaterialDark

    /// Converts to `UIBlurEffect.Style` (iOS 13+).
    public var uiBlurEffectStyle: UIBlurEffect.Style {
      switch self {
      case .extraLight: return .extraLight
      case .light: return .light
      case .dark: return .dark
      case .regular: return .regular
      case .prominent: return .prominent
      case .systemUltraThinMaterial: return .systemUltraThinMaterial
      case .systemThinMaterial: return .systemThinMaterial
      case .systemMaterial: return .systemMaterial
      case .systemThickMaterial: return .systemThickMaterial
      case .systemChromeMaterial: return .systemChromeMaterial
      case .systemUltraThinMaterialLight: return .systemUltraThinMaterialLight
      case .systemThinMaterialLight: return .systemThinMaterialLight
      case .systemMaterialLight: return .systemMaterialLight
      case .systemThickMaterialLight: return .systemThickMaterialLight
      case .systemChromeMaterialLight: return .systemChromeMaterialLight
      case .systemUltraThinMaterialDark: return .systemUltraThinMaterialDark
      case .systemThinMaterialDark: return .systemThinMaterialDark
      case .systemMaterialDark: return .systemMaterialDark
      case .systemThickMaterialDark: return .systemThickMaterialDark
      case .systemChromeMaterialDark: return .systemChromeMaterialDark
      }
    }
  }

  /// Custom blur parameters used by the Core Image backend.
  public struct CustomParameters: Sendable, Equatable {
    /// Gaussian blur radius in points.
    public var blurRadius: CGFloat
    /// Saturation multiplier (1.0 means unchanged).
    public var saturation: CGFloat
    /// Brightness adjustment (-1...1 is typical; 0 means unchanged).
    public var brightness: CGFloat
    /// Optional tint color overlay applied on top of the blurred result.
    public var tintColor: UIColor?
    /// Tint opacity (0...1). Only used when `tintColor` is non-nil.
    public var tintOpacity: CGFloat

    /// Creates custom blur parameters.
    public init(
      blurRadius: CGFloat = 20,
      saturation: CGFloat = 1.0,
      brightness: CGFloat = 0.0,
      tintColor: UIColor? = nil,
      tintOpacity: CGFloat = 0.0
    ) {
      self.blurRadius = blurRadius
      self.saturation = saturation
      self.brightness = brightness
      self.tintColor = tintColor
      self.tintOpacity = tintOpacity
    }
  }

  /// Rendering mode.
  public var mode: Mode
  /// Selected backend.
  public var backend: Backend
  /// Overall opacity for the blur result (0...1).
  public var opacity: CGFloat

  /// Downsample factor for the Core Image pipeline (1 = full resolution, 2/4/8 = faster).
  ///
  /// - Note: This affects only `.custom` backend.
  public var downsampleFactor: CGFloat

  /// Preferred refresh rate for dynamic Core Image blur (frames per second).
  ///
  /// - Important: System backend ignores this because it is already hardware-accelerated.
  public var preferredFramesPerSecond: Int

  /// Opaque fill for the **`.custom`** backend when the user enables *Reduce Transparency*
  /// (Settings → Accessibility → Display & Text Size).
  ///
  /// `nil` means `UIColor.secondarySystemBackground` (resolved with the host view’s `traitCollection`).
  /// Set a brand or surface color when the default system gray does not match your chrome.
  ///
  /// - Note: Ignored for `.system` backend; `UIVisualEffectView` is handled by the system.
  public var reduceTransparencyFallbackColor: UIColor?

  /// Creates a blur configuration.
  public init(
    mode: Mode = .dynamic,
    backend: Backend = .system(style: .systemMaterial),
    opacity: CGFloat = 1.0,
    downsampleFactor: CGFloat = 4,
    preferredFramesPerSecond: Int = 60,
    reduceTransparencyFallbackColor: UIColor? = nil
  ) {
    self.mode = mode
    self.backend = backend
    self.opacity = opacity
    self.downsampleFactor = downsampleFactor
    self.preferredFramesPerSecond = preferredFramesPerSecond
    self.reduceTransparencyFallbackColor = reduceTransparencyFallbackColor
  }

  /// A sensible default matching iOS materials.
  public static let `default` = FKBlurConfiguration()
}

/// Namespace for blur-wide defaults (parallel to `FKBadge` using static configuration entry points).
///
/// Mutate `defaultConfiguration` once at launch to unify appearance; set `FKBlurView.configuration` per instance to override.
///
/// - Important: Mutate only on the main thread (UIKit). Existing `FKBlurView` instances do not observe changes automatically—reassign `FKBlurView.configuration` when needed.
public enum FKBlur {
  /// Baseline configuration used by new `FKBlurView` instances and by `FKSwiftUIBlurView` when no value is passed.
  public nonisolated(unsafe) static var defaultConfiguration: FKBlurConfiguration = .default
}

