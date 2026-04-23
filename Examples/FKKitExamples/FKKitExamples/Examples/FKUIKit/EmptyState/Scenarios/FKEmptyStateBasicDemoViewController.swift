import FKUIKit
import UIKit

final class FKEmptyStateBasicDemoViewController: UIViewController {
  private let container = UIView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Basic"
    view.backgroundColor = .systemBackground

    container.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(container)
    NSLayoutConstraint.activate([
      container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    let model = FKEmptyStateDemoFactory.makeBasicModel()
    container.fk_applyEmptyState(model) { [weak self] _ in
      self?.fk_presentMessageAlert(title: "Action", message: "Create item tapped.")
    }
  }
}
