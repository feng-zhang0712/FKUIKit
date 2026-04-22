import FKUIKit
import SwiftUI
import UIKit

// MARK: - UITableView Single Section

final class FKStickyTableSingleSectionViewController: UITableViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "UITableView Single Section"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.sectionHeaderHeight = 52
    // Enable section sticky headers with one line.
    tableView.fk_enableSectionStickyHeaders()
  }

  override func numberOfSections(in tableView: UITableView) -> Int { 1 }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 40 }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    var config = cell.defaultContentConfiguration()
    config.text = "Row \(indexPath.row + 1)"
    config.secondaryText = "Basic single-section sticky demo"
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    return cell
  }

  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    FKStickyHeaderFactory.makeLabelHeader(text: "Single Section Header", style: .systemBlue)
  }
}

// MARK: - UITableView Multi Section (Contacts Style)

class FKStickyTableMultiSectionViewController: UITableViewController {
  private let sections = (0..<12).map { "Section \($0 + 1)" }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "UITableView Multi Section"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.sectionHeaderHeight = 46
    // Use this scenario to verify section push-off behavior.
    tableView.fk_enableSectionStickyHeaders()
  }

  override func numberOfSections(in tableView: UITableView) -> Int { sections.count }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 8 }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    var config = cell.defaultContentConfiguration()
    config.text = "\(sections[indexPath.section]) - Contact \(indexPath.row + 1)"
    config.secondaryText = "Contacts-style grouped list"
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    return cell
  }

  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    FKStickyHeaderFactory.makeLabelHeader(text: sections[section], style: .systemIndigo)
  }
}

// MARK: - UICollectionView Basic Multi Section

class FKStickyCollectionBasicViewController: UIViewController, UICollectionViewDataSource {
  private let sections = Array(0..<10)
  private let collectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.minimumLineSpacing = 10
    layout.headerReferenceSize = CGSize(width: 1, height: 48)
    return UICollectionView(frame: .zero, collectionViewLayout: layout)
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Collection Basic Sticky"
    view.backgroundColor = .systemBackground
    collectionView.backgroundColor = .systemGroupedBackground
    collectionView.dataSource = self
    collectionView.contentInset = UIEdgeInsets(top: 8, left: 12, bottom: 16, right: 12)
    collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
    collectionView.register(FKStickyCollectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "header")
    view.addSubview(collectionView)
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      collectionView.topAnchor.constraint(equalTo: view.topAnchor),
      collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    // CollectionView also supports one-line sticky setup.
    collectionView.fk_enableSectionStickyHeaders()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
    let width = collectionView.bounds.width - collectionView.contentInset.left - collectionView.contentInset.right
    layout.itemSize = CGSize(width: width, height: 56)
    collectionView.fk_reloadStickyTargets()
  }

  func numberOfSections(in collectionView: UICollectionView) -> Int { sections.count }
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { 5 }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
    cell.layer.cornerRadius = 12
    cell.backgroundColor = .secondarySystemGroupedBackground
    let tag = 1001
    let label: UILabel
    if let cached = cell.contentView.viewWithTag(tag) as? UILabel {
      label = cached
    } else {
      label = UILabel()
      label.tag = tag
      label.font = .systemFont(ofSize: 14, weight: .medium)
      label.translatesAutoresizingMaskIntoConstraints = false
      cell.contentView.addSubview(label)
      NSLayoutConstraint.activate([
        label.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 12),
        label.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
      ])
    }
    label.text = "Section \(indexPath.section) - Item \(indexPath.item)"
    return cell
  }

  func collectionView(
    _ collectionView: UICollectionView,
    viewForSupplementaryElementOfKind kind: String,
    at indexPath: IndexPath
  ) -> UICollectionReusableView {
    let header = collectionView.dequeueReusableSupplementaryView(
      ofKind: kind,
      withReuseIdentifier: "header",
      for: indexPath
    ) as! FKStickyCollectionHeaderView
    header.configure(text: "Section \(indexPath.section + 1)")
    return header
  }
}

// MARK: - UICollectionView Waterfall Sticky

