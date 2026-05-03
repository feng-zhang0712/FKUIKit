import FKUIKit
import UIKit

final class FKRefreshAsyncAwaitExampleViewController: UIViewController {

  private enum ResultMode: Int {
    case success
    case noMore
    case failed
  }

  private var items: [String] = FKRefreshAsyncAwaitExampleViewController.makeInitialItems()
  private let maxItems = 40

  private static func makeInitialItems() -> [String] {
    (1...24).map { "Async item \($0)" }
  }

  private lazy var tableView: UITableView = {
    let tv = UITableView(frame: .zero, style: .insetGrouped)
    tv.translatesAutoresizingMaskIntoConstraints = false
    tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tv.dataSource = self
    return tv
  }()

  private lazy var modeControl: UISegmentedControl = {
    let control = UISegmentedControl(items: ["Success", "No more", "Failed"])
    control.selectedSegmentIndex = 0
    control.addTarget(self, action: #selector(modeControlChanged), for: .valueChanged)
    return control
  }()

  private lazy var statusLabel: UILabel = {
    let label = UILabel()
    label.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Async/Await"
    view.backgroundColor = .systemGroupedBackground

    let stack = UIStackView(arrangedSubviews: [modeControl, statusLabel])
    stack.axis = .vertical
    stack.spacing = 8
    stack.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(stack)
    view.addSubview(tableView)

    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
      stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

      tableView.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 8),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    var pullConfig = FKRefreshConfiguration(
      tintColor: .systemCyan,
      automaticallyEndsRefreshingOnAsyncCompletion: true,
      automaticEndDelay: 0.2
    )
    pullConfig.texts.headerLoading = "Async refreshing..."

    tableView.fk_addPullToRefresh(configuration: pullConfig, asyncAction: { [weak self] in
      guard let self else { return }
      try await FKRefreshExampleCommon.simulateAsyncRequest(delay: 0.8)
      if Task.isCancelled { return }
      // Keep the same title pattern before and after refresh; `automaticallyEndsRefreshingOnAsyncCompletion` ends the header.
      self.items = Self.makeInitialItems()
      self.tableView.reloadData()
      self.tableView.fk_loadMore?.resetFooterAfterPullToRefresh()
    })

    var loadConfig = pullConfig
    // Footer must end explicitly: `throw` + `automaticallyEndsRefreshingOnAsyncCompletion` would double-drive failure/success.
    loadConfig.automaticallyEndsRefreshingOnAsyncCompletion = false
    loadConfig.autohidesFooterWhenNotScrollable = false
    loadConfig.texts.footerLoading = "Async loading..."
    tableView.fk_addLoadMore(configuration: loadConfig, asyncAction: { [weak self] in
      guard let self else { return }
      await self.handleAsyncLoadMore()
    })

    tableView.fk_pullToRefresh?.onStateChanged = { [weak self] _, _ in
      self?.reloadStatusText()
    }
    tableView.fk_loadMore?.onStateChanged = { [weak self] _, _ in
      self?.reloadStatusText()
    }
    reloadStatusText()

    // Auto refresh right after setup.
    tableView.fk_beginPullToRefresh(animated: true)
  }

  private var selectedResultMode: ResultMode {
    ResultMode(rawValue: modeControl.selectedSegmentIndex) ?? .success
  }

  @objc private func modeControlChanged() {
    tableView.fk_pullToRefresh?.cancelCurrentAction(resetState: true)
    tableView.fk_loadMore?.cancelCurrentAction(resetState: true)
    items = Self.makeInitialItems()
    tableView.reloadData()
    tableView.setContentOffset(.zero, animated: false)
    tableView.fk_loadMore?.resetFooterAfterPullToRefresh()
    reloadStatusText()
  }

  private func handleAsyncLoadMore() async {
    do {
      try await FKRefreshExampleCommon.simulateAsyncRequest(delay: 0.9)
    } catch {
      if Task.isCancelled {
        tableView.fk_loadMore?.cancelCurrentAction(resetState: true)
      } else {
        tableView.fk_loadMore?.endRefreshingWithError(error)
      }
      return
    }
    if Task.isCancelled {
      tableView.fk_loadMore?.cancelCurrentAction(resetState: true)
      return
    }

    switch selectedResultMode {
    case .success:
      guard items.count < maxItems else {
        tableView.fk_loadMore?.endRefreshingWithNoMoreData()
        return
      }
      let start = items.count + 1
      let end = min(start + 7, maxItems)
      items.append(contentsOf: (start...end).map { "Async item \($0)" })
      tableView.reloadData()

      if items.count >= maxItems {
        tableView.fk_loadMore?.endRefreshingWithNoMoreData()
      } else {
        tableView.fk_loadMore?.endRefreshing()
      }
    case .noMore:
      tableView.fk_loadMore?.endRefreshingWithNoMoreData()
    case .failed:
      struct AsyncDemoError: LocalizedError { var errorDescription: String? { "Async load failed." } }
      tableView.fk_loadMore?.endRefreshingWithError(AsyncDemoError())
    }
  }

  private func reloadStatusText() {
    let pull = FKRefreshExampleCommon.stateDescription(tableView.fk_pullToRefresh?.state ?? .idle)
    let load = FKRefreshExampleCommon.stateDescription(tableView.fk_loadMore?.state ?? .idle)
    let modeTitles = ["Success", "No more", "Failed"]
    let mi = min(max(0, modeControl.selectedSegmentIndex), modeTitles.count - 1)
    let mode = modeTitles[mi]
    statusLabel.text = "mode: \(mode)\npull: \(pull)\nload: \(load)\nrows: \(items.count)"
  }
}

extension FKRefreshAsyncAwaitExampleViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    items.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    var content = cell.defaultContentConfiguration()
    content.text = items[indexPath.row]
    cell.contentConfiguration = content
    return cell
  }
}
