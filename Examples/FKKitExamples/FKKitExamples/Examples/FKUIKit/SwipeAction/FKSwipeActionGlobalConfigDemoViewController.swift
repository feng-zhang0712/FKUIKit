import UIKit
import FKUIKit

/// Global defaults demo: shows how to apply/reset `FKSwipeActionManager.globalDefaultConfiguration`.
final class FKSwipeActionGlobalConfigDemoViewController: UITableViewController {
  private var items: [String] = (0..<20).map { "Global config demo row \($0)" }
  private var didApplyGlobal = false
  private let headerContainer = UIView()
  private let headerLabel = UILabel()
  private var lastHeaderWidth: CGFloat = 0

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Global Configuration"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.rowHeight = 56
    tableView.cellLayoutMarginsFollowReadableWidth = true

    // Header note: copy-ready guidance.
    headerLabel.numberOfLines = 0
    headerLabel.font = .preferredFont(forTextStyle: .footnote)
    headerLabel.textColor = .secondaryLabel
    headerLabel.text =
      "Demo: update FKSwipeAction global defaults.\n" +
      "Action: tap “Apply/Reset” to observe style differences.\n" +
      "Note: global defaults affect managers created afterwards; passing a per-list configuration overrides them."
    configureHeaderIfNeeded()
    updateHeaderLayoutIfNeeded(force: true)

    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Apply",
      style: .plain,
      target: self,
      action: #selector(toggleGlobal)
    )

    // Key line: enable without passing `configuration` so it starts from the current global defaults.
    tableView.fk_enableSwipeActions { _ in
      FKSwipeActionConfiguration(
        rightActions: [
          FKSwipeActionButton(id: "delete", title: "Delete", background: .color(.systemRed), width: 84) {},
          FKSwipeActionButton(id: "pin", title: "Pin", background: .color(.systemOrange), width: 84) {},
        ]
      )
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    updateHeaderLayoutIfNeeded(force: false)
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    var config = cell.defaultContentConfiguration()
    config.text = items[indexPath.row]
    config.secondaryText = "Swipe action appearance changes with global defaults."
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    cell.selectionStyle = .none
    return cell
  }

  // MARK: - Global toggle

  @objc private func toggleGlobal() {
    didApplyGlobal.toggle()
    navigationItem.rightBarButtonItem?.title = didApplyGlobal ? "Reset" : "Apply"

    if didApplyGlobal {
      // Key line: set global defaults (typically at app launch).
      FKSwipeActionManager.globalDefaultConfiguration = FKSwipeActionConfiguration(
        openThreshold: 56,
        allowsOnlyOneOpen: true,
        tapToClose: true,
        autoCloseAfterAction: true,
        usesRubberBand: true,
        animationDuration: 0.26
      )
    } else {
      // Reset to the default initializer values.
      FKSwipeActionManager.globalDefaultConfiguration = FKSwipeActionConfiguration()
    }

    // To make this screen reflect changes immediately, re-enable once.
    // In a real app, you typically set global defaults before creating lists.
    tableView.fk_enableSwipeActions { [self] _ in
      FKSwipeActionConfiguration(
        rightActions: [
          FKSwipeActionButton(
            id: "delete",
            title: "Delete",
            icon: UIImage(systemName: "trash.fill"),
            background: .color(.systemRed),
            layout: .iconLeading,
            width: 108,
            cornerRadius: self.didApplyGlobal ? 16 : 0
          ) {},
          FKSwipeActionButton(
            id: "pin",
            title: "Pin",
            icon: UIImage(systemName: "pin.fill"),
            background: .horizontalGradient(leading: .systemOrange, trailing: .systemYellow),
            layout: .iconTop,
            width: 92,
            cornerRadius: self.didApplyGlobal ? 16 : 0
          ) {},
        ]
      )
    }
  }

  // MARK: - Header helper

  private func configureHeaderIfNeeded() {
    guard tableView.tableHeaderView == nil else { return }
    headerContainer.backgroundColor = .clear
    headerLabel.translatesAutoresizingMaskIntoConstraints = false
    headerContainer.addSubview(headerLabel)
    NSLayoutConstraint.activate([
      headerLabel.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: 12),
      headerLabel.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 16),
      headerLabel.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -16),
      headerLabel.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: -12),
    ])
    tableView.tableHeaderView = headerContainer
  }

  private func updateHeaderLayoutIfNeeded(force: Bool) {
    let width = view.bounds.width
    if !force, abs(width - lastHeaderWidth) < 0.5 { return }
    lastHeaderWidth = width
    let size = headerContainer.systemLayoutSizeFitting(
      CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .fittingSizeLevel
    )
    headerContainer.frame = CGRect(x: 0, y: 0, width: width, height: size.height)
    tableView.tableHeaderView = headerContainer
  }
}

