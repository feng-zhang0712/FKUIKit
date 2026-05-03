import FKUIKit
import UIKit

final class FKRefreshPolicyStressExampleViewController: UIViewController {
  private enum PolicyMode: Int {
    case mutuallyExclusive
    case queueing
    case parallel
  }

  private var items: [String] = (1...4).map { "Seed \($0)" }
  private var loadCount = 0

  private lazy var tableView: UITableView = {
    let view = UITableView(frame: .zero, style: .insetGrouped)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    view.dataSource = self
    return view
  }()

  private lazy var policyControl: UISegmentedControl = {
    let control = UISegmentedControl(items: ["Mutex", "Queue", "Parallel"])
    control.selectedSegmentIndex = 1
    control.addTarget(self, action: #selector(policyChanged), for: .valueChanged)
    return control
  }()

  private lazy var statusLabel: UILabel = {
    let label = UILabel()
    label.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.adjustsFontForContentSizeCategory = true
    return label
  }()

  private lazy var actionStack: UIStackView = {
    let pull = makeButton("Programmatic Pull") { [weak self] in
      self?.tableView.fk_beginPullToRefresh(animated: true)
    }
    let load = makeButton("Programmatic Load") { [weak self] in
      self?.tableView.fk_beginLoadMore()
    }
    let race = makeButton("Stress Trigger x5") { [weak self] in
      self?.runStressTriggers()
    }
    let reset = makeButton("Reset + Re-enable no-more") { [weak self] in
      self?.resetData()
    }
    let stack = UIStackView(arrangedSubviews: [pull, load, race, reset])
    stack.axis = .vertical
    stack.spacing = 8
    return stack
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Policy + Boundaries"
    view.backgroundColor = .systemGroupedBackground
    navigationItem.largeTitleDisplayMode = .always

    let top = UIStackView(arrangedSubviews: [policyControl, statusLabel, actionStack])
    top.axis = .vertical
    top.spacing = 8
    top.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(top)
    view.addSubview(tableView)

    NSLayoutConstraint.activate([
      top.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      top.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      top.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      tableView.topAnchor.constraint(equalTo: top.bottomAnchor, constant: 8),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    installRefresh()
    updatePolicy()
    tableView.fk_beginPullToRefresh(animated: true)
  }

  private func installRefresh() {
    var pullConfig = FKRefreshConfiguration()
    pullConfig.minimumLoadingVisibilityDuration = 0.3
    pullConfig.blocksUserInteractionWhileRefreshing = false
    tableView.fk_addPullToRefresh(configuration: pullConfig) { [weak self] in
      guard let self else { return }
      FKRefreshExampleCommon.simulateRequest(delay: 0.7) {
        self.items = (1...6).map { "Seed \($0)" }
        self.tableView.reloadData()
        self.tableView.fk_pullToRefresh?.endRefreshing()
        self.tableView.fk_resetLoadMoreState()
        self.updateStatus()
      }
    }

    var loadConfig = FKRefreshConfiguration()
    loadConfig.loadMorePreloadOffset = 140
    loadConfig.autohidesFooterWhenNotScrollable = false
    tableView.fk_addLoadMore(configuration: loadConfig) { [weak self] in
      guard let self else { return }
      FKRefreshExampleCommon.simulateRequest(delay: 0.55) {
        self.loadCount += 1
        if self.loadCount >= 4 {
          self.tableView.fk_loadMore?.endRefreshingWithNoMoreData()
          self.updateStatus()
          return
        }
        let start = self.items.count + 1
        self.items.append(contentsOf: (start..<(start + 4)).map { "Page \(self.loadCount) item \($0)" })
        self.tableView.reloadData()
        self.tableView.fk_loadMore?.endRefreshing()
        self.updateStatus()
      }
    }

    tableView.fk_pullToRefresh?.onStateChanged = { [weak self] _, _ in self?.updateStatus() }
    tableView.fk_loadMore?.onStateChanged = { [weak self] _, _ in self?.updateStatus() }
  }

  private func makeButton(_ title: String, action: @escaping () -> Void) -> UIButton {
    var config = UIButton.Configuration.bordered()
    config.title = title
    return UIButton(configuration: config, primaryAction: UIAction { _ in action() })
  }

  @objc
  private func policyChanged() {
    tableView.fk_pullToRefresh?.cancelCurrentAction(resetState: true)
    tableView.fk_loadMore?.cancelCurrentAction(resetState: true)
    tableView.fk_loadMore?.resetFooterAfterPullToRefresh()
    updatePolicy()
  }

  private func updatePolicy() {
    tableView.fk_refreshPolicy = FKRefreshPolicy(
      concurrency: selectedPolicy,
      autoFill: FKAutoFillPolicy(isEnabled: true, maxTriggerCount: 2)
    )
    updateStatus()
  }

  private var selectedPolicy: FKRefreshConcurrencyPolicy {
    let mode = PolicyMode(rawValue: policyControl.selectedSegmentIndex) ?? .queueing
    switch mode {
    case .mutuallyExclusive: return .mutuallyExclusive
    case .queueing: return .queueing
    case .parallel: return .parallel
    }
  }

  private func runStressTriggers() {
    for _ in 0..<5 {
      tableView.fk_beginPullToRefresh(animated: false)
      tableView.fk_beginLoadMore()
    }
  }

  private func resetData() {
    items = (1...4).map { "Reset \($0)" }
    loadCount = 0
    tableView.reloadData()
    tableView.fk_resetLoadMoreState()
    updateStatus()
  }

  private func updateStatus() {
    let pull = FKRefreshExampleCommon.stateDescription(tableView.fk_pullToRefresh?.state ?? .idle)
    let load = FKRefreshExampleCommon.stateDescription(tableView.fk_loadMore?.state ?? .idle)
    statusLabel.text = "policy: \(selectedPolicy)\npull: \(pull)\nload: \(load)\nrows: \(items.count)"
  }
}

extension FKRefreshPolicyStressExampleViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    items.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    var content = cell.defaultContentConfiguration()
    content.text = items[indexPath.row]
    content.secondaryText = "Preload offset example and duplicate-trigger guard."
    cell.contentConfiguration = content
    return cell
  }
}

