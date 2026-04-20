//
// FKEmptyStatePhasesDemoViewController.swift
//
// Segmented control switches `FKEmptyStatePhase` on an empty table.
//

import FKUIKit
import UIKit

// MARK: - Phases demo

/// Compares `.content`, `.loading`, `.empty`, and `.error` on the same table shell.
final class FKEmptyStatePhasesDemoViewController: UIViewController {

  // MARK: Types

  private enum Segment: Int, CaseIterable {
    case content
    case loading
    case empty
    case error

    var title: String {
      switch self {
      case .content: return "Content"
      case .loading: return "Loading"
      case .empty: return "Empty"
      case .error: return "Error"
      }
    }
  }

  // MARK: Properties

  private lazy var tableView: UITableView = {
    let t = UITableView(frame: .zero, style: .insetGrouped)
    t.translatesAutoresizingMaskIntoConstraints = false
    t.dataSource = self
    t.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    return t
  }()

  private lazy var phaseControl: UISegmentedControl = {
    let c = UISegmentedControl(items: Segment.allCases.map(\.title))
    c.selectedSegmentIndex = Segment.empty.rawValue
    c.addTarget(self, action: #selector(phaseChanged), for: .valueChanged)
    return c
  }()

  // MARK: Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Phases"
    view.backgroundColor = .systemGroupedBackground
    navigationItem.titleView = phaseControl

    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    applyPhase(animated: false)
  }

  // MARK: Actions

  @objc private func phaseChanged() {
    applyPhase(animated: true)
  }

  // MARK: Empty state

  private func applyPhase(animated: Bool) {
    guard let segment = Segment(rawValue: phaseControl.selectedSegmentIndex) else { return }

    switch segment {
    case .content:
      var m = FKEmptyStateModel(phase: .content)
      m.backgroundColor = .systemBackground
      tableView.fk_applyEmptyState(m, animated: animated, actionHandler: nil)

    case .loading:
      var m = FKEmptyStateModel(phase: .loading, title: "Loading example", loadingMessage: "Fetching data…")
      m.backgroundColor = .systemBackground
      m.activityIndicatorStyle = .large
      tableView.fk_applyEmptyState(m, animated: animated, actionHandler: nil)

    case .empty:
      var m = FKEmptyStateModel.scenario(.noSearchResult)
        .withImage(UIImage(systemName: "tray"))
      m.backgroundColor = .systemBackground
      tableView.fk_applyEmptyState(m, animated: animated, actionHandler: nil)

    case .error:
      var m = FKEmptyStateModel.scenario(.loadFailed)
        .withImage(UIImage(systemName: "exclamationmark.triangle"))
      m.backgroundColor = .systemBackground
      tableView.fk_applyEmptyState(m, animated: animated, actionHandler: { [weak self] in
        self?.showRetryToast()
      })
    }
  }

  private func showRetryToast() {
    let alert = UIAlertController(title: "Retry", message: "Would start a new request.", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
  }
}

// MARK: - UITableViewDataSource

extension FKEmptyStatePhasesDemoViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 0 }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
  }
}
