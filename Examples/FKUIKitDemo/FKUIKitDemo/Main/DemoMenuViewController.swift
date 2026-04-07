//
//  DemoMenuViewController.swift
//  FKUIKitDemo
//

import UIKit

/// 演示入口列表：按模块跳转到 `Demos/` 下对应页面。
final class DemoMenuViewController: UITableViewController {

  private struct MenuItem {
    let title: String
    let subtitle: String
    let make: () -> UIViewController
  }

  private let menuItems: [MenuItem] = [
    MenuItem(
      title: "FKButton",
      subtitle: "标题、图片、副标题与多种外观",
      make: { FKButtonDemoViewController() }
    ),
    MenuItem(
      title: "FKBar",
      subtitle: "横向条目条与选中 / 回调",
      make: { FKBarDemoViewController() }
    ),
    MenuItem(
      title: "FKPresentation",
      subtitle: "锚点浮层与遮罩",
      make: { FKPresentationDemoViewController() }
    ),
    MenuItem(
      title: "FKBarPresentation",
      subtitle: "Bar + 浮层组合",
      make: { FKBarPresentationDemoViewController() }
    ),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKUIKit Demo"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    menuItems.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let item = menuItems[indexPath.row]
    var config = cell.defaultContentConfiguration()
    config.text = item.title
    config.secondaryText = item.subtitle
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let vc = menuItems[indexPath.row].make()
    navigationController?.pushViewController(vc, animated: true)
  }
}
