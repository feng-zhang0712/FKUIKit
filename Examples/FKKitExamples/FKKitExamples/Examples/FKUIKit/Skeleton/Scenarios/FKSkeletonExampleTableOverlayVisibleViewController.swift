import UIKit
import FKUIKit

/// Overlay skeletons on already laid-out cells via visible-cell helpers.
final class FKSkeletonExampleTableOverlayVisibleViewController: UIViewController, UITableViewDataSource {

  private let tableView = UITableView(frame: .zero, style: .insetGrouped)
  private var isLoading = true

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Table · overlay visible"
    view.backgroundColor = .systemBackground

    tableView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.dataSource = self

    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Toggle loading",
      style: .done,
      target: self,
      action: #selector(toggle)
    )

    reloadAndApplySkeletonState()
  }

  @objc private func toggle() {
    if isLoading {
      tableView.fk_hideSkeletonOnVisibleCells(animated: true) { [weak self] in
        self?.isLoading = false
        self?.reloadAndApplySkeletonState()
      }
    } else {
      isLoading = true
      reloadAndApplySkeletonState()
      tableView.layoutIfNeeded()
      tableView.fk_showSkeletonOnVisibleCells(
        animated: true,
        respectsSafeArea: false,
        blocksInteraction: true
      )
    }
  }

  private func reloadAndApplySkeletonState() {
    tableView.reloadData()
    if isLoading {
      tableView.layoutIfNeeded()
      tableView.fk_showSkeletonOnVisibleCells(
        animated: false,
        respectsSafeArea: false,
        blocksInteraction: true
      )
    }
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    24
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    cell.textLabel?.text = "Row \(indexPath.row + 1) · UITableViewCell content"
    return cell
  }
}
