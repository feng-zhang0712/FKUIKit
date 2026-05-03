import FKUIKit
import UIKit

final class FKEmptyStatePermissionDeniedExampleViewController: UIViewController {
  private let container = UIView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Permission Denied"
    view.backgroundColor = .systemBackground
    fk_embedFill(container, in: view)
    render()
  }

  deinit {
    fk_clearEmptyStateActionObservers()
  }

  private func render() {
    var model = FKEmptyStateConfiguration.scenario(.noPermission)
    model.image = UIImage(systemName: "lock.shield")
    model.actions = FKEmptyStateActionSet(
      primary: FKEmptyStateAction(id: "request_access", title: "Request access", kind: .primary),
      tertiary: FKEmptyStateAction(id: "contact_admin", title: "Contact admin", kind: .tertiary)
    )
    model.isButtonHidden = false
    container.fk_applyEmptyState(model) { [weak self] action in
      guard let self, action.id == "request_access" else { return }
      self.fk_presentMessageAlert(title: "Access Requested", message: "Your request has been sent to the workspace owner.")
    }
    fk_bindEmptyStateActions(from: container) { [weak self] action in
      guard let self, action.id == "contact_admin" else { return }
      self.fk_presentMessageAlert(title: "Contact Admin", message: "A draft message to admins has been prepared.")
    }
  }
}
