import FKUIKit
import UIKit

final class FKEmptyStateI18nExampleViewController: UIViewController {
  private let container = UIView()
  private let localeSelector = UISegmentedControl(items: ["en", "zh-CN"])
  private let queryField = UITextField()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "i18n"
    view.backgroundColor = .systemBackground
    buildUI()
    render()
  }

  deinit {
    fk_clearEmptyStateActionObservers()
  }

  private func buildUI() {
    localeSelector.selectedSegmentIndex = 0
    localeSelector.addTarget(self, action: #selector(render), for: .valueChanged)
    localeSelector.translatesAutoresizingMaskIntoConstraints = false

    queryField.borderStyle = .roundedRect
    queryField.text = "wallet"
    queryField.placeholder = "query"
    queryField.addTarget(self, action: #selector(render), for: .editingChanged)
    queryField.translatesAutoresizingMaskIntoConstraints = false

    container.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(localeSelector)
    view.addSubview(queryField)
    view.addSubview(container)
    NSLayoutConstraint.activate([
      localeSelector.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
      localeSelector.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      localeSelector.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      queryField.topAnchor.constraint(equalTo: localeSelector.bottomAnchor, constant: 8),
      queryField.leadingAnchor.constraint(equalTo: localeSelector.leadingAnchor),
      queryField.trailingAnchor.constraint(equalTo: localeSelector.trailingAnchor),
      container.topAnchor.constraint(equalTo: queryField.bottomAnchor, constant: 10),
      container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  @objc private func render() {
    let locale: FKEmptyStateLocale = localeSelector.selectedSegmentIndex == 0 ? .en : .zhCN
    let factory = FKEmptyStateFactory(locale: locale)
    let query = queryField.text?.isEmpty == false ? (queryField.text ?? "") : "wallet"
    // Interpolation keeps runtime user input localized in-place (e.g. query text).
    let copy = factory.copy(for: .noResults, variables: ["query": query])

    var model = FKEmptyStateConfiguration(phase: .empty, type: .noResults)
    model.image = UIImage(systemName: "magnifyingglass.circle")
    model.title = copy.title
    model.description = copy.description
    model.actions = FKEmptyStateActionSet(
      secondary: FKEmptyStateAction(
        id: "clear",
        title: factory.actionTitle(FKEmptyStateI18nKey("empty.action.clearFilters")),
        kind: .secondary
      )
    )
    model.isButtonHidden = false
    container.fk_applyEmptyState(model)
    fk_bindEmptyStateActions(from: container) { [weak self] action in
      guard let self, action.id == "clear" else { return }
      self.queryField.text = ""
      self.fk_presentMessageAlert(title: "Updated", message: "The query has been cleared.")
      self.render()
    }
  }
}
