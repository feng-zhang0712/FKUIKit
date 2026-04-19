//
// FKRefreshDefaultDemoViewController.swift
// FKKitExamples — FKRefresh demos
//
// Exercises `FKDefaultRefreshContentView`: simulated outcomes, `fk_beginPullToRefresh` / `fk_beginLoadMore`.
//

import FKUIKit
import UIKit

final class FKRefreshDefaultDemoViewController: UIViewController {

  private var items: [String] = (1...12).map { "Row \($0)" }
  private var page = 1
  private let pageSize = 8
  private let maxRows = 40

  private lazy var tableView: UITableView = {
    let tv = UITableView(frame: .zero, style: .insetGrouped)
    tv.translatesAutoresizingMaskIntoConstraints = false
    tv.register(UITableViewCell.self, forCellReuseIdentifier: "c")
    tv.dataSource = self
    return tv
  }()

  private lazy var statusLabel: UILabel = {
    let l = UILabel()
    l.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
    l.textColor = .secondaryLabel
    l.numberOfLines = 0
    l.translatesAutoresizingMaskIntoConstraints = false
    return l
  }()

  /// Full-width under the nav bar so segment titles are not truncated.
  private lazy var outcomeControl: UISegmentedControl = {
    let s = UISegmentedControl(items: ["Success", "Empty", "Error", "Fast"])
    s.selectedSegmentIndex = 0
    return s
  }()

