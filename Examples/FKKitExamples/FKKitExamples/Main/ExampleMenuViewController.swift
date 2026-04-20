//
//  ExampleMenuViewController.swift
//  FKKitExamples
//

import UIKit
import FKCompositeKit

fileprivate struct ExampleMenuItem {
  let title: String
  let subtitle: String
  let make: () -> UIViewController
}

fileprivate struct KitEntry {
  let title: String
  let subtitle: String
  let items: [ExampleMenuItem]
}

/// Two-level example index:
/// - Level 1: three target entries (`FKUIKit`, `FKCoreKit`, `FKCompositeKit`)
/// - Level 2: examples under the selected target
final class ExampleMenuViewController: UITableViewController {

  private static let kitEntries: [KitEntry] = [
    KitEntry(
      title: "FKUIKit",
      subtitle: "Foundational UI components and presentation infrastructure",
      items: [
        ExampleMenuItem(
          title: "FKBar",
          subtitle: "Horizontal item bar with selection callbacks",
          make: { FKBarExampleViewController() }
        ),
        ExampleMenuItem(
          title: "FKBarPresentation",
          subtitle: "Bar + anchored panel composite",
          make: { FKBarPresentationExampleViewController() }
        ),
        ExampleMenuItem(
          title: "FKBadge",
          subtitle: "Dot, numeric & text badges, anchors, animations, TabBarItem",
          make: { FKBadgeExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "FKButton",
          subtitle: "Split demos: basics, layout, interaction, appearance, loading",
          make: { FKButtonExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "FKEmptyState",
          subtitle: "Hub: scenarios, phases, sandbox, retry→fail",
          make: { FKEmptyStateExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "FKPresentation",
          subtitle: "Anchored panel with mask",
          make: { FKPresentationExampleViewController() }
        ),
        ExampleMenuItem(
          title: "FKRefresh",
          subtitle: "Hub: default, GIF, hosted, delegate, settings, collection, scroll view, …",
          make: { FKRefreshExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "FKSkeleton",
          subtitle: "Overlay, presets, standalone blocks, table/collection skeleton cells, unified shimmer",
          make: { FKSkeletonExampleViewController() }
        ),
      ].sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    ),
    KitEntry(
      title: "FKCoreKit",
      subtitle: "Core non-UI capabilities (networking, logging, utilities, etc.)",
      items: [
        ExampleMenuItem(
          title: "FKAsync",
          subtitle: "Main/background dispatch, delay cancel, debounce, throttle, groups, executors",
          make: { FKAsyncExampleViewController() }
        ),
        ExampleMenuItem(
          title: "FKLogger",
          subtitle: "5-level logs, config, file persistence, crash capture, export/clear",
          make: { FKLoggerExampleViewController() }
        ),
        ExampleMenuItem(
          title: "FKNetwork",
          subtitle: "GET/POST, async/await, upload/download, cache, cancel, parsing",
          make: { FKNetworkExampleViewController() }
        ),
        ExampleMenuItem(
          title: "FKPermissions",
          subtitle: "Unified permission status/query/request, batch, denied handling, settings jump",
          make: { FKPermissionsExampleViewController() }
        ),
        ExampleMenuItem(
          title: "FKStorage",
          subtitle: "UserDefaults, Keychain, file, memory cache, TTL, purge, async",
          make: { FKStorageExampleViewController() }
        ),
      ]
    ),
    KitEntry(
      title: "FKCompositeKit",
      subtitle: "Composed modules built on FKUIKit and FKCoreKit",
      items: [
        ExampleMenuItem(
          title: "FKFilter",
          subtitle: "Composite dropdown filters (top bar + panels)",
          make: { FKFilterExampleViewController() }
        ),
        ExampleMenuItem(
          title: "FKListKit",
          subtitle: "Plugin list: refresh, paging, skeleton, empty/error",
          make: { FKListKitTableExampleViewController() }
        ),
      ].sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    ),
  ].sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }

  convenience init() {
    self.init(style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKKit Examples"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
  }

  override func numberOfSections(in tableView: UITableView) -> Int { 1 }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    Self.kitEntries.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let entry = Self.kitEntries[indexPath.row]
    var config = cell.defaultContentConfiguration()
    config.text = entry.title
    config.secondaryText = entry.subtitle
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let entry = Self.kitEntries[indexPath.row]
    let vc = KitExamplesViewController(title: entry.title, items: entry.items)
    navigationController?.pushViewController(vc, animated: true)
  }
}

private final class KitExamplesViewController: UITableViewController {
  private let screenTitle: String
  private let items: [ExampleMenuItem]

  init(title: String, items: [ExampleMenuItem]) {
    self.screenTitle = title
    self.items = items.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    super.init(style: .insetGrouped)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = screenTitle
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
  }

  override func numberOfSections(in tableView: UITableView) -> Int { 1 }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    items.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let item = items[indexPath.row]
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
    let vc = items[indexPath.row].make()
    navigationController?.pushViewController(vc, animated: true)
  }
}
