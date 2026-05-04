import UIKit

/// Hub: **Tab bar anchor** demo vs **custom UIView anchor** demo (separate screens).
final class FKAnchoredDropdownExampleViewController: UIViewController {
  private enum Demo: Int, CaseIterable {
    case tabBarAnchor
    case customViewAnchor

    var title: String {
      switch self {
      case .tabBarAnchor:
        return "Tab bar anchor"
      case .customViewAnchor:
        return "Custom view anchor"
      }
    }

    var subtitle: String {
      switch self {
      case .tabBarAnchor:
        return "Default: panel attaches to FKTabBar. Tabs, switch animations, optional Events hooks."
      case .customViewAnchor:
        return "Custom UIView anchor + tap; hidden tab bar (programmatic expand/collapse)."
      }
    }

    func makeViewController() -> UIViewController {
      switch self {
      case .tabBarAnchor:
        return AnchoredDropdownExampleTabBarAnchorViewController()
      case .customViewAnchor:
        return AnchoredDropdownExampleCustomAnchorViewController()
      }
    }
  }

  private let tableView = UITableView(frame: .zero, style: .insetGrouped)

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Anchored dropdown"
    view.backgroundColor = .systemGroupedBackground

    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.dataSource = self
    tableView.delegate = self
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }
}

extension FKAnchoredDropdownExampleViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    Demo.allCases.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let demo = Demo.allCases[indexPath.row]
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    var config = UIListContentConfiguration.subtitleCell()
    config.text = demo.title
    config.secondaryText = demo.subtitle
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }
}

extension FKAnchoredDropdownExampleViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let vc = Demo.allCases[indexPath.row].makeViewController()
    navigationController?.pushViewController(vc, animated: true)
  }
}
