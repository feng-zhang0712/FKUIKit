//
//  FKSkeletonExampleViewController.swift
//  FKKitExamples
//

import UIKit
import FKUIKit

/// Single-page vertical scroll covering the main FKSkeleton APIs for visual comparison.
final class FKSkeletonExampleViewController: UIViewController {

  // MARK: - Toggle state

  private var isShowingSkeleton = true

  /// References for global show/hide (overlays, containers, standalone blocks, embedded lists).
  private var overlayTargets: [UIView] = []
  private var containerViews: [FKSkeletonContainerView] = []
  private var standaloneViews: [FKSkeletonView] = []
  private weak var hitTestBlockedHost: UIView?
  private weak var hitTestPassthroughHost: UIView?
  private weak var overlayOnVisibleCellsTable: UITableView?
  private weak var skeletonCellTableView: UITableView?
  private weak var skeletonCollectionView: UICollectionView?

  private let skeletonTableReuseId = "FKSkeletonTableViewCell.demo"
  private let skeletonCollectionReuseId = "FKSkeletonCollectionViewCell.demo"
  private let plainCellReuseId = "plain.demo"

  // MARK: - UI

  private lazy var statusLabel: UILabel = {
    let l = UILabel()
    l.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    l.textColor = .secondaryLabel
    l.textAlignment = .center
    l.numberOfLines = 0
    l.translatesAutoresizingMaskIntoConstraints = false
    return l
  }()

  private lazy var statusBar: UIView = {
    let v = UIView()
    v.backgroundColor = .secondarySystemBackground
    v.translatesAutoresizingMaskIntoConstraints = false
    return v
  }()

  private lazy var scrollView: UIScrollView = {
    let sv = UIScrollView()
    sv.alwaysBounceVertical = true
    sv.translatesAutoresizingMaskIntoConstraints = false
    return sv
  }()

