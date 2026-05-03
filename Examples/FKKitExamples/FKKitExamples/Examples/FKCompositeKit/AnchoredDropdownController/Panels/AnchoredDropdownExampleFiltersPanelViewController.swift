import UIKit

final class AnchoredDropdownExampleFiltersPanelViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  private let tableView = UITableView(frame: .zero, style: .plain)
  private var rows: [String] = (1...18).map { "Filter option \($0)" }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.dataSource = self
    tableView.delegate = self
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    // Encourage intrinsic height measurement while still allowing internal scrolling:
    // FKPresentationController will clamp by available space and content will scroll.
    preferredContentSize = CGSize(width: 0, height: 420)
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows.count }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
    cell.textLabel?.text = rows[indexPath.row]
    cell.detailTextLabel?.text = "Tap to simulate content height change"
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    // Simulate a dynamic height change (e.g. async load expanding a section).
    if rows.count < 26 {
      rows.append(contentsOf: (rows.count + 1...rows.count + 6).map { "Filter option \($0)" })
      tableView.reloadData()
      preferredContentSize.height += 120
    } else {
      rows = (1...18).map { "Filter option \($0)" }
      tableView.reloadData()
      preferredContentSize.height = 420
    }
  }
}
