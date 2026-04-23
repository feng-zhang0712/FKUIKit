#if canImport(SwiftUI)
import FKUIKit
import SwiftUI
import UIKit

@available(iOS 13.0, *)
struct FKRefreshSwiftUIBridgeDemoView: View {
  var body: some View {
    FKRefreshBridgeTableContainer()
      .navigationTitle("Refresh Bridge")
      .navigationBarTitleDisplayMode(.inline)
  }
}

@available(iOS 13.0, *)
private struct FKRefreshBridgeTableContainer: UIViewControllerRepresentable {
  func makeUIViewController(context: Context) -> FKRefreshBridgeTableViewController {
    FKRefreshBridgeTableViewController()
  }

  func updateUIViewController(_ uiViewController: FKRefreshBridgeTableViewController, context: Context) {}
}

private final class FKRefreshBridgeTableViewController: UITableViewController {
  private let bridge = FKRefreshSwiftUIBridge()
  private var items: [String] = (1...14).map { "SwiftUI row \($0)" }

  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.rowHeight = 58
    bridge.bind(scrollView: tableView)
    bridge.setPolicy(FKRefreshPolicy(concurrency: .queueing, autoFill: FKAutoFillPolicy(isEnabled: true, maxTriggerCount: 1)))

    var pull = FKRefreshConfiguration()
    pull.tintColor = .systemTeal
    bridge.installPullToRefresh(configuration: pull) { [weak self] context in
      guard let self else { return }
      FKRefreshExampleCommon.simulateRequest(delay: 0.75) {
        self.items = (1...14).map { "Bridge refreshed \($0)" }
        self.tableView.reloadData()
        self.tableView.fk_pullToRefresh?.endRefreshing(token: context.token)
        self.tableView.fk_resetLoadMoreState()
      }
    }

    var load = FKRefreshConfiguration()
    load.loadMorePreloadOffset = 120
    bridge.installLoadMore(configuration: load) { [weak self] context in
      guard let self else { return }
      FKRefreshExampleCommon.simulateRequest(delay: 0.65) {
        if self.items.count >= 36 {
          self.tableView.fk_loadMore?.endRefreshingWithNoMoreData(token: context.token)
          return
        }
        let start = self.items.count + 1
        self.items.append(contentsOf: (start..<(start + 6)).map { "Bridge row \($0)" })
        self.tableView.reloadData()
        self.tableView.fk_loadMore?.endRefreshing(token: context.token)
      }
    }
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    bridge.beginPullToRefresh(animated: true)
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    items.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    var content = cell.defaultContentConfiguration()
    content.text = items[indexPath.row]
    content.secondaryText = "Shared FKRefresh core through SwiftUI bridge."
    cell.contentConfiguration = content
    return cell
  }
}
#endif