  private lazy var controlPanel: UIView = {
    let panel = UIView()
    panel.backgroundColor = .secondarySystemGroupedBackground
    panel.translatesAutoresizingMaskIntoConstraints = false

    let caption = UILabel()
    caption.text = "Next request simulates"
    caption.font = .preferredFont(forTextStyle: .caption1)
    caption.textColor = .secondaryLabel
    caption.translatesAutoresizingMaskIntoConstraints = false

    outcomeControl.translatesAutoresizingMaskIntoConstraints = false

    let reset = makePanelButton(title: "Reset data") { [weak self] in self?.resetData() }
    let pull = makePanelButton(title: "Begin pull") { [weak self] in self?.triggerPull() }
    let more = makePanelButton(title: "Begin load more") { [weak self] in self?.triggerLoadMore() }

    let buttons = UIStackView(arrangedSubviews: [reset, pull, more])
    buttons.axis = .vertical
    buttons.spacing = 8
    buttons.distribution = .fillEqually
    buttons.translatesAutoresizingMaskIntoConstraints = false

    panel.addSubview(caption)
    panel.addSubview(outcomeControl)
    panel.addSubview(buttons)

    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: panel.topAnchor, constant: 10),
      caption.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 16),
      caption.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -16),

      outcomeControl.topAnchor.constraint(equalTo: caption.bottomAnchor, constant: 6),
      outcomeControl.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 16),
      outcomeControl.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -16),

      buttons.topAnchor.constraint(equalTo: outcomeControl.bottomAnchor, constant: 10),
      buttons.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 16),
      buttons.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -16),
      buttons.bottomAnchor.constraint(equalTo: panel.bottomAnchor, constant: -10),
    ])

    return panel
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Default"
    view.backgroundColor = .systemGroupedBackground

    let statusBar = UIView()
    statusBar.backgroundColor = .secondarySystemBackground
    statusBar.translatesAutoresizingMaskIntoConstraints = false
    statusBar.addSubview(statusLabel)

    view.addSubview(controlPanel)
    view.addSubview(statusBar)
    view.addSubview(tableView)

    NSLayoutConstraint.activate([
      controlPanel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      controlPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      controlPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),

      statusBar.topAnchor.constraint(equalTo: controlPanel.bottomAnchor),
      statusBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      statusBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

      statusLabel.topAnchor.constraint(equalTo: statusBar.topAnchor, constant: 6),
      statusLabel.leadingAnchor.constraint(equalTo: statusBar.leadingAnchor, constant: 10),
      statusLabel.trailingAnchor.constraint(equalTo: statusBar.trailingAnchor, constant: -10),
      statusLabel.bottomAnchor.constraint(equalTo: statusBar.bottomAnchor, constant: -6),

      tableView.topAnchor.constraint(equalTo: statusBar.bottomAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    var pull = FKRefreshConfiguration()
    pull.tintColor = .systemBlue
    tableView.fk_addPullToRefresh(configuration: pull) { [weak self] in
      self?.runPullRefresh()
    }
    tableView.fk_pullToRefresh?.onStateChanged = { [weak self] _, s in
      self?.updateStatus(pull: s)
    }

    var load = FKRefreshConfiguration()
    load.tintColor = .systemIndigo
    tableView.fk_addLoadMore(configuration: load) { [weak self] in
      self?.runLoadMore()
    }
    tableView.fk_loadMore?.onStateChanged = { [weak self] _, s in
      self?.updateStatus(load: s)
    }

    updateStatus()
  }

  private func makePanelButton(title: String, action: @escaping () -> Void) -> UIButton {
    var cfg = UIButton.Configuration.bordered()
    cfg.title = title
    cfg.titleAlignment = .center
    cfg.cornerStyle = .medium
    return UIButton(configuration: cfg, primaryAction: UIAction { _ in action() })
  }

  private func updateStatus(pull: FKRefreshState? = nil, load: FKRefreshState? = nil) {
    let p = pull ?? tableView.fk_pullToRefresh?.state ?? .idle
    let l = load ?? tableView.fk_loadMore?.state ?? .idle
    let pp = tableView.fk_pullToRefresh?.currentPullProgress ?? 0
    statusLabel.text =
      "pull: \(FKRefreshDemoCommon.stateDescription(p))  progress=\(String(format: "%.2f", pp))\n"
      + "load: \(FKRefreshDemoCommon.stateDescription(l))"
  }

  private func runPullRefresh() {
    let delay: TimeInterval = outcomeControl.selectedSegmentIndex == 3 ? 0.05 : 1.0
    FKRefreshDemoCommon.simulateRequest(delay: delay) { [weak self] in
      guard let self else { return }
      switch self.outcomeControl.selectedSegmentIndex {
      case 1:
        self.page = 1
        self.items = []
        self.tableView.reloadData()
        self.tableView.fk_pullToRefresh?.endRefreshingWithEmptyList()
      case 2:
        self.tableView.fk_pullToRefresh?.endRefreshingWithError(NSError(domain: "demo", code: -1))
      default:
        self.page = 1
        self.items = (1...self.pageSize).map { "Refreshed \($0)" }
        self.tableView.reloadData()
        self.tableView.fk_pullToRefresh?.endRefreshing()
        self.tableView.fk_loadMore?.resetToIdle()
      }
      self.updateStatus()
    }
  }

  private func runLoadMore() {
    let delay: TimeInterval = outcomeControl.selectedSegmentIndex == 3 ? 0.05 : 1.0
    FKRefreshDemoCommon.simulateRequest(delay: delay) { [weak self] in
      guard let self else { return }
      if self.outcomeControl.selectedSegmentIndex == 2 {
        self.tableView.fk_loadMore?.endRefreshingWithError()
        self.updateStatus()
        return
      }
      if self.items.count >= self.maxRows {
        self.tableView.fk_loadMore?.endRefreshingWithNoMoreData()
        self.updateStatus()
        return
      }
      let start = self.items.count + 1
      let end = min(start + self.pageSize - 1, self.maxRows)
      self.items.append(contentsOf: (start...end).map { "Row \($0)" })
      self.page += 1
      self.tableView.reloadData()
      self.tableView.fk_loadMore?.endRefreshing()
      if self.items.count >= self.maxRows {
        self.tableView.fk_loadMore?.endRefreshingWithNoMoreData()
      }
      self.updateStatus()
    }
  }

  @objc private func triggerPull() {
    tableView.fk_beginPullToRefresh()
  }

  @objc private func triggerLoadMore() {
    tableView.fk_beginLoadMore()
  }

  @objc private func resetData() {
    items = (1...12).map { "Row \($0)" }
    page = 1
    tableView.reloadData()
    tableView.fk_loadMore?.resetToIdle()
    updateStatus()
  }
}

extension FKRefreshDefaultDemoViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    items.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "c", for: indexPath)
    var c = cell.defaultContentConfiguration()
    c.text = items[indexPath.row]
    cell.contentConfiguration = c
    return cell
  }
}
