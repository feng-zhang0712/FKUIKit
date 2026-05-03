#if canImport(UIKit)
import QuartzCore
import UIKit

public extension UINavigationController {
  /// Pops to the root view controller and invokes `completion` when the transition finishes (when `animated` is `true`, subject to `CATransaction` semantics).
  func fk_popToRootViewController(animated: Bool, completion: (() -> Void)?) {
    guard let completion else {
      popToRootViewController(animated: animated)
      return
    }
    CATransaction.begin()
    CATransaction.setCompletionBlock(completion)
    popToRootViewController(animated: animated)
    CATransaction.commit()
  }

  /// Pushes a controller and invokes `completion` when the transition finishes.
  func fk_pushViewController(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
    guard let completion else {
      pushViewController(viewController, animated: animated)
      return
    }
    CATransaction.begin()
    CATransaction.setCompletionBlock(completion)
    pushViewController(viewController, animated: animated)
    CATransaction.commit()
  }
}

#endif
