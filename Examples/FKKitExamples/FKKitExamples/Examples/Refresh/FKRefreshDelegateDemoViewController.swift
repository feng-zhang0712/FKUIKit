//
// FKRefreshDelegateDemoViewController.swift
// FKKitExamples — FKRefresh demos
//
// `FKRefreshControlDelegate` vs `onStateChanged`; bottom log shows transitions.
//

import FKUIKit
import UIKit

final class FKRefreshDelegateDemoViewController: UIViewController {

  private var items = (1...15).map { "Delegate \($0)" }

  private lazy var tableView: UITableView = {
    let tv = UITableView(frame: .zero, style: .insetGrouped)
    tv.translatesAutoresizingMaskIntoConstraints = false
    tv.register(UITableViewCell.self, forCellReuseIdentifier: "c")
    tv.dataSource = self
    return tv
  }()

  private lazy var logView: UITextView = {
    let t = UITextView()
    t.font = .monospacedSystemFont(ofSize: 9, weight: .regular)
    t.isEditable = false
    t.backgroundColor = .secondarySystemBackground
    t.translatesAutoresizingMaskIntoConstraints = false
    return t
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Delegate"
    view.backgroundColor = .systemGroupedBackground

    view.addSubview(tableView)
    view.addSubview(logView)

    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: logView.topAnchor),

      logView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      logView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      logView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      logView.heightAnchor.constraint(equalToConstant: 120),
    ])

    var cfg = FKRefreshConfiguration()
    cfg.tintColor = .systemGreen
    let pull = tableView.fk_addPullToRefresh(configuration: cfg) { [weak self] in
      FKRefreshDemoCommon.simulateRequest(delay: 0.9) {
        self?.items = (1...12).map { "Pull ok \($0)" }
        self?.tableView.reloadData()
        self?.tableView.fk_pullToRefresh?.endRefreshing()
        self?.tableView.fk_loadMore?.resetToIdle()
      }
    }
    pull.delegate = self
    pull.onStateChanged = { [weak self] _, state in
      self?.appendLog("onStateChanged pull: \(FKRefreshDemoCommon.stateDescription(state))")
    }

    let load = tableView.fk_addLoadMore(configuration: cfg) { [weak self] in
      FKRefreshDemoCommon.simulateRequest(delay: 0.8) {
        guard let self else { return }
        let n = self.items.count
        self.items.append(contentsOf: (n + 1...(n + 5)).map { "Delegate \($0)" })
        self.tableView.reloadData()
        self.tableView.fk_loadMore?.endRefreshing()
      }
    }
    load.delegate = self
    load.onStateChanged = { [weak self] _, state in
      self?.appendLog("onStateChanged load: \(FKRefreshDemoCommon.stateDescription(state))")
    }
  }

  private func appendLog(_ line: String) {
    logView.text = (logView.text ?? "") + line + "\n"
    let ns = logView.text as NSString
    guard ns.length > 0 else { return }
    logView.scrollRangeToVisible(NSRange(location: ns.length - 1, length: 1))
  }
}

extension FKRefreshDelegateDemoViewController: FKRefreshControlDelegate {
  func refreshControl(_ control: FKRefreshControl, didChange state: FKRefreshState, from previous: FKRefreshState) {
    let kindName = control.kind == .pullToRefresh ? "FKRefreshKind.pullToRefresh" : "FKRefreshKind.loadMore"
    appendLog("delegate \(kindName): \(FKRefreshDemoCommon.stateDescription(previous)) → \(FKRefreshDemoCommon.stateDescription(state))")
  }
}

extension FKRefreshDelegateDemoViewController: UITableViewDataSource {
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
