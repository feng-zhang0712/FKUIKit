import FKUIKit
import UIKit

final class FKEmptyStateErrorRetryExampleViewController: UIViewController {
  private let container = UIView()
  private var isRetrying = false

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Error + Retry"
    view.backgroundColor = .systemBackground
    fk_embedFill(container, in: view)
    showError()
  }

  private func showError() {
    var model = FKEmptyStateExampleFactory.makeLoadFailedModel()
    model.description = "The request timed out. Retry uses action loading state."
    model.actions = FKEmptyStateActionSet(
      primary: FKEmptyStateAction(id: "retry", title: "Retry", kind: .primary, isLoading: isRetrying)
    )
    container.fk_applyEmptyState(model) { [weak self] _ in
      self?.startRetryFlow()
    }
  }

  private func startRetryFlow() {
    guard !isRetrying else { return }
    isRetrying = true
    showError()
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
      guard let self else { return }
      self.isRetrying = false
      var model = FKEmptyStateExampleFactory.makeBasicModel()
      model.title = "No items after retry"
      model.description = "Retry succeeded, but there is still no content to show."
      self.container.fk_applyEmptyState(model)
    }
  }
}
