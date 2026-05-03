import Foundation
import UIKit

/// Default implementation of ``FKBusinessAlertManaging`` with de-duplication.
public final class FKBusinessAlertManager: FKBusinessAlertManaging, @unchecked Sendable {
  /// Lock protecting de-duplication state when ``presentOnce`` schedules UI work.
  private let lock = NSLock()
  /// IDs of alerts currently being presented.
  private var presentingIDs: Set<String> = []

  /// Creates alert manager.
  public init() {}

  /// Presents a single alert instance for a given identifier.
  ///
  /// - Parameters:
  ///   - id: Stable identifier for duplicate suppression.
  ///   - title: Alert title.
  ///   - message: Alert message.
  ///   - actions: Action descriptors. Empty array falls back to a single "OK" action.
  ///   - presenter: Optional presenter view controller.
  public func presentOnce(
    id: String,
    title: String?,
    message: String?,
    actions: [FKAlertAction],
    presenter: UIViewController?
  ) {
    guard !id.isEmpty else { return }

    lock.lock()
    if presentingIDs.contains(id) {
      lock.unlock()
      return
    }
    presentingIDs.insert(id)
    lock.unlock()

    Task { @MainActor [weak self] in
      self?.presentAlertOnMain(id: id, title: title, message: message, actions: actions, presenter: presenter)
    }
  }

  @MainActor
  private func presentAlertOnMain(
    id: String,
    title: String?,
    message: String?,
    actions: [FKAlertAction],
    presenter: UIViewController?
  ) {
    let vc = presenter ?? FKTopViewControllerResolver.topMostViewController()
    guard let vc else {
      finish(id: id)
      return
    }

    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let resolvedActions = actions.isEmpty ? [FKAlertAction(title: "OK", style: .default, handler: nil)] : actions
    for action in resolvedActions {
      alert.addAction(UIAlertAction(title: action.title, style: Self.mapStyle(action.style)) { _ in
        action.handler?()
        self.finish(id: id)
      })
    }

    vc.present(alert, animated: true)
  }

  /// Marks alert identifier as finished so it can be presented again.
  ///
  /// - Parameter id: Alert identifier.
  private func finish(id: String) {
    lock.lock()
    presentingIDs.remove(id)
    lock.unlock()
  }

  /// Converts toolkit alert style to `UIAlertAction.Style`.
  ///
  /// - Parameter style: Toolkit alert style.
  /// - Returns: UIKit alert style.
  private static func mapStyle(_ style: FKAlertAction.Style) -> UIAlertAction.Style {
    switch style {
    case .default: return .default
    case .cancel: return .cancel
    case .destructive: return .destructive
    }
  }
}
