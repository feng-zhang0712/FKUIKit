import UIKit

public extension FKAnchoredDropdownController {
  /// Adds this controller as a child of `parent` and pins ``view`` to the edges of `container`.
  ///
  /// Call from the parent’s `viewDidLoad` (or later) after `parent.view` exists. Defaults to pinning to `parent.view`.
  func embed(in parent: UIViewController, pinTo container: UIView? = nil) {
    guard let host = container ?? parent.view else {
      assertionFailure("FKAnchoredDropdownController.embed requires parent.view; call after the parent view loads.")
      return
    }
    parent.addChild(self)
    view.translatesAutoresizingMaskIntoConstraints = false
    host.addSubview(view)
    NSLayoutConstraint.activate([
      view.topAnchor.constraint(equalTo: host.topAnchor),
      view.leadingAnchor.constraint(equalTo: host.leadingAnchor),
      view.trailingAnchor.constraint(equalTo: host.trailingAnchor),
      view.bottomAnchor.constraint(equalTo: host.bottomAnchor),
    ])
    didMove(toParent: parent)
  }
}