  private lazy var contentStack: UIStackView = {
    let sv = UIStackView()
    sv.axis = NSLayoutConstraint.Axis.vertical
    sv.spacing = 24
    sv.translatesAutoresizingMaskIntoConstraints = false
    return sv
  }()

  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKSkeleton"
    view.backgroundColor = .systemGroupedBackground

    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Hide",
      style: .plain,
      target: self,
      action: #selector(toggleSkeleton)
    )

    statusBar.addSubview(statusLabel)
    view.addSubview(statusBar)
    view.addSubview(scrollView)
    scrollView.addSubview(contentStack)

    NSLayoutConstraint.activate([
      statusBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      statusBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      statusBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

      statusLabel.topAnchor.constraint(equalTo: statusBar.topAnchor, constant: 8),
      statusLabel.leadingAnchor.constraint(equalTo: statusBar.leadingAnchor, constant: 12),
      statusLabel.trailingAnchor.constraint(equalTo: statusBar.trailingAnchor, constant: -12),
      statusLabel.bottomAnchor.constraint(equalTo: statusBar.bottomAnchor, constant: -8),

      scrollView.topAnchor.constraint(equalTo: statusBar.bottomAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
      contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
      contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
      contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
      contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
    ])

    buildAllSections()
    applySkeletonVisibility(animated: false)
    updateStatusLabel()
  }

  // MARK: - Build (all sections on one page)

  private func buildAllSections() {
    contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    clearRegistry()

    contentStack.addArrangedSubview(introLabel())

    contentStack.addArrangedSubview(sectionHeader("1. fk_showSkeleton (overlay on placeholder views)"))
    contentStack.addArrangedSubview(buildOverlayOnPlaceholdersDemo())

    contentStack.addArrangedSubview(sectionHeader("2. fk_showSkeleton(respectsSafeArea:)"))
    contentStack.addArrangedSubview(noteLabel(
      "When the host view fills the screen as a root, set respectsSafeArea to true so the skeleton avoids the status bar and home indicator."
    ))

    contentStack.addArrangedSubview(sectionHeader("3. blocksInteraction: block taps vs pass-through"))
    contentStack.addArrangedSubview(buildHitTestComparison())

    contentStack.addArrangedSubview(sectionHeader("4. FKSkeletonPresets.listRow (circular avatar)"))
    contentStack.addArrangedSubview(wrapPreset(FKSkeletonPresets.listRow(), fixedHeight: 56))

    contentStack.addArrangedSubview(sectionHeader("5. listRow (rounded avatar, FKSkeletonAvatarStyle.rounded)"))
    contentStack.addArrangedSubview(wrapPreset(
      FKSkeletonPresets.listRow(avatarStyle: .rounded(cornerRadius: 8)),
      fixedHeight: 56
    ))

    contentStack.addArrangedSubview(sectionHeader("6. FKSkeletonPresets.card"))
    contentStack.addArrangedSubview(wrapPreset(FKSkeletonPresets.card(bannerHeight: 120)))

    contentStack.addArrangedSubview(sectionHeader("7. textBlock (default, last line shorter)"))
    contentStack.addArrangedSubview(wrapPreset(FKSkeletonPresets.textBlock(lineCount: 4)))

    contentStack.addArrangedSubview(sectionHeader("8. textBlock(lineWidthRatios:) per-line width"))
    contentStack.addArrangedSubview(wrapPreset(FKSkeletonPresets.textBlock(
      lineCount: 4,
      lineWidthRatios: [1.0, 0.9, 0.7, 0.35]
    )))

    contentStack.addArrangedSubview(sectionHeader("9. FKSkeletonPresets.gridCell × 3"))
    contentStack.addArrangedSubview(buildGridRow())

    contentStack.addArrangedSubview(sectionHeader("10. FKSkeletonContainerView.usesUnifiedShimmer"))
    contentStack.addArrangedSubview(noteLabel(
      "Left: usesUnifiedShimmer = true (default, one shared highlight). Right: false (per-block animations; heavier when many cells)."
    ))
    contentStack.addArrangedSubview(buildUnifiedComparisonRow())

    contentStack.addArrangedSubview(sectionHeader("11. FKSkeletonView: shimmer / breathing / none"))
    contentStack.addArrangedSubview(buildStandaloneRow(
      title: "shimmer · default",
      config: FKSkeletonConfiguration(animationDuration: 1.4, animationMode: .shimmer)
    ))
    contentStack.addArrangedSubview(buildStandaloneRow(
      title: "breathing",
      config: FKSkeletonConfiguration(animationDuration: 1.6, animationMode: .breathing, breathingMinOpacity: 0.4)
    ))
    contentStack.addArrangedSubview(buildStandaloneRow(
      title: "none · static",
      config: FKSkeletonConfiguration(animationMode: .none)
    ))

    contentStack.addArrangedSubview(sectionHeader("12. FKSkeletonView: shimmer direction"))
    contentStack.addArrangedSubview(buildStandaloneRow(
      title: "diagonal",
      config: FKSkeletonConfiguration(
        baseColor: .systemPurple.withAlphaComponent(0.22),
        highlightColor: .systemPurple.withAlphaComponent(0.55),
        animationDuration: 1.8,
        shimmerDirection: .diagonal,
        animationMode: .shimmer
      )
    ))
    contentStack.addArrangedSubview(buildStandaloneRow(
      title: "topToBottom",
      config: FKSkeletonConfiguration(
        baseColor: .systemTeal.withAlphaComponent(0.22),
        highlightColor: .systemTeal.withAlphaComponent(0.55),
        animationDuration: 1.4,
        shimmerDirection: .topToBottom,
        animationMode: .shimmer
      )
    ))

    contentStack.addArrangedSubview(sectionHeader("13. FKSkeletonTableViewCell (dedicated skeleton cell)"))
    contentStack.addArrangedSubview(buildSkeletonTableDemo())

    contentStack.addArrangedSubview(sectionHeader("14. FKSkeletonCollectionViewCell"))
    contentStack.addArrangedSubview(buildSkeletonCollectionDemo())

    contentStack.addArrangedSubview(sectionHeader("15. UITableView.fk_showSkeletonOnVisibleCells (overlay on real cells)"))
    contentStack.addArrangedSubview(noteLabel(
      "For existing lists: overlay visible rows while loading, then fk_hideSkeletonOnVisibleCells and reloadData."
    ))
    contentStack.addArrangedSubview(buildVisibleCellsOverlayTable())
  }

  // MARK: - Section builders

  private func introLabel() -> UIView {
    let l = UILabel()
    l.text = "All sections below are on one page. Use the bar button to show or hide every skeleton together for comparison."
    l.font = .preferredFont(forTextStyle: .subheadline)
    l.textColor = .secondaryLabel
    l.numberOfLines = 0
    return l
  }

  private func sectionHeader(_ text: String) -> UILabel {
    let l = UILabel()
    l.text = text
    l.font = .systemFont(ofSize: 13, weight: .semibold)
    l.textColor = .label
    l.numberOfLines = 0
    return l
  }

  private func noteLabel(_ text: String) -> UILabel {
    let l = UILabel()
    l.text = text
    l.font = .preferredFont(forTextStyle: .caption1)
    l.textColor = .tertiaryLabel
    l.numberOfLines = 0
    return l
  }

  private func buildOverlayOnPlaceholdersDemo() -> UIView {
    let card = makeCard()
    let avatar = makePlaceholder(width: 56, height: 56, radius: 28)
    let lineA = makePlaceholder(width: 0, height: 14, radius: 4)
    let lineB = makePlaceholder(width: 0, height: 12, radius: 4)

    card.addSubview(avatar)
    card.addSubview(lineA)
    card.addSubview(lineB)

    NSLayoutConstraint.activate([
      card.heightAnchor.constraint(equalToConstant: 72),
      avatar.leadingAnchor.constraint(equalTo: card.leadingAnchor),
      avatar.centerYAnchor.constraint(equalTo: card.centerYAnchor),
      avatar.widthAnchor.constraint(equalToConstant: 56),
      avatar.heightAnchor.constraint(equalToConstant: 56),
      lineA.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 12),
      lineA.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -32),
      lineA.heightAnchor.constraint(equalToConstant: 14),
      lineA.bottomAnchor.constraint(equalTo: card.centerYAnchor, constant: -3),
      lineB.leadingAnchor.constraint(equalTo: lineA.leadingAnchor),
      lineB.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -80),
      lineB.heightAnchor.constraint(equalToConstant: 12),
      lineB.topAnchor.constraint(equalTo: card.centerYAnchor, constant: 3),
    ])

    overlayTargets.append(contentsOf: [avatar, lineA, lineB])
    return card
  }

  private func buildHitTestComparison() -> UIStackView {
    let row = UIStackView()
    row.axis = NSLayoutConstraint.Axis.horizontal
    row.spacing = 12
    row.distribution = .fillEqually
    row.alignment = .fill

    let blocked = makeHitTestColumn(
      title: "blocksInteraction: true",
      blocksInteraction: true
    )
    let passthrough = makeHitTestColumn(
      title: "blocksInteraction: false",
      blocksInteraction: false
    )
    hitTestBlockedHost = blocked.host
    hitTestPassthroughHost = passthrough.host
    row.addArrangedSubview(blocked.stack)
    row.addArrangedSubview(passthrough.stack)
    return row
  }

  private func makeHitTestColumn(title: String, blocksInteraction: Bool) -> (stack: UIStackView, host: UIView) {
    let titleLabel = UILabel()
    titleLabel.text = title
    titleLabel.font = UIFont.preferredFont(forTextStyle: .caption2)
    titleLabel.textColor = .secondaryLabel
    titleLabel.numberOfLines = 0

    let result = UILabel()
    result.font = .monospacedDigitSystemFont(ofSize: 11, weight: .regular)
    result.textColor = .label
    result.text = "Taps: 0"
    result.tag = 9001

    let button = UIButton(type: .system)
    button.setTitle("Tap me", for: .normal)
    button.backgroundColor = .secondarySystemFill
    button.layer.cornerRadius = 8

    let host = UIView()
    host.backgroundColor = .clear
    host.translatesAutoresizingMaskIntoConstraints = false
    host.heightAnchor.constraint(equalToConstant: 96).isActive = true

    host.addSubview(button)
    button.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      button.topAnchor.constraint(equalTo: host.topAnchor),
      button.leadingAnchor.constraint(equalTo: host.leadingAnchor),
      button.trailingAnchor.constraint(equalTo: host.trailingAnchor),
      button.bottomAnchor.constraint(equalTo: host.bottomAnchor),
    ])

    var count = 0
    button.addAction(UIAction { [weak result] _ in
      count += 1
      result?.text = "Taps: \(count)"
    }, for: .touchUpInside)

    overlayTargets.append(host)

    let stack = UIStackView(arrangedSubviews: [titleLabel, host, result])
    stack.axis = NSLayoutConstraint.Axis.vertical
    stack.spacing = 6
    return (stack, host)
  }

  private func wrapPreset(_ container: FKSkeletonContainerView, fixedHeight: CGFloat? = nil) -> UIView {
    container.translatesAutoresizingMaskIntoConstraints = false
    containerViews.append(container)
    if let h = fixedHeight {
      container.heightAnchor.constraint(equalToConstant: h).isActive = true
    }
    return container
  }

  private func buildGridRow() -> UIView {
    let row = UIStackView()
    row.axis = NSLayoutConstraint.Axis.horizontal
    row.spacing = 12
    row.distribution = .fillEqually
    for _ in 0..<3 {
      let cell = FKSkeletonPresets.gridCell()
      cell.translatesAutoresizingMaskIntoConstraints = false
      containerViews.append(cell)
      row.addArrangedSubview(cell)
    }
    return row
  }

  private func buildUnifiedComparisonRow() -> UIView {
    let row = UIStackView()
    row.axis = NSLayoutConstraint.Axis.horizontal
    row.spacing = 12
    row.distribution = .fillEqually

    let unified = FKSkeletonPresets.textBlock(lineCount: 3, lineHeight: 10, lineSpacing: 6)
    unified.usesUnifiedShimmer = true
    unified.translatesAutoresizingMaskIntoConstraints = false

    let perBlock = FKSkeletonPresets.textBlock(lineCount: 3, lineHeight: 10, lineSpacing: 6)
    perBlock.usesUnifiedShimmer = false
    perBlock.translatesAutoresizingMaskIntoConstraints = false

    let capU = UILabel()
    capU.text = "unified"
    capU.font = UIFont.preferredFont(forTextStyle: .caption2)
    capU.textColor = .secondaryLabel
    let capP = UILabel()
    capP.text = "per-block"
    capP.font = UIFont.preferredFont(forTextStyle: .caption2)
    capP.textColor = .secondaryLabel

    let su = UIStackView(arrangedSubviews: [capU, unified])
    su.axis = NSLayoutConstraint.Axis.vertical
    su.spacing = 4
    let sp = UIStackView(arrangedSubviews: [capP, perBlock])
    sp.axis = NSLayoutConstraint.Axis.vertical
    sp.spacing = 4

    containerViews.append(unified)
    containerViews.append(perBlock)

    row.addArrangedSubview(su)
    row.addArrangedSubview(sp)
    return row
  }

  private func buildStandaloneRow(title: String, config: FKSkeletonConfiguration) -> UIView {
    let cap = UILabel()
    cap.text = title
    cap.font = UIFont.preferredFont(forTextStyle: .caption2)
    cap.textColor = .secondaryLabel

    let v = FKSkeletonView()
    v.translatesAutoresizingMaskIntoConstraints = false
    v.layer.cornerRadius = 12
    v.configuration = config
    v.heightAnchor.constraint(equalToConstant: 52).isActive = true
    standaloneViews.append(v)

    let stack = UIStackView(arrangedSubviews: [cap, v])
    stack.axis = NSLayoutConstraint.Axis.vertical
    stack.spacing = 6
    return stack
  }

  private func buildSkeletonTableDemo() -> UIView {
    let tv = UITableView(frame: .zero, style: .plain)
    tv.translatesAutoresizingMaskIntoConstraints = false
    tv.isScrollEnabled = false
    tv.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    tv.register(FKSkeletonTableViewCell.self, forCellReuseIdentifier: skeletonTableReuseId)
    tv.dataSource = self
    tv.delegate = self
    tv.tag = 7001
    skeletonCellTableView = tv

    let h: CGFloat = 3 * 64 + 2
    tv.heightAnchor.constraint(equalToConstant: h).isActive = true
    tv.reloadData()
    return tv
  }

  private func buildSkeletonCollectionDemo() -> UIView {
    let layout = UICollectionViewFlowLayout()
    layout.minimumInteritemSpacing = 12
    layout.minimumLineSpacing = 12
    layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

    let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
    cv.translatesAutoresizingMaskIntoConstraints = false
    cv.backgroundColor = .clear
    cv.register(FKSkeletonCollectionViewCell.self, forCellWithReuseIdentifier: skeletonCollectionReuseId)
    cv.dataSource = self
    cv.delegate = self
    cv.tag = 8001
    skeletonCollectionView = cv

    cv.heightAnchor.constraint(equalToConstant: 200).isActive = true
    cv.reloadData()
    return cv
  }

  private func buildVisibleCellsOverlayTable() -> UIView {
    let tv = UITableView(frame: .zero, style: .insetGrouped)
    tv.translatesAutoresizingMaskIntoConstraints = false
    tv.isScrollEnabled = false
    tv.register(UITableViewCell.self, forCellReuseIdentifier: plainCellReuseId)
    tv.dataSource = self
    tv.delegate = self
    tv.tag = 9002
    overlayOnVisibleCellsTable = tv

    tv.heightAnchor.constraint(equalToConstant: 132).isActive = true
    tv.reloadData()
    return tv
  }

  // MARK: - Helpers (chrome)

  private func makeCard() -> UIView {
    let v = UIView()
    v.backgroundColor = .secondarySystemGroupedBackground
    v.layer.cornerRadius = 12
    v.layer.cornerCurve = .continuous
    v.translatesAutoresizingMaskIntoConstraints = false
    return v
  }

  private func makePlaceholder(width: CGFloat, height: CGFloat, radius: CGFloat) -> UIView {
    let v = UIView()
    v.backgroundColor = .systemFill
    v.layer.cornerRadius = radius
    v.layer.cornerCurve = .continuous
    v.translatesAutoresizingMaskIntoConstraints = false
    if width > 0 { v.widthAnchor.constraint(equalToConstant: width).isActive = true }
    v.heightAnchor.constraint(equalToConstant: height).isActive = true
    return v
  }

  private func clearRegistry() {
    overlayTargets.removeAll()
    containerViews.removeAll()
    standaloneViews.removeAll()
    hitTestBlockedHost = nil
    hitTestPassthroughHost = nil
    overlayOnVisibleCellsTable = nil
    skeletonCellTableView = nil
    skeletonCollectionView = nil
  }

  // MARK: - Visibility

  private func applySkeletonVisibility(animated: Bool) {
    overlayTargets.forEach { view in
      if view === hitTestBlockedHost {
        isShowingSkeleton
          ? view.fk_showSkeleton(animated: animated, blocksInteraction: true)
          : view.fk_hideSkeleton(animated: animated)
        return
      }
      if view === hitTestPassthroughHost {
        isShowingSkeleton
          ? view.fk_showSkeleton(animated: animated, blocksInteraction: false)
          : view.fk_hideSkeleton(animated: animated)
        return
      }
      if isShowingSkeleton {
        view.fk_showSkeleton(animated: animated)
      } else {
        view.fk_hideSkeleton(animated: animated)
      }
    }

    containerViews.forEach {
      isShowingSkeleton ? $0.showSkeleton(animated: animated) : $0.hideSkeleton(animated: animated)
    }

    standaloneViews.forEach {
      isShowingSkeleton ? $0.show(animated: animated) : $0.hide(animated: animated)
    }

    if let tv = skeletonCellTableView {
      tv.visibleCells.compactMap { $0 as? FKSkeletonTableViewCell }.forEach { cell in
        isShowingSkeleton
          ? cell.skeletonContainer.showSkeleton(animated: animated)
          : cell.skeletonContainer.hideSkeleton(animated: animated)
      }
    }

    if let cv = skeletonCollectionView {
      cv.visibleCells.compactMap { $0 as? FKSkeletonCollectionViewCell }.forEach { cell in
        isShowingSkeleton
          ? cell.skeletonContainer.showSkeleton(animated: animated)
          : cell.skeletonContainer.hideSkeleton(animated: animated)
      }
    }

    if let tv = overlayOnVisibleCellsTable {
      if isShowingSkeleton {
        tv.fk_showSkeletonOnVisibleCells(animated: animated, blocksInteraction: true)
      } else {
        tv.fk_hideSkeletonOnVisibleCells(animated: animated)
      }
    }
  }

  private func updateStatusLabel() {
    let state = isShowingSkeleton ? "Skeleton visible" : "Skeleton hidden"
    statusLabel.text = "Bar button · \(state)"
  }

  // MARK: - Actions

  @objc private func toggleSkeleton() {
    isShowingSkeleton.toggle()
    applySkeletonVisibility(animated: true)
    navigationItem.rightBarButtonItem?.title = isShowingSkeleton ? "Hide" : "Show"
    updateStatusLabel()
  }
}

