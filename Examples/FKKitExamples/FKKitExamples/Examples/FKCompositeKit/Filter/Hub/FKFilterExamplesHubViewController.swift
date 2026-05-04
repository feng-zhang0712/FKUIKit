import UIKit

/// Table entry list for Filter demos (three peers).
final class FKFilterExamplesHubViewController: UITableViewController {

  private enum Row: Int, CaseIterable {
    case full
    case tableHost
    case customHost

    var title: String {
      switch self {
      case .full:
        return "Full demo (6 tabs)"
      case .tableHost:
        return "Equal tabs · business filters"
      case .customHost:
        return "Equal tabs · knowledge & sort"
      }
    }

    var subtitle: String {
      switch self {
      case .full:
        return "Scrollable strip, constrained tab widths"
      case .tableHost:
        return "Three equal columns; empty body"
      case .customHost:
        return "Three equal columns; empty body"
      }
    }

    func makeViewController() -> UIViewController {
      switch self {
      case .full:
        return FKFilterExampleViewController()
      case .tableHost:
        return FKFilterTableHostExampleViewController()
      case .customHost:
        return FKFilterCustomViewHostExampleViewController()
      }
    }
  }

  convenience init() {
    self.init(style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Filter"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
    tableView.rowHeight = 76
  }

  override func numberOfSections(in tableView: UITableView) -> Int { 1 }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    Row.allCases.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let row = Row.allCases[indexPath.row]
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    var config = UIListContentConfiguration.subtitleCell()
    config.text = row.title
    config.secondaryText = row.subtitle
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let vc = Row.allCases[indexPath.row].makeViewController()
    navigationController?.pushViewController(vc, animated: true)
  }
}
