//
//  FKListKitTableExampleViewController.swift
//  FKKitExamples
//
//  End-to-end demo: ``FKListPlugin`` + ``UITableView`` with pagination, pull-to-refresh, load-more,
//  first-load skeleton, empty/error overlays, and load-more failures — backed entirely by mock data.
//

import UIKit
import FKCompositeKit
import FKUIKit

// MARK: - Model

/// Row model for the demo list (in real apps you may map from DTO → domain; kept minimal here).
struct DemoItemModel: Equatable, Hashable {
  let id: String
  let title: String
  let content: String
}

// MARK: - Cell

private extension UITableViewCell {
  static var demoReuseId: String { String(describing: DemoItemCell.self) }
}

/// Minimal cell style; uses ``FKListCellConfigurable`` to bind UI to ``DemoItemModel``.
final class DemoItemCell: UITableViewCell, FKListCellConfigurable {

  func configure(with item: DemoItemModel) {
    var config = defaultContentConfiguration()
    config.text = item.title
    config.secondaryText = item.content
    config.secondaryTextProperties.numberOfLines = 2
    config.secondaryTextProperties.color = .secondaryLabel
    contentConfiguration = config
    accessoryType = .none
  }
}

// MARK: - Mock service

/// Pure local async simulation: delay + random batch sizes / empty / failure.
///
/// - Note: All randomness lives here; the screen only maps outcomes into ``FKListPlugin`` APIs.
private final class DemoListMockService {

  enum Outcome {
    case items([DemoItemModel])
    case empty
    case failure(message: String)
  }

  /// When enabled, the next first-page / refresh request returns an empty list (useful for validating empty state).
  var forceNextRefreshEmpty = false
  /// When enabled, the next request (initial/refresh/load-more) fails.
  var forceNextFailure = false
  /// Item count range for initial/refresh responses (inclusive).
  var refreshItemCountRange: ClosedRange<Int> = 4...12
  /// Page size for load-more responses (the final page may still end earlier due to pagination policy).
  var loadMorePageSize: Int = 8

  private let queue = DispatchQueue(label: "demo.list.mock", qos: .userInitiated)

  func simulateRequest(
    page: Int,
    limit: Int,
    isFirstPage: Bool,
    completion: @escaping @MainActor (Outcome) -> Void
  ) {
    queue.async { [weak self] in
      guard let self else { return }
      // Simulate network RTT.
      Thread.sleep(forTimeInterval: Double.random(in: 0.35...0.85))
      let outcome: Outcome
      if self.forceNextFailure {
        self.forceNextFailure = false
        outcome = .failure(message: "Forced demo failure (simulating a 503).")
      } else if isFirstPage, Double.random(in: 0...1) < 0.06 {
        // Initial/refresh: ~6% probability to enter full-screen ``FKListState.error`` (or footer-failure when rows exist).
        outcome = .failure(message: "Refresh failed. Please try again.")
      } else if isFirstPage, self.forceNextRefreshEmpty {
        self.forceNextRefreshEmpty = false
        outcome = .empty
      } else if !isFirstPage, Double.random(in: 0...1) < 0.12 {
        // Load-more: inject an extra ~12% failure rate to demonstrate ``loadMoreFailed`` and footer error animations.
        outcome = .failure(message: "Load more failed. Please retry.")
      } else if isFirstPage, Double.random(in: 0...1) < 0.08 {
        outcome = .empty
      } else if !isFirstPage, Double.random(in: 0...1) < 0.1 {
        outcome = .failure(message: "Network is unstable. Please try again later.")
      } else {
        let count: Int
        if isFirstPage {
          count = Int.random(in: self.refreshItemCountRange)
        } else {
          count = min(limit, self.loadMorePageSize)
        }
        let base = (page - 1) * limit
        let items = (0..<count).map { offset -> DemoItemModel in
          let index = base + offset
          return DemoItemModel(
            id: "demo-\(index)",
            title: "Page \(page) · Row \(offset + 1)",
            content: "Placeholder copy #\(index). Replace with your own summary/tags/rich text in real screens."
          )
        }
        outcome = .items(items)
      }
      DispatchQueue.main.async {
        completion(outcome)
      }
    }
  }
}

// MARK: - View controller

/// Demo host screen: **compose** ``FKListPlugin`` (no base controller inheritance); explicitly attaches/detaches within lifecycle.
final class FKListKitTableExampleViewController: UIViewController, FKListCapable {

