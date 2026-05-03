import FKUIKit
import UIKit

/// Lists ExpandableText sample screens; each row pushes one example view controller.
final class FKExpandableTextExamplesHubViewController: UITableViewController {
  private struct Row {
    let title: String
    let subtitle: String
    let make: () -> UIViewController
  }

  private let rows: [Row] = [
    Row(title: "UILabel — basic", subtitle: "Default configuration", make: { FKExpandableTextExampleLabelBasicViewController() }),
    Row(title: "UITextView — rich text + links", subtitle: "`FKExpandableText.attach`", make: { FKExpandableTextExampleTextViewRichViewController() }),
    Row(title: "Custom line limit", subtitle: "`collapseRule: .lines(2)`", make: { FKExpandableTextExampleLineLimitViewController() }),
    Row(title: "Custom action styling", subtitle: "Token, fonts, `trailingBottom`", make: { FKExpandableTextExampleActionStyleViewController() }),
    Row(title: "One-way expand", subtitle: "`oneWayExpand`", make: { FKExpandableTextExampleOneWayExpandViewController() }),
    Row(title: "Tap full text area", subtitle: "`interactionMode: .fullTextArea`", make: { FKExpandableTextExampleFullTextAreaViewController() }),
    Row(title: "Dynamic text", subtitle: "Runtime `fk_setExpandableText`", make: { FKExpandableTextExampleDynamicTextViewController() }),
    Row(title: "UIKit composition", subtitle: "Label + text view", make: { FKExpandableTextExampleUIKitCompositionViewController() }),
    Row(title: "SwiftUI bridge", subtitle: "`FKExpandableTextView`", make: { FKExpandableTextExampleSwiftUIViewController() }),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "ExpandableText"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
  }

  override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
    rows.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let row = rows[indexPath.row]
    var config = cell.defaultContentConfiguration()
    config.text = row.title
    config.secondaryText = row.subtitle
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    navigationController?.pushViewController(rows[indexPath.row].make(), animated: true)
  }
}
