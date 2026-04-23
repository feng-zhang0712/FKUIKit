import FKUIKit
import UIKit

final class FKEmptyStateOfflineDemoViewController: UIViewController {
  private let container = UIView()

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Offline"
    view.backgroundColor = .systemBackground
    fk_embedFill(container, in: view)
    render()
  }

  private func render() {
    var model = FKEmptyStateDemoFactory.makeNoNetworkModel()
    model.description = "You are offline. Open docs for troubleshooting or check network settings."
    model.actions = FKEmptyStateActionSet(
      primary: FKEmptyStateAction(id: "check_network", title: "Check network", kind: .primary),
      secondary: FKEmptyStateAction(id: "open_docs", title: "Open docs", kind: .secondary)
    )
    container.fk_applyEmptyState(model) { [weak self] action in
      guard let _ = self, action.id == "check_network" else { return }
      if let url = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(url)
      }
    }
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleActionNotification(_:)),
      name: .fkEmptyStateActionInvoked,
      object: container.fk_emptyStateView
    )
  }

  @objc private func handleActionNotification(_ notification: Notification) {
    guard let id = notification.userInfo?[FKEmptyStateNotificationKeys.id] as? String, id == "open_docs" else { return }
    if let url = URL(string: "https://developer.apple.com/documentation/network") {
      UIApplication.shared.open(url)
    }
  }
}
