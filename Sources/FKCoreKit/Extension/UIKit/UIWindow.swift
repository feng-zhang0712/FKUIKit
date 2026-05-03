#if canImport(UIKit)
import UIKit

public extension UIWindow {
  /// Recursively finds the top-most visible view controller hosted in the window.
  var fk_topViewController: UIViewController? {
    guard let root = rootViewController else { return nil }
    return fk_topViewController(from: root)
  }

  private func fk_topViewController(from base: UIViewController) -> UIViewController {
    if let nav = base as? UINavigationController, let visible = nav.visibleViewController {
      return fk_topViewController(from: visible)
    }
    if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
      return fk_topViewController(from: selected)
    }
    if let presented = base.presentedViewController {
      return fk_topViewController(from: presented)
    }
    return base
  }
}

#endif
