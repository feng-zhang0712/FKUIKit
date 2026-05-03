import FKUIKit
import UIKit

final class FKRefreshGIFDemoViewController: UIViewController {

  private var items = (1...18).map { "GIF demo \($0)" }

  private lazy var tableView: UITableView = {
    let tv = UITableView(frame: .zero, style: .insetGrouped)
    tv.translatesAutoresizingMaskIntoConstraints = false
    tv.register(UITableViewCell.self, forCellReuseIdentifier: "c")
    tv.dataSource = self
    return tv
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "GIF"
    view.backgroundColor = .systemGroupedBackground
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    let gifPull = FKGIFRefreshContentView()
    gifPull.image = FKRefreshExampleCommon.makeDemoAnimatedImage()

    var cfg = FKRefreshConfiguration()
    cfg.expandedHeight = 56
    tableView.fk_addPullToRefresh(configuration: cfg, contentView: gifPull) { [weak self] in
      FKRefreshExampleCommon.simulateRequest(delay: 1.2) {
        self?.items = (1...12).map { "GIF demo \($0)" }
        self?.tableView.reloadData()
        self?.tableView.fk_pullToRefresh?.endRefreshing()
        self?.tableView.fk_loadMore?.resetToIdle()
      }
    }

    let gifLoad = FKGIFRefreshContentView()
    gifLoad.image = FKRefreshExampleCommon.makeDemoAnimatedImage()
    tableView.fk_addLoadMore(configuration: cfg, contentView: gifLoad) { [weak self] in
      FKRefreshExampleCommon.simulateRequest(delay: 1.0) {
        guard let self else { return }
        let n = self.items.count
        self.items.append(contentsOf: (n + 1...(n + 6)).map { "GIF \($0)" })
        self.tableView.reloadData()
        self.tableView.fk_loadMore?.endRefreshing()
      }
    }
  }
}

extension FKRefreshGIFDemoViewController: UITableViewDataSource {
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
