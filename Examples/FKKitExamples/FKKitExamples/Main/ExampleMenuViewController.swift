//
//  ExampleMenuViewController.swift
//  FKKitExamples
//

import UIKit
import FKCompositeKit

/// Grouped example index: **FKUIKit** first, then **FKCompositeKit**; rows sorted alphabetically by title within each section.
final class ExampleMenuViewController: UITableViewController {

  // MARK: Types

  private struct MenuItem {
    let title: String
    let subtitle: String
    let make: () -> UIViewController
  }

  private enum KitSection: Int, CaseIterable {
    case fkUIKit
    case fkCompositeKit

    var headerTitle: String {
      switch self {
      case .fkUIKit: return "FKUIKit"
      case .fkCompositeKit: return "FKCompositeKit"
      }
    }
  }

  // MARK: Data

  /// FKUIKit demos, A→Z by `title`.
  private static let fkUIKitItems: [MenuItem] = [
    MenuItem(
      title: "FKBar",
      subtitle: "Horizontal item bar with selection callbacks",
      make: { FKBarExampleViewController() }
    ),
    MenuItem(
      title: "FKBarPresentation",
      subtitle: "Bar + anchored panel composite",
      make: { FKBarPresentationExampleViewController() }
    ),
    MenuItem(
      title: "FKBadge",
      subtitle: "Dot, numeric & text badges, anchors, animations, TabBarItem",
      make: { FKBadgeExamplesHubViewController() }
    ),
    MenuItem(
      title: "FKButton",
      subtitle: "Split demos: basics, layout, interaction, appearance, loading",
      make: { FKButtonExamplesHubViewController() }
    ),
    MenuItem(
      title: "FKEmptyState",
      subtitle: "Hub: scenarios, phases, sandbox, retry→fail",
      make: { FKEmptyStateExamplesHubViewController() }
    ),
    MenuItem(
      title: "FKPresentation",
      subtitle: "Anchored panel with mask",
      make: { FKPresentationExampleViewController() }
    ),
    MenuItem(
      title: "FKRefresh",
      subtitle: "Hub: default, GIF, hosted, delegate, settings, collection, scroll view, …",
      make: { FKRefreshExamplesHubViewController() }
    ),
    MenuItem(
      title: "FKSkeleton",
      subtitle: "Overlay, presets, standalone blocks, table/collection skeleton cells, unified shimmer",
      make: { FKSkeletonExampleViewController() }
    ),
  ].sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }

  /// FKCompositeKit demos, A→Z by `title`.
  private static let fkCompositeKitItems: [MenuItem] = [
    MenuItem(
      title: "FKFilter",
      subtitle: "Composite dropdown filters (top bar + panels)",
      make: { FKFilterExampleViewController() }
    ),
    MenuItem(
      title: "FKListKit",
      subtitle: "Plugin list: refresh, paging, skeleton, empty/error",
      make: { FKListKitTableExampleViewController() }
    ),
  ].sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }

  private func items(for section: Int) -> [MenuItem] {
    guard let kit = KitSection(rawValue: section) else { return [] }
    switch kit {
    case .fkUIKit: return Self.fkUIKitItems
    case .fkCompositeKit: return Self.fkCompositeKitItems
    }
  }

  // MARK: Lifecycle

  convenience init() {
    self.init(style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKKit Examples"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
  }

  // MARK: UITableViewDataSource

  override func numberOfSections(in tableView: UITableView) -> Int {
    KitSection.allCases.count
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    items(for: section).count
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    KitSection(rawValue: section)?.headerTitle
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let item = items(for: indexPath.section)[indexPath.row]
    var config = cell.defaultContentConfiguration()
    config.text = item.title
    config.secondaryText = item.subtitle
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  // MARK: UITableViewDelegate

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let vc = items(for: indexPath.section)[indexPath.row].make()
    navigationController?.pushViewController(vc, animated: true)
  }
}
