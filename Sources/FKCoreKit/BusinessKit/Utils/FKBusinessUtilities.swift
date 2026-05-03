import Foundation
import UIKit

/// Default implementation of ``FKBusinessUtilitiesProviding``.
public final class FKBusinessUtilities: FKBusinessUtilitiesProviding, @unchecked Sendable {
  /// Time formatting helper group.
  public let time: FKBusinessTimeFormatting
  /// Number formatting helper group.
  public let number: FKBusinessNumberFormatting
  /// Sensitive data masking helper group.
  public let mask: FKBusinessMasking
  /// Alert presentation and de-duplication helper group.
  public let alerts: FKBusinessAlertManaging
  /// Startup task orchestration helper group.
  public let startup: FKBusinessStartupTaskManaging

  /// Creates utilities facade with default helper implementations.
  ///
  /// - Parameters:
  ///   - i18n: Localization manager used by locale-aware formatters.
  ///   - infoProvider: App/device info provider reserved for future utility expansion.
  public init(i18n: FKBusinessLocalizing, infoProvider: FKBusinessInfoProviding) {
    // This closure is intentionally not marked `@Sendable` because `FKBusinessLocalizing`
    // is a reference-type protocol. The underlying implementation is internally synchronized.
    let languageProvider: () -> String = { i18n.currentLanguageCode }
    time = FKBusinessTimeFormatter(languageCodeProvider: languageProvider)
    number = FKBusinessNumberFormatter(languageCodeProvider: languageProvider)
    mask = FKBusinessMasker()
    alerts = FKBusinessAlertManager()
    startup = FKBusinessStartupTaskManager()
  }
}

// MARK: - Top view controller

@MainActor
enum FKTopViewControllerResolver {
  /// Resolves current top-most view controller in active foreground scene.
  ///
  /// - Returns: Top-most view controller if available.
  static func topMostViewController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes
    let windowScene = scenes.compactMap { $0 as? UIWindowScene }.first { $0.activationState == .foregroundActive }
    let window = windowScene?.windows.first { $0.isKeyWindow } ?? windowScene?.windows.first
    let root = window?.rootViewController
    return top(from: root)
  }

  /// Traverses common container stacks (`UINavigationController`, `UITabBarController`, presented chain).
  ///
  /// - Parameter base: Starting view controller.
  /// - Returns: Top-most reachable view controller.
  private static func top(from base: UIViewController?) -> UIViewController? {
    if let nav = base as? UINavigationController {
      return top(from: nav.visibleViewController)
    }
    if let tab = base as? UITabBarController {
      return top(from: tab.selectedViewController)
    }
    if let presented = base?.presentedViewController {
      return top(from: presented)
    }
    return base
  }
}

