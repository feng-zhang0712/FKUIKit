//
// FKEmptyStateTableViewExampleViewController.swift
//
// Copy-ready table integration example with loading, empty, failed, and auto-hide flows.
//

import FKUIKit
import UIKit

/// Demonstrates UITableView integration, retry/refresh callbacks, and auto-hide when data exists.
final class FKEmptyStateTableViewExampleViewController: UIViewController {
  private var items: [String] = []

  private lazy var tableView: UITableView = {
    let table = UITableView(frame: .zero, style: .insetGrouped)
    table.translatesAutoresizingMaskIntoConstraints = false
    table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    table.dataSource = self
    return table
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "UITableView Empty State"
    view.backgroundColor = .systemBackground

    navigationItem.rightBarButtonItems = [
      UIBarButtonItem(title: "Load Data", style: .plain, target: self, action: #selector(loadDataTapped)),
      UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(clearTapped)),
    ]

    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    showLoadingThenFailed()
  }

  /// Simulates request start, then fallback to a failed state.
  private func showLoadingThenFailed() {
    tableView.fk_setEmptyState(phase: .loading)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
      self?.showLoadFailed()
    }
  }

  /// Shows load failed state with a retry callback.
  private func showLoadFailed() {
    let model = FKEmptyStateDemoFactory.makeLoadFailedModel()
    tableView.fk_applyEmptyState(model, actionHandler: { [weak self] in
      self?.reloadFromRetry()
    })
  }

  /// Retry entry point. Uses loading state first, then succeeds with data.
  private func reloadFromRetry() {
    tableView.fk_setEmptyState(phase: .loading)
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
      guard let self else { return }
      self.items = (1...12).map { "Table item \($0)" }
      self.tableView.reloadData()
      self.updatePlaceholderByItemCount()
    }
  }

  /// Automatically hides placeholder when data has been loaded.
  private func updatePlaceholderByItemCount() {
    var model = FKEmptyStateDemoFactory.makeCustomEmptyModel()
    model.title = "No Table Data"
    model.description = "Tap Load Data or Retry to fill the table."
    tableView.fk_updateEmptyState(
      itemCount: items.count,
      model: model,
      actionHandler: { [weak self] in
        self?.reloadFromRetry()
      }
    )
  }

  @objc private func loadDataTapped() {
    items = (1...8).map { "Loaded row \($0)" }
    tableView.reloadData()
    updatePlaceholderByItemCount()
  }

  @objc private func clearTapped() {
    items.removeAll()
    tableView.reloadData()
    updatePlaceholderByItemCount()
  }
}

extension FKEmptyStateTableViewExampleViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    items.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    var content = cell.defaultContentConfiguration()
    content.text = items[indexPath.row]
    content.secondaryText = "Auto-hide demo row \(indexPath.row + 1)"
    cell.contentConfiguration = content
    return cell
  }
}
