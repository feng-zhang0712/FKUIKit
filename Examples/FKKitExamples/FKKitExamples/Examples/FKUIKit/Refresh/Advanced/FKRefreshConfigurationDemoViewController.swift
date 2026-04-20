//
// FKRefreshConfigurationDemoViewController.swift
// FKKitExamples — FKRefresh demos
//
// `FKRefreshText`, silent refresh toggle, and minimum loading visibility duration.
//

import FKUIKit
import UIKit

final class FKRefreshConfigurationDemoViewController: UIViewController {

  private var items = (1...10).map { "Cfg \($0)" }

  private lazy var tableView: UITableView = {
    let tv = UITableView(frame: .zero, style: .insetGrouped)
    tv.translatesAutoresizingMaskIntoConstraints = false
    tv.register(UITableViewCell.self, forCellReuseIdentifier: "c")
    tv.dataSource = self
    return tv
  }()

  private lazy var silentSwitch: UISwitch = {
    let s = UISwitch()
    s.addTarget(self, action: #selector(silentChanged), for: .valueChanged)
    return s
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Configuration"
    view.backgroundColor = .systemGroupedBackground

    let lab = UILabel()
    lab.text = "Silent pull"
    lab.font = .preferredFont(forTextStyle: .caption1)
    lab.textColor = .secondaryLabel
    let row = UIStackView(arrangedSubviews: [lab, silentSwitch])
    row.spacing = 6
    navigationItem.rightBarButtonItem = UIBarButtonItem(customView: row)

    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    installControls()
  }

  @objc private func silentChanged() {
    tableView.fk_removePullToRefresh()
    tableView.fk_removeLoadMore()
    installControls()
  }

  private func installControls() {
    let texts = FKRefreshText(
      pullToRefresh: "Pull down to refresh",
      releaseToRefresh: "Release to refresh",
      headerLoading: "Refreshing...",
      headerFinished: "Refresh complete",
      headerListEmpty: "No items",
      headerFailed: "Refresh failed",
      footerLoading: "Loading more...",
      footerFinished: "Load complete",
      footerNoMoreData: "No more data",
      footerFailed: "Load failed",
      footerTapToRetry: "Tap to retry"
    )

    let cfg = FKRefreshConfiguration(
      triggerThreshold: 56,
      expandedHeight: 56,
      minimumLoadingVisibilityDuration: 0.45,
      tintColor: .systemBrown,
      texts: texts,
      isSilentRefresh: silentSwitch.isOn,
      isHapticFeedbackEnabled: true
    )

    tableView.fk_addPullToRefresh(configuration: cfg) { [weak self] in
      // Very fast “network” to show minimum visibility hold.
      FKRefreshDemoCommon.simulateRequest(delay: 0.08) {
        self?.items = (1...8).map { "Cfg refreshed \($0)" }
        self?.tableView.reloadData()
        self?.tableView.fk_pullToRefresh?.endRefreshing()
        self?.tableView.fk_loadMore?.resetToIdle()
      }
    }

    var loadCfg = cfg
    loadCfg.isSilentRefresh = false
    tableView.fk_addLoadMore(configuration: loadCfg) { [weak self] in
      FKRefreshDemoCommon.simulateRequest(delay: 0.5) {
        guard let self else { return }
        let n = self.items.count
        self.items.append(contentsOf: (n + 1...(n + 4)).map { "Cfg \($0)" })
        self.tableView.reloadData()
        self.tableView.fk_loadMore?.endRefreshing()
      }
    }
  }
}

extension FKRefreshConfigurationDemoViewController: UITableViewDataSource {
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
