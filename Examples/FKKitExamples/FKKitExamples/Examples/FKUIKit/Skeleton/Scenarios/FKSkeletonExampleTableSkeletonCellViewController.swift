import UIKit
import FKUIKit

/// Dedicated `FKSkeletonTableViewCell` rows while loading.
final class FKSkeletonExampleTableSkeletonCellViewController: UIViewController, UITableViewDataSource {

  private enum Reuse {
    static let skeleton = "skeleton.table"
    static let plain = "plain"
  }

  private let tableView = UITableView(frame: .zero, style: .insetGrouped)
  private var isLoading = true

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Table · skeleton cell"
    view.backgroundColor = .systemBackground

    tableView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    tableView.register(FKSkeletonTableViewCell.self, forCellReuseIdentifier: Reuse.skeleton)
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: Reuse.plain)
    tableView.dataSource = self
    tableView.rowHeight = 96

    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Toggle loaded",
      style: .done,
      target: self,
      action: #selector(toggleLoaded)
    )
  }

  @objc private func toggleLoaded() {
    isLoading.toggle()
    tableView.reloadData()
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    isLoading ? 8 : 20
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if isLoading {
      let cell = tableView.dequeueReusableCell(withIdentifier: Reuse.skeleton, for: indexPath) as! FKSkeletonTableViewCell
      if cell.skeletonContainer.skeletonSubviews.isEmpty {
        Self.configureListSkeleton(cell)
      }
      cell.skeletonContainer.showSkeleton(animated: false)
      return cell
    }
    let cell = tableView.dequeueReusableCell(withIdentifier: Reuse.plain, for: indexPath)
    cell.textLabel?.text = "Loaded row \(indexPath.row + 1)"
    cell.accessoryType = .none
    return cell
  }

  private static func configureListSkeleton(_ cell: FKSkeletonTableViewCell) {
    cell.resetSkeletonContent()
    let c = cell.skeletonContainer
    let avatar = FKSkeletonView()
    avatar.layer.cornerRadius = 22
    let line1 = FKSkeletonView()
    line1.layer.cornerRadius = 4
    let line2 = FKSkeletonView()
    line2.layer.cornerRadius = 4
    [avatar, line1, line2].forEach { c.addSkeletonSubview($0) }
    NSLayoutConstraint.activate([
      avatar.leadingAnchor.constraint(equalTo: c.leadingAnchor),
      avatar.centerYAnchor.constraint(equalTo: c.centerYAnchor),
      avatar.widthAnchor.constraint(equalToConstant: 44),
      avatar.heightAnchor.constraint(equalToConstant: 44),

      line1.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 12),
      line1.trailingAnchor.constraint(equalTo: c.trailingAnchor),
      line1.heightAnchor.constraint(equalToConstant: 12),
      line1.topAnchor.constraint(equalTo: c.topAnchor, constant: 10),

      line2.leadingAnchor.constraint(equalTo: line1.leadingAnchor),
      line2.widthAnchor.constraint(equalTo: c.widthAnchor, multiplier: 0.45),
      line2.heightAnchor.constraint(equalToConstant: 10),
      line2.bottomAnchor.constraint(equalTo: c.bottomAnchor, constant: -10),
    ])
  }
}