final class FKStickyWaterfallCollectionViewController: UIViewController, UICollectionViewDataSource {
  private let layout = FKStickyWaterfallLayout()
  private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
  private let sections = Array(0..<7)

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Collection Waterfall Sticky"
    view.backgroundColor = .systemBackground
    collectionView.backgroundColor = .systemGroupedBackground
    collectionView.contentInset = UIEdgeInsets(top: 8, left: 12, bottom: 18, right: 12)
    collectionView.dataSource = self
    collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
    collectionView.register(FKStickyCollectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "header")
    view.addSubview(collectionView)
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      collectionView.topAnchor.constraint(equalTo: view.topAnchor),
      collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    // Waterfall layout can directly reuse section sticky behavior.
    collectionView.fk_enableSectionStickyHeaders()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    layout.contentInsets = collectionView.contentInset
    layout.availableWidth = collectionView.bounds.width
    collectionView.collectionViewLayout.invalidateLayout()
    collectionView.fk_reloadStickyTargets()
  }

  func numberOfSections(in collectionView: UICollectionView) -> Int { sections.count }
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { 14 }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
    cell.layer.cornerRadius = 10
    cell.backgroundColor = .secondarySystemBackground
    return cell
  }

  func collectionView(
    _ collectionView: UICollectionView,
    viewForSupplementaryElementOfKind kind: String,
    at indexPath: IndexPath
  ) -> UICollectionReusableView {
    let header = collectionView.dequeueReusableSupplementaryView(
      ofKind: kind,
      withReuseIdentifier: "header",
      for: indexPath
    ) as! FKStickyCollectionHeaderView
    header.configure(text: "Waterfall Section \(indexPath.section + 1)")
    return header
  }
}

// MARK: - Animation / State / Offset / Toggle

final class FKStickyAnimationDemoViewController: UITableViewController {
  enum Mode {
    case customOffset
    case alpha
    case backgroundColor
    case scale
    case stateCallback
    case toggleSticky
  }

  private let mode: Mode
  private let sections = Array(0..<10)
  private let statusLabel = UILabel()
  private var stickyEnabled = true

  init(mode: Mode) {
    self.mode = mode
    super.init(style: .insetGrouped)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = makeTitle()
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.sectionHeaderHeight = 48
    configureHeaderStatusView()
    configureSticky()
    if mode == .toggleSticky { configureToggleButton() }
  }

  override func numberOfSections(in tableView: UITableView) -> Int { sections.count }
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 6 }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    var config = cell.defaultContentConfiguration()
    config.text = "Section \(indexPath.section) - Row \(indexPath.row)"
    config.secondaryText = "Minimal sticky integration logic, copy-ready"
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    return cell
  }

  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    FKStickyHeaderFactory.makeLabelHeader(text: "Header \(section + 1)", style: .systemOrange)
  }

  private func configureSticky() {
    var configuration = FKStickyConfiguration.default
    if mode == .customOffset {
      // Offset avoids overlap with navigation bars or top overlays.
      configuration.referenceOffsetY = 44
    }

    tableView.fk_enableSectionStickyHeaders(configuration: configuration) { [weak self] section, header in
      guard let self else { return nil }
      return FKStickyTarget(
        id: "demo_\(section)",
        viewProvider: { [weak header] in header },
        threshold: self.tableView.rectForHeader(inSection: section).minY,
        onTransition: { [weak self] progress, view in
          self?.applyAnimation(progress: progress, view: view)
        },
        onStateChanged: { [weak self] state in
          self?.applyState(state)
        }
      )
    }
  }

  private func applyAnimation(progress: CGFloat, view: UIView) {
    switch mode {
    case .alpha:
      // Alpha transitions smoothly from 0.6 to 1.0.
      view.alpha = 0.6 + (0.4 * progress)
    case .backgroundColor:
      // Background color transitions with sticky progress.
      view.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.12 + 0.25 * progress)
    case .scale:
      // Scale animation adds depth during sticky transition.
      let scale = 0.96 + (0.04 * progress)
      view.subviews.first?.transform = CGAffineTransform(scaleX: scale, y: scale)
    default:
      break
    }
  }

  private func applyState(_ state: FKStickyState) {
    guard mode == .stateCallback || mode == .toggleSticky else { return }
    statusLabel.text = "State callback: \(state)"
  }

  private func configureHeaderStatusView() {
    statusLabel.font = .systemFont(ofSize: 13, weight: .medium)
    statusLabel.numberOfLines = 0
    statusLabel.textColor = .secondaryLabel
    statusLabel.textAlignment = .left
    statusLabel.text = "State callback output appears here"
    statusLabel.frame = CGRect(x: 0, y: 0, width: 10, height: 56)
    tableView.tableHeaderView = statusLabel
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    guard let header = tableView.tableHeaderView else { return }
    let size = header.systemLayoutSizeFitting(CGSize(width: tableView.bounds.width - 24, height: 0))
    if abs(header.frame.height - max(56, size.height + 12)) > 0.5 {
      header.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: max(56, size.height + 12))
      tableView.tableHeaderView = header
    }
  }

  private func configureToggleButton() {
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Disable Sticky",
      style: .plain,
      target: self,
      action: #selector(toggleSticky)
    )
  }

  @objc
  private func toggleSticky() {
    stickyEnabled.toggle()
    tableView.fk_stickyEngine.setEnabled(stickyEnabled)
    navigationItem.rightBarButtonItem?.title = stickyEnabled ? "Disable Sticky" : "Enable Sticky"
    statusLabel.text = stickyEnabled ? "Sticky enabled" : "Sticky disabled"
  }

  private func makeTitle() -> String {
    switch mode {
    case .customOffset: return "Custom Offset"
    case .alpha: return "Alpha Animation"
    case .backgroundColor: return "Background Color Animation"
    case .scale: return "Scale Animation"
    case .stateCallback: return "State Callback"
    case .toggleSticky: return "Dynamic Sticky Toggle"
    }
  }
}

