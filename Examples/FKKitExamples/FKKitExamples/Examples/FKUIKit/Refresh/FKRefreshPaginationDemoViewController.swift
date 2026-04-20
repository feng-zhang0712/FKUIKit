//
// FKRefreshPaginationDemoViewController.swift
// FKKitExamples — FKRefresh demos
//
// `FKRefreshPagination`: reset on pull, `advance()` after each successful load-more.
//

import FKUIKit
import UIKit

final class FKRefreshPaginationDemoViewController: UIViewController {

  private var pagination = FKRefreshPagination()
  private var items: [String] = []

  private lazy var pageLabel: UILabel = {
    let l = UILabel()
    l.font = .monospacedSystemFont(ofSize: 12, weight: .semibold)
    l.textColor = .secondaryLabel
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
    title = "Pagination"
    navigationItem.titleView = pageLabel
    reloadPageLabel()

    view.backgroundColor = .systemGroupedBackground
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    loadFirstPageSilently()

    var cfg = FKRefreshConfiguration()
    cfg.tintColor = .systemPink
    tableView.fk_addPullToRefresh(configuration: cfg) { [weak self] in
      self?.handlePull()
    }
    tableView.fk_addLoadMore(configuration: cfg) { [weak self] in
      self?.handleLoadMore()
    }
  }

  private func reloadPageLabel() {
    pageLabel.text = "page = \(pagination.page)  rows = \(items.count)"
    pageLabel.sizeToFit()
  }

  private func loadFirstPageSilently() {
    pagination.resetForNewRequest()
    items = (1...8).map { "p\(pagination.page) — \($0)" }
    tableView.reloadData()
    reloadPageLabel()
  }

  private func handlePull() {
    FKRefreshDemoCommon.simulateRequest(delay: 0.9) { [weak self] in
      guard let self else { return }
      self.pagination.resetForNewRequest()
      self.items = (1...8).map { "p\(self.pagination.page) — \($0)" }
      self.tableView.reloadData()
      self.tableView.fk_pullToRefresh?.endRefreshing()
      self.tableView.fk_loadMore?.resetToIdle()
      self.reloadPageLabel()
    }
  }

  private func handleLoadMore() {
    FKRefreshDemoCommon.simulateRequest(delay: 0.8) { [weak self] in
      guard let self else { return }
      if self.items.count >= 35 {
        self.tableView.fk_loadMore?.endRefreshingWithNoMoreData()
        self.reloadPageLabel()
        return
      }
      self.pagination.advance()
      let base = self.items.count
      self.items.append(contentsOf: (1...8).map { "p\(self.pagination.page) — \(base + $0)" })
      self.tableView.reloadData()
      self.tableView.fk_loadMore?.endRefreshing()
      self.reloadPageLabel()
    }
  }
}

extension FKRefreshPaginationDemoViewController: UITableViewDataSource {
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
