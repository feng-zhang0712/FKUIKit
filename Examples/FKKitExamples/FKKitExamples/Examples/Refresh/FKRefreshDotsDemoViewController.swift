//
// FKRefreshDotsDemoViewController.swift
// FKKitExamples — FKRefresh demos
//
// Custom `FKRefreshContentView` implementation (bouncing dots) on pull and load-more.
//

import FKUIKit
import UIKit

final class FKRefreshDotsDemoViewController: UIViewController {

  private var items = (1...20).map { "Dots \($0)" }

  private lazy var tableView: UITableView = {
    let tv = UITableView(frame: .zero, style: .insetGrouped)
    tv.translatesAutoresizingMaskIntoConstraints = false
    tv.register(UITableViewCell.self, forCellReuseIdentifier: "c")
    tv.dataSource = self
    return tv
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Custom dots"
    view.backgroundColor = .systemGroupedBackground
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    var cfg = FKRefreshConfiguration()
    cfg.tintColor = .systemPurple
    let dots = FKDotsRefreshContentView()
    tableView.fk_addPullToRefresh(configuration: cfg, contentView: dots) { [weak self] in
      FKRefreshDemoCommon.simulateRequest(delay: 1.0) {
        self?.items = (1...15).map { "Dots refreshed \($0)" }
        self?.tableView.reloadData()
        self?.tableView.fk_pullToRefresh?.endRefreshing()
        self?.tableView.fk_loadMore?.resetToIdle()
      }
    }

    tableView.fk_addLoadMore(configuration: cfg, contentView: FKDotsRefreshContentView()) { [weak self] in
      FKRefreshDemoCommon.simulateRequest(delay: 1.0) {
        guard let self else { return }
        let n = self.items.count
        self.items.append(contentsOf: (n + 1...(n + 5)).map { "Dots \($0)" })
        self.tableView.reloadData()
        self.tableView.fk_loadMore?.endRefreshing()
      }
    }
  }
}

extension FKRefreshDotsDemoViewController: UITableViewDataSource {
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