  // MARK: Subviews

  private let tableView: UITableView = {
    let tv = UITableView(frame: .zero, style: .insetGrouped)
    tv.translatesAutoresizingMaskIntoConstraints = false
    tv.keyboardDismissMode = .onDrag
    return tv
  }()

  /// First-load skeleton host, covering the same area as the list. During ``.loading(.initial)``,
  /// ``FKListPlugin`` hides the table and shows the skeleton.
  private let skeletonHost = FKSkeletonContainerView()

  // MARK: Composition

  private let mockService = DemoListMockService()

  /// List plugin: the generic ``Item`` matches ``DemoItemModel`` so `handleSuccess(data:)` can infer batch counts.
  private lazy var listPlugin: FKListPlugin<DemoItemModel> = {
    var configuration = FKListConfiguration()
    configuration.pagination = FKPageManagerConfiguration(pageSize: 8, mode: .page(firstPageIndex: 1))
    configuration.enablesPullToRefresh = true
    configuration.enablesLoadMore = true
    configuration.enablesSkeletonOnInitialLoad = true
    configuration.presentsEmptyStateOverlay = true
    configuration.presentsErrorStateOverlay = true
    configuration.tracksItemCountForRefreshFailureUX = true
    // End pagination after 3 successful pages; decoupled from variable page sizes returned by the mock service.
    configuration.hasMoreEvaluator = { [weak self] _, _ in
      guard let self else { return false }
      let page = self.listPlugin.pageManager.lastSuccessfulPage ?? 0
      return page < 3
    }
    return FKListPlugin<DemoItemModel>(configuration: configuration)
  }()

  // MARK: Data

  private var items: [DemoItemModel] = []