// MARK: - UITableViewDataSource (embedded tables)

extension FKSkeletonExampleViewController: UITableViewDataSource, UITableViewDelegate {

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch tableView.tag {
    case 7001: return 3
    case 9002: return 2
    default: return 0
    }
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if tableView.tag == 7001 {
      let cell = tableView.dequeueReusableCell(withIdentifier: skeletonTableReuseId, for: indexPath) as! FKSkeletonTableViewCell
      SkeletonDemo.configureListRow(in: cell)
      return cell
    }
    let cell = tableView.dequeueReusableCell(withIdentifier: plainCellReuseId, for: indexPath)
    var config = cell.defaultContentConfiguration()
    config.text = indexPath.row == 0 ? "Sample row A (content cell)" : "Sample row B (content cell)"
    cell.contentConfiguration = config
    cell.backgroundColor = .secondarySystemGroupedBackground
    return cell
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if tableView.tag == 7001 { return 64 }
    if tableView.tag == 9002 { return 52 }
    return UITableView.automaticDimension
  }
}

// MARK: - UICollectionView (embedded)

extension FKSkeletonExampleViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    4
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: skeletonCollectionReuseId, for: indexPath) as! FKSkeletonCollectionViewCell
    SkeletonDemo.configureGrid(in: cell)
    return cell
  }

  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    let layout = collectionViewLayout as! UICollectionViewFlowLayout
    let totalSpacing = layout.minimumInteritemSpacing + layout.sectionInset.left + layout.sectionInset.right
    let w = floor((collectionView.bounds.width - totalSpacing) / 2)
    return CGSize(width: max(80, w), height: 188)
  }
}

