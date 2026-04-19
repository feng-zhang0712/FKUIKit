//
// FKEmptyStateSandboxViewController.swift
//
// Interactive sandbox: segmented scenarios, loading toggle, gradient toggle, optional list rows.
//

import FKUIKit
import UIKit

// MARK: - Sandbox

/// Stress-tests `fk_applyEmptyState` with mixed controls (mirrors real integration patterns).
final class FKEmptyStateSandboxViewController: UIViewController {

  // MARK: Types

  private enum Section: Int, CaseIterable {
    case actions
    case list
  }

  // MARK: Properties

  private var items: [String] = []
  private var showsLoading = false
  private var usesGradient = false

  private lazy var tableView: UITableView = {
    let view = UITableView(frame: .zero, style: .insetGrouped)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.dataSource = self
    view.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    return view
  }()

  private lazy var scenarioControl: UISegmentedControl = {
    let control = UISegmentedControl(items: ["No network", "No results", "Load failed"])
    control.selectedSegmentIndex = 0
    control.addTarget(self, action: #selector(scenarioChanged), for: .valueChanged)
    return control
  }()

  // MARK: Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Sandbox"
    view.backgroundColor = .systemGroupedBackground

    navigationItem.titleView = scenarioControl
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Toggle data",
      style: .plain,
      target: self,
      action: #selector(toggleData)
    )

    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    applyCurrentState(animated: false)
  }

  // MARK: Actions

  @objc private func scenarioChanged() {
    applyCurrentState(animated: true)
  }

  @objc private func toggleData() {
    if items.isEmpty {
      items = (1...10).map { "Sample row \($0)" }
    } else {
      items = []
    }
    tableView.reloadData()
    applyCurrentState(animated: true)
  }

  // MARK: Empty state

  private func applyCurrentState(animated: Bool) {
    let scenario: FKEmptyStateScenario
    switch scenarioControl.selectedSegmentIndex {
    case 1: scenario = .noSearchResult
    case 2: scenario = .loadFailed
    default: scenario = .noNetwork
    }

    var model = FKEmptyStateModel.scenario(scenario)
      .withImage(UIImage(systemName: "tray"))

    if items.isEmpty {
      model.phase = showsLoading ? .loading : model.phase
    } else {
      model.phase = .content
    }

    model.backgroundColor = .systemBackground
    model.automaticallyShowsWhenContentFits = true
    model.supportsTapToDismissKeyboard = true
    model.gradientColors = usesGradient ? [.systemBackground, .secondarySystemBackground] : []
    model.loadingMessage = showsLoading ? "Loading…" : nil

    tableView.fk_applyEmptyState(
      model,
      animated: animated,
      actionHandler: { [weak self] in
        self?.simulateReload()
      }
    )
  }

  private func simulateReload() {
    showsLoading = true
    applyCurrentState(animated: true)
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
      guard let self else { return }
      self.showsLoading = false
      self.items = (1...8).map { "Loaded row \($0)" }
      self.tableView.reloadData()
      self.applyCurrentState(animated: true)
    }
  }
}

// MARK: - UITableViewDataSource

extension FKEmptyStateSandboxViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int { Section.allCases.count }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard let section = Section(rawValue: section) else { return 0 }
    switch section {
    case .actions: return 2
    case .list: return items.count
    }
  }

  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    guard let section = Section(rawValue: section) else { return nil }
    switch section {
    case .actions: return "Toggles"
    case .list: return "List (empty shows placeholder)"
    }
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    guard let section = Section(rawValue: indexPath.section) else { return cell }

    switch section {
    case .actions:
      var config = cell.defaultContentConfiguration()
      let toggle = UISwitch()
      toggle.tag = indexPath.row
      toggle.addTarget(self, action: #selector(toggleSwitch(_:)), for: .valueChanged)

      if indexPath.row == 0 {
        config.text = "Show loading"
        toggle.isOn = showsLoading
      } else {
        config.text = "Gradient background"
        toggle.isOn = usesGradient
      }
      cell.contentConfiguration = config
      cell.accessoryView = toggle
      cell.selectionStyle = .none

    case .list:
      var config = cell.defaultContentConfiguration()
      config.text = items[indexPath.row]
      config.secondaryText = "Row \(indexPath.row + 1)"
      cell.contentConfiguration = config
      cell.accessoryView = nil
      cell.selectionStyle = .default
    }
    return cell
  }

  @objc private func toggleSwitch(_ sender: UISwitch) {
    if sender.tag == 0 {
      showsLoading = sender.isOn
    } else {
      usesGradient = sender.isOn
    }
    applyCurrentState(animated: true)
  }
}
