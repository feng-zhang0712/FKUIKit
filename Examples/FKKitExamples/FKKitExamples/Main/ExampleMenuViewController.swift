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
          title: "Badge",
          subtitle: "Dot, numeric & text badges, anchors, animations, TabBarItem",
          make: { FKBadgeExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "BlurView",
          subtitle: "High-performance blur view demos (UIKit / SwiftUI / IB)",
          make: { FKBlurViewExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "Button",
          subtitle: "Split demos: basics, layout, interaction, appearance, loading",
          make: { FKButtonExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "CornerShadow",
          subtitle: "Any-corner radius + high-performance shadow (path based)",
          make: { FKCornerShadowExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "Carousel",
          subtitle: "Hub: infinite loop, auto-play, custom content, callbacks, and list adaptation",
          make: { FKCarouselExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "Divider",
          subtitle: "Horizontal/vertical, dashed/gradient, auto pin, IB and SwiftUI divider demos",
          make: { FKDividerExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "EmptyState",
          subtitle: "Hub: scenarios, phases, sandbox, retry→fail",
          make: { FKEmptyStateExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "ExpandableText",
          subtitle: "Hub: basic, table and collection expandable text demos",
          make: { FKExpandableTextExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "LoadingAnimator",
          subtitle: "Hub: fullscreen/embedded loading, progress ring, style switching, list reuse",
          make: { FKLoadingAnimatorExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "MultiPicker",
          subtitle: "Multi-level cascading picker with built-in region and custom data linkage",
          make: { FKMultiPickerExampleViewController() }
        ),
        ExampleMenuItem(
          title: "Presentation",
          subtitle: "Custom presentation controller examples (sheet/center/anchor, animation, backdrop, keyboard, rotation)",
          make: { PresentationExamplesIndexViewController() }
        ),
        ExampleMenuItem(
          title: "Refresh",
          subtitle: "Hub: default, GIF, hosted, delegate, settings, collection, scroll view, …",
          make: { FKRefreshExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "Skeleton",
          subtitle: "Overlay, presets, standalone blocks, table/collection skeleton cells, unified shimmer",
          make: { FKSkeletonExampleViewController() }
        ),
        ExampleMenuItem(
          title: "StarRating",
          subtitle: "5-star, half-star, precise decimal, image/color styles, callbacks, and table reuse demos",
          make: { FKStarRatingExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "StickyView",
          subtitle: "Hub: multi-target sticky, table/collection headers, callbacks, offsets, and runtime control",
          make: { FKStickyExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "SwipeAction",
          subtitle: "Native left/right multi-button swipe actions for table and collection lists",
          make: { FKSwipeActionExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "TabBar",
          subtitle: "Segmented tab bar with indicators, dynamic data, width policies, and a11y/i18n demos",
          make: { FKTabBarExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "TextField",
          subtitle: "Formatted input, validation, style customization, callbacks, and global defaults",
          make: { FKTextFieldExampleViewController() }
        ),
        ExampleMenuItem(
          title: "Toast",
          subtitle: "Global Toast/HUD/Snackbar hints with queueing, styles, positions, custom view, and SwiftUI support",
          make: { FKToastExamplesHubViewController() }
        ),
      ].sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    ),
    KitEntry(
      title: "FKCoreKit",
      subtitle: "Core non-UI capabilities (networking, logging, utilities, etc.)",
      items: [
        ExampleMenuItem(
          title: "Async",
          subtitle: "Main/background dispatch, delay cancel, debounce, throttle, groups, executors",
          make: { FKAsyncExampleViewController() }
        ),
        ExampleMenuItem(
          title: "BusinessKit",
          subtitle: "Version, tracking, i18n, lifecycle, deeplink, device info, business utils",
          make: { FKBusinessKitExampleViewController() }
        ),
        ExampleMenuItem(
          title: "FileManager",
          subtitle: "Sandbox/file ops, read/write, resumable download, upload, cache and ZIP APIs",
          make: { FKFileManagerExampleViewController() }
        ),
        ExampleMenuItem(
          title: "Logger",
          subtitle: "5-level logs, config, file persistence, crash capture, export/clear",
          make: { FKLoggerExampleViewController() }
        ),
        ExampleMenuItem(
          title: "Network",
          subtitle: "GET/POST, async/await, upload/download, cache, cancel, parsing",
          make: { FKNetworkExampleViewController() }
        ),
        ExampleMenuItem(
          title: "Permissions",
          subtitle: "Unified permission status/query/request, batch, denied handling, settings jump",
          make: { FKPermissionsExampleViewController() }
        ),
        ExampleMenuItem(
          title: "Security",
          subtitle: "Hash, AES, RSA, Base64/HEX/URL, HMAC, random, masking, wipe, anti-debug",
          make: { FKSecurityExampleViewController() }
        ),
        ExampleMenuItem(
          title: "Storage",
          subtitle: "UserDefaults, Keychain, file, memory cache, TTL, purge, async",
          make: { FKStorageExampleViewController() }
        ),
        ExampleMenuItem(
          title: "Utils",
          subtitle: "Date, regex, number, string, device, UI, collection, image and common helpers",
          make: { FKUtilsExampleViewController() }
        ),
      ]
    ),
    KitEntry(
      title: "FKCompositeKit",
      subtitle: "Composed modules built on FKUIKit and FKCoreKit",
      items: [
        ExampleMenuItem(
          title: "Base",
          subtitle: "Controller foundation demos: lifecycle, navigation and tab bar infrastructure",
          make: { FKBaseExamplesHubViewController() }
        ),
        ExampleMenuItem(
          title: "ListKit",
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