// MARK: - Global Configuration Demo

final class FKStickyGlobalConfigDemoViewController: FKStickyTableMultiSectionViewController {
  override func viewDidLoad() {
    // Set global defaults first, then open the list demo.
    FKStickyManager.shared.updateTemplateConfiguration { config in
      config.referenceOffsetY = 10
      config.animationCurve = .easeInOut
      config.transitionDistance = 24
    }
    super.viewDidLoad()
    title = "Global Configuration"
  }
}

// MARK: - Dark Mode Demo

final class FKStickyDarkModeDemoViewController: FKStickyTableMultiSectionViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Dark Mode Adaptation"
    // System dynamic colors adapt to light/dark mode automatically.
    overrideUserInterfaceStyle = .unspecified
  }
}

// MARK: - Rotation Demo

final class FKStickyRotationDemoViewController: FKStickyCollectionBasicViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Rotation Adaptation"
  }
}

// MARK: - Performance Demo (FPS)

final class FKStickyPerformanceDemoViewController: FKStickyTableMultiSectionViewController {
  private let fpsLabel = UILabel()
  private var fpsLink: CADisplayLink?
  private var tickCount = 0
  private var lastTimestamp: CFTimeInterval = 0

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Scrolling Performance Test"
    fpsLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
    fpsLabel.textColor = .secondaryLabel
    fpsLabel.text = "FPS: --"
    navigationItem.rightBarButtonItem = UIBarButtonItem(customView: fpsLabel)
    startFPSMonitor()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    stopFPSMonitor()
  }

  private func startFPSMonitor() {
    let link = CADisplayLink(target: self, selector: #selector(onFrame(_:)))
    link.add(to: .main, forMode: .common)
    fpsLink = link
  }

  private func stopFPSMonitor() {
    fpsLink?.invalidate()
    fpsLink = nil
  }

  @objc
  private func onFrame(_ link: CADisplayLink) {
    if lastTimestamp == 0 { lastTimestamp = link.timestamp; return }
    tickCount += 1
    let delta = link.timestamp - lastTimestamp
    guard delta >= 1 else { return }
    let fps = Int(round(Double(tickCount) / delta))
    fpsLabel.text = "FPS: \(fps)"
    tickCount = 0
    lastTimestamp = link.timestamp
  }
}

// MARK: - SwiftUI Demo

final class FKStickySwiftUIHostViewController: UIHostingController<FKStickySwiftUIDemoView> {
  init() {
    super.init(rootView: FKStickySwiftUIDemoView())
    title = "SwiftUI Sticky List"
  }