// MARK: - Skeleton cell configuration (demo-only)

private enum SkeletonDemo {

  static func configureListRow(in cell: FKSkeletonTableViewCell) {
    cell.resetSkeletonContent()
    let c = cell.skeletonContainer
    let avatar = FKSkeletonView()
    avatar.layer.cornerRadius = 22
    let t1 = FKSkeletonView()
    t1.layer.cornerRadius = 4
    let t2 = FKSkeletonView()
    t2.layer.cornerRadius = 4
    [avatar, t1, t2].forEach { c.addSkeletonSubview($0) }

    NSLayoutConstraint.activate([
      avatar.leadingAnchor.constraint(equalTo: c.leadingAnchor),
      avatar.centerYAnchor.constraint(equalTo: c.centerYAnchor),
      avatar.widthAnchor.constraint(equalToConstant: 44),
      avatar.heightAnchor.constraint(equalToConstant: 44),

      t1.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 12),
      t1.trailingAnchor.constraint(equalTo: c.trailingAnchor, constant: -24),
      t1.heightAnchor.constraint(equalToConstant: 12),
      t1.bottomAnchor.constraint(equalTo: c.centerYAnchor, constant: -3),

      t2.leadingAnchor.constraint(equalTo: t1.leadingAnchor),
      t2.trailingAnchor.constraint(equalTo: c.trailingAnchor, constant: -64),
      t2.heightAnchor.constraint(equalToConstant: 10),
      t2.topAnchor.constraint(equalTo: c.centerYAnchor, constant: 3),
    ])
  }

  static func configureGrid(in cell: FKSkeletonCollectionViewCell) {
    cell.resetSkeletonContent()
    let c = cell.skeletonContainer
    let image = FKSkeletonView()
    image.layer.cornerRadius = 8
    let label = FKSkeletonView()
    label.layer.cornerRadius = 4
    [image, label].forEach { c.addSkeletonSubview($0) }

    NSLayoutConstraint.activate([
      image.topAnchor.constraint(equalTo: c.topAnchor),
      image.leadingAnchor.constraint(equalTo: c.leadingAnchor),
      image.trailingAnchor.constraint(equalTo: c.trailingAnchor),
      image.heightAnchor.constraint(equalTo: image.widthAnchor),

      label.topAnchor.constraint(equalTo: image.bottomAnchor, constant: 8),
      label.leadingAnchor.constraint(equalTo: c.leadingAnchor, constant: 2),
      label.trailingAnchor.constraint(equalTo: c.trailingAnchor, constant: -2),
      label.heightAnchor.constraint(equalToConstant: 12),
      label.bottomAnchor.constraint(equalTo: c.bottomAnchor),
    ])
  }
}
