import UIKit

@MainActor
protocol FKPresentationHost: AnyObject {
  /// Indicates whether this host currently owns a visible presentation.
  var isPresented: Bool { get }
  /// Presents content from the supplied presenter using host-specific mechanics.
  func present(from presentingViewController: UIViewController, animated: Bool, completion: (() -> Void)?)
  /// Dismisses content managed by this host.
  func dismiss(animated: Bool, completion: (() -> Void)?)
  /// Re-applies layout when external geometry changes.
  func updateLayout()
}