  @available(*, unavailable)
  @objc required dynamic init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

struct FKStickySwiftUIDemoView: View {
  var body: some View {
    FKStickyUIKitTableContainer()
      .navigationBarTitleDisplayMode(.inline)
  }
}

private struct FKStickyUIKitTableContainer: UIViewControllerRepresentable {
  func makeUIViewController(context: Context) -> UIViewController {
    // Host a UIKit list inside SwiftUI to reuse the same sticky logic.
    FKStickyTableMultiSectionViewController()
  }

  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

// MARK: - Common UI

private enum FKStickyHeaderFactory {
  static func makeLabelHeader(text: String, style: UIColor) -> UIView {
    let header = UIView()
    header.backgroundColor = style.withAlphaComponent(0.14)
    header.layer.cornerRadius = 10
    let label = UILabel()
    label.font = .boldSystemFont(ofSize: 15)
    label.textColor = .label
    label.text = text
    label.translatesAutoresizingMaskIntoConstraints = false
    header.addSubview(label)
    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 12),
      label.centerYAnchor.constraint(equalTo: header.centerYAnchor),
    ])
    return header
  }

  static func makeTextCard(_ text: String) -> UIView {
    let label = UILabel()
    label.numberOfLines = 0
    label.text = text
    label.backgroundColor = .secondarySystemGroupedBackground
    label.layer.cornerRadius = 10
    label.layer.masksToBounds = true
    label.font = .systemFont(ofSize: 14)
    label.textAlignment = .left
    label.heightAnchor.constraint(greaterThanOrEqualToConstant: 56).isActive = true
    return label
  }
}

private final class FKStickyCollectionHeaderView: UICollectionReusableView {
  private let label = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = UIColor.systemGreen.withAlphaComponent(0.15)
    layer.cornerRadius = 10
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = .boldSystemFont(ofSize: 15)
    addSubview(label)
    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
      label.centerYAnchor.constraint(equalTo: centerYAnchor),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  func configure(text: String) {
    label.text = text
  }
}

private final class FKStickyWaterfallLayout: UICollectionViewLayout {
  var availableWidth: CGFloat = 0
  var contentInsets: UIEdgeInsets = .zero
  private var cache: [UICollectionViewLayoutAttributes] = []
  private var contentSize: CGSize = .zero
  private let columns = 2
  private let headerHeight: CGFloat = 46
  private let spacing: CGFloat = 8

  override var collectionViewContentSize: CGSize { contentSize }

  override func prepare() {
    super.prepare()
    guard let collectionView else { return }
    cache.removeAll(keepingCapacity: true)
    let width = max(availableWidth - contentInsets.left - contentInsets.right, 100)
    let columnWidth = (width - spacing) / CGFloat(columns)
    var yOffset: CGFloat = contentInsets.top

    for section in 0..<collectionView.numberOfSections {
      let header = UICollectionViewLayoutAttributes(
        forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
        with: IndexPath(item: 0, section: section)
      )
      header.frame = CGRect(x: contentInsets.left, y: yOffset, width: width, height: headerHeight)
      cache.append(header)
      yOffset += headerHeight + spacing

      var columnHeights = Array(repeating: yOffset, count: columns)
      for item in 0..<collectionView.numberOfItems(inSection: section) {
        let indexPath = IndexPath(item: item, section: section)
        let minColumn = columnHeights.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
        let x = contentInsets.left + CGFloat(minColumn) * (columnWidth + spacing)
        let dynamicHeight = CGFloat(70 + ((item * 13 + section * 9) % 80))
        let frame = CGRect(x: x, y: columnHeights[minColumn], width: columnWidth, height: dynamicHeight)
        let attrs = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        attrs.frame = frame
        cache.append(attrs)
        columnHeights[minColumn] = frame.maxY + spacing
      }
      yOffset = (columnHeights.max() ?? yOffset) + 10
    }

    contentSize = CGSize(width: availableWidth, height: yOffset + contentInsets.bottom)
  }

  override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    cache.filter { $0.frame.intersects(rect) }
  }

  override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    cache.first { $0.representedElementCategory == .cell && $0.indexPath == indexPath }
  }

  override func layoutAttributesForSupplementaryView(
    ofKind elementKind: String,
    at indexPath: IndexPath
  ) -> UICollectionViewLayoutAttributes? {
    cache.first {
      $0.representedElementKind == elementKind && $0.indexPath.section == indexPath.section
    }
  }

  override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool { true }
}