  // MARK: Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKListKit (Table)"
    view.backgroundColor = .systemBackground
    configureNavigationItems()
    configureHierarchy()
    configureTable()
    buildSkeletonLayout()
    mountListPlugin()
    // Kick off initial load right after mounting (skeleton + ``onRefresh``).
    startRefresh()
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    // Detach refresh controls when leaving the navigation stack to avoid duplicate callbacks.
    // (Avoid calling `MainActor` APIs from `deinit` which is not actor-isolated.)
    if isMovingFromParent || isBeingDismissed {
      listPlugin.detach()
    }
  }

  // MARK: Setup

  private func configureNavigationItems() {
    navigationItem.rightBarButtonItems = [
      UIBarButtonItem(
        title: "Next empty",
        style: .plain,
        target: self,
        action: #selector(toggleNextEmpty)
      ),
      UIBarButtonItem(
        title: "Next failure",
        style: .plain,
        target: self,
        action: #selector(toggleNextFailure)
      ),
    ]
  }

  @objc private func toggleNextEmpty() {
    mockService.forceNextRefreshEmpty.toggle()
    let on = mockService.forceNextRefreshEmpty
    presentToast(on ? "Enabled: next refresh returns 0 items." : "Disabled: forced empty list.")
  }

  @objc private func toggleNextFailure() {
    mockService.forceNextFailure.toggle()
    let on = mockService.forceNextFailure
    presentToast(on ? "Enabled: next request will fail." : "Disabled: forced failure.")
  }

  private func presentToast(_ message: String) {
    let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
    present(alert, animated: true)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { [weak alert] in
      alert?.dismiss(animated: true)
    }
  }

  private func configureHierarchy() {
    skeletonHost.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(skeletonHost)
    view.addSubview(tableView)

    NSLayoutConstraint.activate([
      skeletonHost.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      skeletonHost.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      skeletonHost.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      skeletonHost.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  private func configureTable() {
    tableView.dataSource = self
    tableView.register(DemoItemCell.self, forCellReuseIdentifier: UITableViewCell.demoReuseId)
  }

  /// Builds skeleton blocks that mimic row heights.
  /// Subviews must be registered via ``FKSkeletonContainerView/addSkeletonSubview(_:)``.
  private func buildSkeletonLayout() {
    skeletonHost.removeAllSkeletonSubviews()
    var previous: FKSkeletonView?
    for _ in 0..<8 {
      let row = FKSkeletonView()
      row.translatesAutoresizingMaskIntoConstraints = false
      row.heightAnchor.constraint(equalToConstant: 56).isActive = true
      row.layer.cornerRadius = 10
      row.clipsToBounds = true
      skeletonHost.addSkeletonSubview(row)
      NSLayoutConstraint.activate([
        row.leadingAnchor.constraint(equalTo: skeletonHost.leadingAnchor, constant: 20),
        row.trailingAnchor.constraint(equalTo: skeletonHost.trailingAnchor, constant: -20),
      ])
      if let previous {
        row.topAnchor.constraint(equalTo: previous.bottomAnchor, constant: 12).isActive = true
      } else {
        row.topAnchor.constraint(equalTo: skeletonHost.topAnchor, constant: 24).isActive = true
      }
      previous = row
    }
    if let previous {
      previous.bottomAnchor.constraint(lessThanOrEqualTo: skeletonHost.bottomAnchor, constant: -16).isActive = true
    }
  }

  // MARK: Plugin wiring

  /// Mounts the plugin after the view hierarchy is ready: binds the scroll view, empty/error host, skeleton host,
  /// and the host view controller.
  private func mountListPlugin() {
    listPlugin.currentTotalItemCount = { [weak self] in
      self?.items.count ?? 0
    }

    listPlugin.onRefresh = { [weak self] parameters in
      self?.handleRefreshLikeRequest(parameters: parameters)
    }

    listPlugin.onLoadMore = { [weak self] parameters in
      self?.handleLoadMoreRequest(parameters: parameters)
    }

    /// Primary action on empty/error overlay: re-trigger the initial-load path.
    listPlugin.onEmptyOrErrorOverlayPrimaryAction = { [weak self] in
      self?.startRefresh()
    }

    listPlugin.attach(
      scrollView: tableView,
      emptyStateHost: view,
      skeletonHost: skeletonHost,
      hostViewController: self
    )
  }

  // MARK: Requests

  /// `startRefresh` as used in this demo maps to ``FKListPlugin/startInitialLoad()`` (first page / full reload entry).
  ///
  /// If you want to **simulate a real user pull-to-refresh** (``FKPageLoadPhase.refreshing``),
  /// call ``tableView.fk_beginPullToRefresh(animated:)`` instead. It triggers the same `onRefresh` callback,
  /// but skips the first-load skeleton (``.loading(.initial)``).
  private func startRefresh() {
    listPlugin.startInitialLoad()
  }

  private func handleRefreshLikeRequest(parameters: FKPageRequestParameters) {
    let page = parameters.page ?? 1
    mockService.simulateRequest(page: page, limit: parameters.limit, isFirstPage: true) { [weak self] outcome in
      guard let self else { return }
      switch outcome {
      case .items(let batch):
        self.items = batch
        self.tableView.reloadData()
        self.listPlugin.handleSuccess(data: batch, totalItemCountAfterMerge: self.items.count)
      case .empty:
        self.items = []
        self.tableView.reloadData()
        self.listPlugin.handleSuccess(data: [], totalItemCountAfterMerge: 0)
      case .failure(let message):
        self.listPlugin.handleError(
          DemoListError.stub(message),
          listError: .business(code: "DEMO", message: message)
        )
      }
    }
  }

  private func handleLoadMoreRequest(parameters: FKPageRequestParameters) {
    let page = parameters.page ?? 1
    mockService.simulateRequest(page: page, limit: parameters.limit, isFirstPage: false) { [weak self] outcome in
      guard let self else { return }
      switch outcome {
      case .items(let batch):
        self.items.append(contentsOf: batch)
        self.tableView.reloadData()
        self.listPlugin.handleSuccess(data: batch, totalItemCountAfterMerge: self.items.count)
      case .empty:
        // Load-more returned an empty array: treat as a normal completion with no new rows.
        self.tableView.reloadData()
        self.listPlugin.handleSuccess(data: [], totalItemCountAfterMerge: self.items.count)
      case .failure(let message):
        self.listPlugin.handleError(
          DemoListError.stub(message),
          listError: .business(code: "DEMO_LOAD_MORE", message: message)
        )
      }
    }
  }
}

// MARK: - UITableViewDataSource

extension FKListKitTableExampleViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    items.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.demoReuseId, for: indexPath) as! DemoItemCell
    cell.configure(with: items[indexPath.row])
    return cell
  }
}

// MARK: - Error type

private struct DemoListError: LocalizedError {
  let message: String
  var errorDescription: String? { message }

  static func stub(_ message: String) -> DemoListError {
    DemoListError(message: message)
  }
}
