import UIKit

/// Visual level of a toast/snackbar message.
public enum FKToastStyle: Sendable, Equatable {
  /// Neutral informational message.
  case normal
  /// Positive feedback.
  case success
  /// Error feedback.
  case error
  /// Warning feedback.
  case warning
  /// Secondary informational hint.
  case info

  /// Default SF Symbol icon for this style.
  ///
  /// - Note: Returned symbols are SF Symbols names. You may override the actual image per message
  ///   via `FKToast.show(_:icon:configuration:actionHandler:)`.
  public var defaultSymbolName: String {
    switch self {
    case .normal: return "bell.fill"
    case .success: return "checkmark.circle.fill"
    case .error: return "xmark.octagon.fill"
    case .warning: return "exclamationmark.triangle.fill"
    case .info: return "info.circle.fill"
    }
  }

  /// Default background color for this style.
  ///
  /// - Note: The returned color is dynamic and adapts to light/dark appearances.
  public var defaultBackgroundColor: UIColor {
    switch self {
    case .normal:
      return UIColor { trait in
        trait.userInterfaceStyle == .dark
          ? UIColor(white: 0.18, alpha: 0.96)
          : UIColor(white: 0.1, alpha: 0.94)
      }
    case .success:
      return UIColor { trait in
        trait.userInterfaceStyle == .dark
          ? UIColor(red: 0.12, green: 0.42, blue: 0.24, alpha: 0.96)
          : UIColor(red: 0.16, green: 0.56, blue: 0.29, alpha: 0.96)
      }
    case .error:
      return UIColor { trait in
        trait.userInterfaceStyle == .dark
          ? UIColor(red: 0.50, green: 0.16, blue: 0.16, alpha: 0.96)
          : UIColor(red: 0.75, green: 0.22, blue: 0.22, alpha: 0.96)
      }
    case .warning:
      return UIColor { trait in
        trait.userInterfaceStyle == .dark
          ? UIColor(red: 0.48, green: 0.35, blue: 0.08, alpha: 0.96)
          : UIColor(red: 0.72, green: 0.50, blue: 0.10, alpha: 0.96)
      }
    case .info:
      return UIColor { trait in
        trait.userInterfaceStyle == .dark
          ? UIColor(red: 0.16, green: 0.34, blue: 0.54, alpha: 0.96)
          : UIColor(red: 0.17, green: 0.46, blue: 0.78, alpha: 0.96)
      }
    }
  }
}

/// Presentation form for global hints.
public enum FKToastKind: Sendable, Equatable {
  /// Floating toast card, typically concise and non-actionable.
  case toast
  /// Snackbar card, usually anchored to bottom/top with optional action.
  case snackbar
}

/// Placement of toast/snackbar in the target window.
public enum FKToastPosition: Sendable, Equatable {
  /// Safe-area top.
  case top
  /// Screen center.
  case center
  /// Safe-area bottom.
  case bottom
}

/// Built-in transition style.
public enum FKToastAnimationStyle: Sendable, Equatable {
  /// Alpha transition only.
  case fade
  /// Alpha + directional translation.
  case slide
}
