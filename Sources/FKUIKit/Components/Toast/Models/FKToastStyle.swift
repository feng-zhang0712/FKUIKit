import UIKit

/// Visual semantics for Toast/HUD/Snackbar rendering.
public enum FKToastStyle: Sendable, Equatable {
  /// Neutral visual style.
  case normal
  /// Positive completion style.
  case success
  /// Error style.
  case error
  /// Warning style.
  case warning
  /// Informational style.
  case info
  /// Loading style (spinner-friendly).
  case loading

  /// Returns the default symbol name used by UIKit rendering.
  public var defaultSymbolName: String {
    switch self {
    case .normal: return "bell.fill"
    case .success: return "checkmark.circle.fill"
    case .error: return "xmark.octagon.fill"
    case .warning: return "exclamationmark.triangle.fill"
    case .info: return "info.circle.fill"
    case .loading: return "arrow.triangle.2.circlepath"
    }
  }

  /// Returns a dynamic background color adapted to Light/Dark mode.
  public var defaultBackgroundColor: UIColor {
    switch self {
    case .normal:
      return UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.18, alpha: 0.96) : UIColor(white: 0.1, alpha: 0.94) }
    case .success:
      return UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.12, green: 0.42, blue: 0.24, alpha: 0.96) : UIColor(red: 0.16, green: 0.56, blue: 0.29, alpha: 0.96) }
    case .error:
      return UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.50, green: 0.16, blue: 0.16, alpha: 0.96) : UIColor(red: 0.75, green: 0.22, blue: 0.22, alpha: 0.96) }
    case .warning:
      return UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.48, green: 0.35, blue: 0.08, alpha: 0.96) : UIColor(red: 0.72, green: 0.50, blue: 0.10, alpha: 0.96) }
    case .info:
      return UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.16, green: 0.34, blue: 0.54, alpha: 0.96) : UIColor(red: 0.17, green: 0.46, blue: 0.78, alpha: 0.96) }
    case .loading:
      return UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.14, alpha: 0.96) : UIColor(white: 0.16, alpha: 0.94) }
    }
  }
}

/// Presentation category for the unified global presenter.
public enum FKToastKind: Sendable, Equatable {
  /// Lightweight non-blocking hint.
  case toast
  /// Blocking or semi-blocking progress/status overlay.
  case hud
  /// Bottom bar style interactive message.
  case snackbar
}

/// Placement of overlay content in the current scene.
public enum FKToastPosition: Sendable, Equatable {
  /// Top safe-area anchored.
  case top
  /// Centered in the visible scene.
  case center
  /// Bottom safe-area anchored.
  case bottom
}

/// Entrance and exit transition styles.
public enum FKToastAnimationStyle: Sendable, Equatable {
  /// Opacity-only transition.
  case fade
  /// Translation-based transition.
  case slide
  /// Scale + opacity transition.
  case scale
}

/// Priority used by the queue scheduler.
public enum FKToastPriority: Int, Sendable, Comparable {
  /// Lowest queue priority.
  case low = 0
  /// Default queue priority.
  case normal = 1
  /// High queue priority.
  case high = 2
  /// Highest queue priority.
  case critical = 3

  public static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}

/// The reason why an overlay was dismissed.
public enum FKToastDismissReason: Sendable, Equatable {
  /// Timer or timeout reached.
  case timeout
  /// User tapped the content.
  case userTap
  /// User swiped away the content.
  case userSwipe
  /// User triggered an action button.
  case actionTriggered
  /// Replaced by another request.
  case replacedByNewRequest
  /// Interrupted by higher priority request.
  case interruptedByPriority
  /// Closed by explicit API call.
  case manual
  /// Scene lifecycle ended.
  case sceneDestroyed
}

/// Strategy for handling a new request while something is visible.
public enum FKToastArrivalPolicy: Sendable, Equatable {
  /// Keep current one and enqueue new one.
  case queue
  /// Replace currently visible request.
  case replaceCurrent
  /// Ignore new request.
  case dropNew
  /// Deduplicate similar incoming requests.
  case coalesce
  /// Interrupt current and requeue it after new request.
  case interruptAndRequeueCurrent
}

/// Symbol mapping for semantic styles.
public struct FKToastSymbolSet: Sendable, Equatable {
  /// Symbol name used for `.normal`.
  public var normal: String
  /// Symbol name used for `.success`.
  public var success: String
  /// Symbol name used for `.error`.
  public var error: String
  /// Symbol name used for `.warning`.
  public var warning: String
  /// Symbol name used for `.info`.
  public var info: String
  /// Symbol name used for `.loading` when a static icon is required.
  public var loading: String

  /// Creates a symbol set.
  public init(
    normal: String = "bell.fill",
    success: String = "checkmark.circle.fill",
    error: String = "xmark.octagon.fill",
    warning: String = "exclamationmark.triangle.fill",
    info: String = "info.circle.fill",
    loading: String = "arrow.triangle.2.circlepath"
  ) {
    self.normal = normal
    self.success = success
    self.error = error
    self.warning = warning
    self.info = info
    self.loading = loading
  }

  /// Returns the symbol name for the provided semantic style.
  public func symbolName(for style: FKToastStyle) -> String {
    switch style {
    case .normal: return normal
    case .success: return success
    case .error: return error
    case .warning: return warning
    case .info: return info
    case .loading: return loading
    }
  }
}

/// Visual effect strategy for the overlay background.
public enum FKToastBackgroundVisualEffect: Sendable, Equatable {
  /// Use solid background color only.
  case none
  /// Use system material blur with the provided style.
  case blur(style: FKBlurConfiguration.SystemStyle)
  /// Prefer liquid-glass visual style on supported systems and gracefully fallback otherwise.
  case liquidGlassPreferred
}
