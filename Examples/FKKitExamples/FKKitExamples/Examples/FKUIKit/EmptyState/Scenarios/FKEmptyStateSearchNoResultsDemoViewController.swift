import FKUIKit
import UIKit

final class FKEmptyStateSearchNoResultsDemoViewController: UIViewController {
  private let container = UIView()
  private let queryField = UITextField()
  private let filtersLabel = UILabel()
  private var activeFilters = 3

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "No Results"
    view.backgroundColor = .systemBackground
    buildUI()
    render()
  }

  deinit {
    fk_clearEmptyStateActionObservers()
  }

  private func buildUI() {
    queryField.borderStyle = .roundedRect
    queryField.placeholder = "Search query"
    queryField.text = "wireless earbuds pro max"
    queryField.addTarget(self, action: #selector(queryChanged), for: .editingChanged)

    filtersLabel.font = .systemFont(ofSize: 13, weight: .medium)
    filtersLabel.textColor = .secondaryLabel

    container.translatesAutoresizingMaskIntoConstraints = false
    queryField.translatesAutoresizingMaskIntoConstraints = false
    filtersLabel.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(queryField)
    view.addSubview(filtersLabel)
    view.addSubview(container)
    NSLayoutConstraint.activate([
      queryField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
      queryField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      queryField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      filtersLabel.topAnchor.constraint(equalTo: queryField.bottomAnchor, constant: 8),
      filtersLabel.leadingAnchor.constraint(equalTo: queryField.leadingAnchor),
      container.topAnchor.constraint(equalTo: filtersLabel.bottomAnchor, constant: 10),
      container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  @objc private func queryChanged() {
    render()
  }

  private func render() {
    let query = queryField.text?.isEmpty == false ? (queryField.text ?? "") : "camera"
    filtersLabel.text = "Active filters: \(activeFilters)"

    var model = FKEmptyStateModel.scenario(.noSearchResult)
    model.image = UIImage(systemName: "magnifyingglass")
    model.title = "No results for \"\(query)\""
    model.description = "Try broader keywords, or clear filters to widen your results."
    model.actions = FKEmptyStateActionSet(
      secondary: FKEmptyStateAction(id: "clear_filters", title: "Clear filters", kind: .secondary)
    )
    model.isButtonHidden = false
    container.fk_applyEmptyState(model)
    fk_bindEmptyStateActions(from: container) { [weak self] action in
      guard let self, action.id == "clear_filters" else { return }
      self.activeFilters = 0
      self.filtersLabel.text = "Active filters: 0"
      self.fk_presentMessageAlert(title: "Filters Cleared", message: "Search is now running without filters.")
    }
  }
}
