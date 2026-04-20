//
// FKRefreshGlobalSettingsDemoViewController.swift
// FKKitExamples — FKRefresh demos
//
// Sets global defaults via `FKRefreshManager`, then restores originals on pop.
//

import FKUIKit
import UIKit

final class FKRefreshGlobalSettingsDemoViewController: UIViewController {

  private var savedPull: FKRefreshConfiguration!
  private var savedLoad: FKRefreshConfiguration!

  private var items = (1...14).map { "Global \($0)" }

  private lazy var hintLabel: UILabel = {
    let l = UILabel()
    l.font = .preferredFont(forTextStyle: .footnote)
    l.textColor = .secondaryLabel
    l.numberOfLines = 0
    l.text = "This screen sets FKRefreshSettings to orange + custom pull copy, then adds controls with configuration: nil."
    l.translatesAutoresizingMaskIntoConstraints = false
    return l
  }()

  private lazy var tableView: UITableView = {
    let tv = UITableView(frame: .zero, style: .insetGrouped)
    tv.translatesAutoresizingMaskIntoConstraints = false
    tv.register(UITableViewCell.self, forCellReuseIdentifier: "c")
    tv.dataSource = self
    return tv
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKRefreshSettings"
    view.backgroundColor = .systemGroupedBackground

    savedPull = FKRefreshSettings.pullToRefresh
    savedLoad = FKRefreshSettings.loadMore

    var global = FKRefreshConfiguration()
    global.tintColor = .systemOrange
    var t = FKRefreshText.default
    t.pullToRefresh = "[Global] Pull me"
    t.footerLoading = "[Global] Loading…"
    global.texts = t
    FKRefreshManager.shared.applyGlobalConfiguration(
      pullToRefresh: global,
      loadMore: global
    )

    let stack = UIStackView(arrangedSubviews: [hintLabel, tableView])
    stack.axis = .vertical
    stack.spacing = 8
    stack.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(stack)

    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      stack.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    tableView.fk_addPullToRefresh(configuration: nil) { [weak self] in
      FKRefreshDemoCommon.simulateRequest(delay: 1.0) {
        self?.items = (1...12).map { "Global refresh \($0)" }
        self?.tableView.reloadData()
        self?.tableView.fk_pullToRefresh?.endRefreshing()
        self?.tableView.fk_loadMore?.resetToIdle()
      }
    }

    tableView.fk_addLoadMore(configuration: nil) { [weak self] in
      FKRefreshDemoCommon.simulateRequest(delay: 0.9) {
        guard let self else { return }
        let n = self.items.count
        self.items.append(contentsOf: (n + 1...(n + 5)).map { "Global \($0)" })
        self.tableView.reloadData()
        self.tableView.fk_loadMore?.endRefreshing()
      }
    }

    // Auto refresh to verify global style immediately.
    tableView.fk_beginPullToRefresh(animated: true)
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if isMovingFromParent {
      FKRefreshManager.shared.applyGlobalConfiguration(
        pullToRefresh: savedPull,
        loadMore: savedLoad
      )
    }
  }
}

extension FKRefreshGlobalSettingsDemoViewController: UITableViewDataSource {
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
