import Foundation

#if os(iOS)
import UIKit

/// Presents a lightweight pre-permission guide dialog before system prompt.
@MainActor
final class FKPermissionPrePromptPresenter {
  /// Presents custom pre-prompt content when provided.
  ///
  /// - Parameter prePrompt: Optional custom alert content.
  /// - Returns: `true` if request flow should continue, `false` if user cancelled.
  func presentIfNeeded(_ prePrompt: FKPermissionPrePrompt?) async -> Bool {
    // Continue silently when no guide text is configured.
    guard let prePrompt else {
      return true
    }

    // Fail open when no active presentation context exists.
    guard let topViewController = Self.findTopViewController() else {
      return true
    }

    return await withCheckedContinuation { continuation in
      let alert = UIAlertController(title: prePrompt.title, message: prePrompt.message, preferredStyle: .alert)
      alert.addAction(
        UIAlertAction(title: prePrompt.cancelTitle, style: .cancel) { _ in
          continuation.resume(returning: false)
        }
      )
      alert.addAction(
        UIAlertAction(title: prePrompt.confirmTitle, style: .default) { _ in
          continuation.resume(returning: true)
        }
      )
      topViewController.present(alert, animated: true)
    }
  }

  /// Finds the top-most view controller in the active foreground window scene.
  private static func findTopViewController() -> UIViewController? {
    let scene = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first(where: { $0.activationState == .foregroundActive })

    let root = scene?.windows.first(where: \.isKeyWindow)?.rootViewController
    return topViewController(from: root)
  }

  /// Walks common container hierarchies to retrieve the visible controller.
  private static func topViewController(from root: UIViewController?) -> UIViewController? {
    if let navigation = root as? UINavigationController {
      return topViewController(from: navigation.visibleViewController)
    }
    if let tab = root as? UITabBarController {
      return topViewController(from: tab.selectedViewController)
    }
    if let presented = root?.presentedViewController {
      return topViewController(from: presented)
    }
    return root
  }
}

#endif
