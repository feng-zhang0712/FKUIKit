import FKUIKit
import UIKit

final class FKRefreshHostedDemoViewController: UIViewController {

  private var items = (1...16).map { "Hosted \($0)" }

  private lazy var hostedPullLabel: UILabel = {
    let l = UILabel()
    l.font = .boldSystemFont(ofSize: 13)
    l.textAlignment = .center
    l.textColor = .label
    l.numberOfLines = 2
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
    title = "Hosted"
    view.backgroundColor = .systemGroupedBackground
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    hostedPullLabel.text = "Hosted header\n(Lottie could go here)"

    let hosted = FKHostedRefreshContentView(hostedView: hostedPullLabel)
    var cfg = FKRefreshConfiguration()
    cfg.tintColor = .label

    tableView.fk_addPullToRefresh(configuration: cfg, contentView: hosted) { [weak self] in
      FKRefreshExampleCommon.simulateRequest(delay: 1.0) {
        self?.items = (1...14).map { "Hosted \($0)" }
        self?.tableView.reloadData()
        self?.tableView.fk_pullToRefresh?.endRefreshing()
        self?.tableView.fk_loadMore?.resetToIdle()
      }
    }

    tableView.fk_pullToRefresh?.onStateChanged = { [weak self] _, state in
      self?.hostedPullLabel.text = "Pull state:\n\(FKRefreshExampleCommon.stateDescription(state))"
    }

    tableView.fk_addLoadMore { [weak self] in
      FKRefreshExampleCommon.simulateRequest(delay: 0.8) {
        guard let self else { return }
        let n = self.items.count
        self.items.append(contentsOf: (n + 1...(n + 5)).map { "Hosted \($0)" })
        self.tableView.reloadData()
        self.tableView.fk_loadMore?.endRefreshing()
      }
    }
  }
}

extension FKRefreshHostedDemoViewController: UITableViewDataSource {
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
