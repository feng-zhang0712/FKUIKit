//
//  FKSkeletonExampleViewController.swift
//  FKKitExamples
//

import UIKit
import FKUIKit

/// A production-style showcase for FKSkeleton covering all key integration scenarios.
final class FKSkeletonExampleViewController: UIViewController {

  // MARK: - Reuse IDs

  private enum ReuseID {
    static let skeletonTable = "fk.skeleton.table"
    static let plainTable = "fk.plain.table"
    static let skeletonCollection = "fk.skeleton.collection"
    static let plainCollection = "fk.plain.collection"
  }

  // MARK: - Loading State

  private var isLoading = true

  /// Views controlled by overlay mode (`fk_showSkeleton` / `fk_hideSkeleton`).
  private var overlayViews: [UIView] = []
  /// Containers controlled by composable skeleton mode.
  private var containerViews: [FKSkeletonContainerView] = []
  /// Standalone skeleton blocks used for animation comparison.
  private var standaloneSkeletonViews: [FKSkeletonView] = []
  /// Roots controlled by auto tree mode (`fk_showAutoSkeleton` / `fk_hideAutoSkeleton`).
  private var autoRoots: [UIView] = []

  // MARK: - UI

  private lazy var stateLabel: UILabel = {
    let label = UILabel()
    label.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
    label.textAlignment = .center
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  private lazy var scrollView: UIScrollView = {
    let scrollView = UIScrollView()
    scrollView.alwaysBounceVertical = true
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    return scrollView
  }()

  private lazy var contentStack: UIStackView = {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 22
    stack.translatesAutoresizingMaskIntoConstraints = false
    return stack
  }()

  private weak var plainTableView: UITableView?
  private weak var skeletonTableView: UITableView?
  private weak var plainCollectionView: UICollectionView?
  private weak var skeletonCollectionView: UICollectionView?

  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKSkeleton"
    view.backgroundColor = .systemGroupedBackground
    configureNavigationItems()
    configureLayout()
    configureGlobalSkeletonStyle()
    buildDemoSections()
    applyLoadingState(animated: false)
  }

  // MARK: - Setup

  private func configureNavigationItems() {
    navigationItem.rightBarButtonItems = [
      UIBarButtonItem(title: "Toggle", style: .plain, target: self, action: #selector(toggleLoadingState)),
      UIBarButtonItem(title: "Simulate API", style: .plain, target: self, action: #selector(simulateNetworkLoading)),
    ]
  }

  private func configureLayout() {
    view.addSubview(stateLabel)
    view.addSubview(scrollView)
    scrollView.addSubview(contentStack)

    NSLayoutConstraint.activate([
      stateLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      stateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      stateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

      scrollView.topAnchor.constraint(equalTo: stateLabel.bottomAnchor, constant: 12),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
      contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
      contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
      contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
      contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
    ])
  }

  /// Demonstrates one-time global style setup.
  private func configureGlobalSkeletonStyle() {
    FKSkeleton.defaultConfiguration = FKSkeletonConfiguration(
      baseColor: UIColor.systemGray5,
      highlightColor: UIColor.white.withAlphaComponent(0.8),
      gradientColors: [
        UIColor.systemGray5,
        UIColor.white.withAlphaComponent(0.9),
        UIColor.systemGray5,
      ],
      cornerRadius: 8,
      borderWidth: 0.5,
      animationDuration: 1.2,
      animationMode: .shimmer,
      lineSpacing: 8,
      lineHeight: 12,
      transitionDuration: 0.2
    )
  }

  // MARK: - Section Builder

  private func buildDemoSections() {
    contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    overlayViews.removeAll()
    containerViews.removeAll()
    standaloneSkeletonViews.removeAll()
    autoRoots.removeAll()

    contentStack.addArrangedSubview(makeIntroLabel())

    contentStack.addArrangedSubview(makeSectionTitle("1) Basic UIView Overlay (UIButton / UILabel / UIImageView)"))
    contentStack.addArrangedSubview(buildBasicOverlaySection())

    contentStack.addArrangedSubview(makeSectionTitle("2) Auto Skeleton for UIStackView + Excluded Subview"))
    contentStack.addArrangedSubview(buildStackAutoSection())

    contentStack.addArrangedSubview(makeSectionTitle("3) Custom Colors, Radius, Speed, and Pulse/Gradient Animations"))
    contentStack.addArrangedSubview(buildAnimationSection())

    contentStack.addArrangedSubview(makeSectionTitle("4) UITableView Skeleton (Dedicated Skeleton Cell)"))
    contentStack.addArrangedSubview(buildSkeletonTableSection())

    contentStack.addArrangedSubview(makeSectionTitle("5) UITableView Skeleton (Overlay on Existing Cells)"))
    contentStack.addArrangedSubview(buildPlainTableSection())

    contentStack.addArrangedSubview(makeSectionTitle("6) UICollectionView Skeleton (Dedicated Skeleton Cell)"))
    contentStack.addArrangedSubview(buildSkeletonCollectionSection())

    contentStack.addArrangedSubview(makeSectionTitle("7) UICollectionView Skeleton (Overlay on Existing Cells)"))
    contentStack.addArrangedSubview(buildPlainCollectionSection())
  }

  // MARK: - Sections

  /// Basic one-line show/hide skeleton APIs on regular UI controls.
  private func buildBasicOverlaySection() -> UIView {
    let card = makeCard()
    card.heightAnchor.constraint(equalToConstant: 112).isActive = true

    let avatar = makeRoundedPlaceholder(size: 58, cornerRadius: 29)
    let titleLabel = makeRoundedPlaceholder(height: 14, cornerRadius: 4)
    let subtitleLabel = makeRoundedPlaceholder(height: 12, cornerRadius: 4)
    let button = makeRoundedPlaceholder(height: 34, cornerRadius: 8)

    [avatar, titleLabel, subtitleLabel, button].forEach { card.addSubview($0) }

    NSLayoutConstraint.activate([
      avatar.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
      avatar.centerYAnchor.constraint(equalTo: card.centerYAnchor),
      avatar.widthAnchor.constraint(equalToConstant: 58),
      avatar.heightAnchor.constraint(equalToConstant: 58),

      titleLabel.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 12),
      titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
      titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 22),

      subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
      subtitleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -64),
      subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),

      button.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
      button.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 12),
      button.widthAnchor.constraint(equalToConstant: 90),
    ])

    overlayViews.append(contentsOf: [avatar, titleLabel, subtitleLabel, button])
    return card
  }

  /// Auto skeleton on stack arranged subviews while excluding one badge view.
  private func buildStackAutoSection() -> UIView {
    let card = makeCard()
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 10
    stack.translatesAutoresizingMaskIntoConstraints = false
    card.addSubview(stack)

    let title = UILabel()
    title.text = "Account Summary"
    title.font = .systemFont(ofSize: 16, weight: .semibold)

    let amount = UILabel()
    amount.text = "$ 98,720.00"
    amount.font = .systemFont(ofSize: 26, weight: .bold)

    let badge = UILabel()
    badge.text = "VIP"
    badge.font = .systemFont(ofSize: 11, weight: .semibold)
    badge.textColor = .white
    badge.backgroundColor = .systemBlue
    badge.layer.cornerRadius = 8
    badge.layer.masksToBounds = true
    badge.textAlignment = .center
    badge.widthAnchor.constraint(equalToConstant: 52).isActive = true
    badge.heightAnchor.constraint(equalToConstant: 24).isActive = true
    /// Exclude this subview from auto generated skeleton.
    badge.fk_isSkeletonExcluded = true

    let footerButton = UIButton(type: .system)
    footerButton.setTitle("Transfer", for: .normal)
    footerButton.backgroundColor = .secondarySystemBackground
    footerButton.layer.cornerRadius = 10
    footerButton.heightAnchor.constraint(equalToConstant: 42).isActive = true

    [title, amount, badge, footerButton].forEach { stack.addArrangedSubview($0) }

    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
      stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
      stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
      stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
    ])

    autoRoots.append(stack)
    return card
  }

  /// Standalone blocks with per-view custom animation and style.
  private func buildAnimationSection() -> UIView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 10

    let gradientBlock = makeStandaloneSkeleton(
      title: "Gradient shimmer · custom color & speed",
      config: FKSkeletonConfiguration(
        baseColor: UIColor.systemPurple.withAlphaComponent(0.22),
        highlightColor: UIColor.systemPurple.withAlphaComponent(0.7),
        gradientColors: [
          UIColor.systemPurple.withAlphaComponent(0.2),
          UIColor.systemPurple.withAlphaComponent(0.75),
          UIColor.systemPurple.withAlphaComponent(0.2),
        ],
        cornerRadius: 12,
        animationDuration: 1.8,
        shimmerDirection: .diagonal,
        animationMode: .shimmer
      )
    )

    let pulseBlock = makeStandaloneSkeleton(
      title: "Pulse animation · custom corner radius",
      config: FKSkeletonConfiguration(
        baseColor: UIColor.systemTeal.withAlphaComponent(0.2),
        highlightColor: UIColor.systemTeal.withAlphaComponent(0.7),
        cornerRadius: 18,
        animationDuration: 1.0,
        animationMode: .pulse,
        breathingMinOpacity: 0.35
      )
    )

    stack.addArrangedSubview(gradientBlock)
    stack.addArrangedSubview(pulseBlock)
    return stack
  }

  /// Table skeleton using `FKSkeletonTableViewCell`.
  private func buildSkeletonTableSection() -> UIView {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.isScrollEnabled = false
    tableView.rowHeight = 68
    tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    tableView.register(FKSkeletonTableViewCell.self, forCellReuseIdentifier: ReuseID.skeletonTable)
    tableView.dataSource = self
    tableView.delegate = self
    tableView.tag = 1001
    tableView.heightAnchor.constraint(equalToConstant: 68 * 3).isActive = true
    skeletonTableView = tableView
    return tableView
  }

  /// Table overlay skeleton on existing content cells.
  private func buildPlainTableSection() -> UIView {
    let tableView = UITableView(frame: .zero, style: .insetGrouped)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.isScrollEnabled = false
    tableView.rowHeight = 56
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: ReuseID.plainTable)
    tableView.dataSource = self
    tableView.delegate = self
    tableView.tag = 1002
    tableView.heightAnchor.constraint(equalToConstant: 56 * 2 + 10).isActive = true
    plainTableView = tableView
    return tableView
  }

  /// Collection skeleton using `FKSkeletonCollectionViewCell`.
  private func buildSkeletonCollectionSection() -> UIView {
    let layout = UICollectionViewFlowLayout()
    layout.minimumLineSpacing = 10
    layout.minimumInteritemSpacing = 10

    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.backgroundColor = .clear
    collectionView.isScrollEnabled = false
    collectionView.register(FKSkeletonCollectionViewCell.self, forCellWithReuseIdentifier: ReuseID.skeletonCollection)
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.tag = 1003
    collectionView.heightAnchor.constraint(equalToConstant: 204).isActive = true
    skeletonCollectionView = collectionView
    return collectionView
  }

  /// Collection overlay skeleton on existing content items.
  private func buildPlainCollectionSection() -> UIView {
    let layout = UICollectionViewFlowLayout()
    layout.minimumLineSpacing = 10
    layout.minimumInteritemSpacing = 10

    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.backgroundColor = .clear
    collectionView.isScrollEnabled = false
    collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: ReuseID.plainCollection)
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.tag = 1004
    collectionView.heightAnchor.constraint(equalToConstant: 150).isActive = true
    plainCollectionView = collectionView
    return collectionView
  }

  // MARK: - Loading Control

  /// Applies a unified loading state to all demo blocks.
  private func applyLoadingState(animated: Bool) {
    if isLoading {
      showAllSkeletons(animated: animated)
    } else {
      hideAllSkeletons(animated: animated)
    }
    stateLabel.text = isLoading ? "Loading state: ON" : "Loading state: OFF"
  }

  private func showAllSkeletons(animated: Bool) {
    // Basic overlay mode.
    overlayViews.forEach { $0.fk_showSkeleton(animated: animated) }

    // Auto skeleton for stack roots.
    autoRoots.forEach {
      $0.fk_showAutoSkeleton(
        options: FKSkeletonDisplayOptions(blocksInteraction: true, hidesTargetView: true),
        animated: animated
      )
    }

    // Dedicated composable container mode.
    containerViews.forEach { $0.showSkeleton(animated: animated) }
    standaloneSkeletonViews.forEach { $0.show(animated: animated) }

    // Table/collection helpers.
    plainTableView?.fk_showSkeletonOnVisibleCells(animated: animated)
    plainCollectionView?.fk_showAutoSkeletonOnVisibleCells(animated: animated)

    skeletonTableView?.reloadData()
    skeletonCollectionView?.reloadData()
  }

  private func hideAllSkeletons(animated: Bool) {
    overlayViews.forEach { $0.fk_hideSkeleton(animated: animated) }
    autoRoots.forEach { $0.fk_hideAutoSkeleton(animated: animated) }
    containerViews.forEach { $0.hideSkeleton(animated: animated) }
    standaloneSkeletonViews.forEach { $0.hide(animated: animated) }
    plainTableView?.fk_hideSkeletonOnVisibleCells(animated: animated)
    plainCollectionView?.fk_hideAutoSkeletonOnVisibleCells(animated: animated)
  }

  // MARK: - Actions

  @objc private func toggleLoadingState() {
    isLoading.toggle()
    applyLoadingState(animated: true)
  }

  /// Demonstrates one-line state control with request completion.
  @objc private func simulateNetworkLoading() {
    isLoading = true
    applyLoadingState(animated: true)

    // One-line loading lifecycle for the whole page.
    view.fk_withSkeletonLoading(animated: true) { done in
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { [weak self] in
        self?.isLoading = false
        self?.applyLoadingState(animated: true)
        done()
      }
    }
  }

  // MARK: - UI Helpers

  private func makeIntroLabel() -> UIView {
    let label = UILabel()
    label.numberOfLines = 0
    label.textColor = .secondaryLabel
    label.font = .preferredFont(forTextStyle: .subheadline)
    label.text = """
    This screen provides copy-ready FKSkeleton examples:
    UIView/UILabel/UIImageView/UIButton, UITableView, UICollectionView, UIStackView,
    global style config, custom animation config, exclusion rules, and manual state control.
    """
    return label
  }

  private func makeSectionTitle(_ text: String) -> UILabel {
    let label = UILabel()
    label.text = text
    label.font = .systemFont(ofSize: 13, weight: .semibold)
    label.numberOfLines = 0
    return label
  }

  private func makeCard() -> UIView {
    let card = UIView()
    card.backgroundColor = .secondarySystemGroupedBackground
    card.layer.cornerRadius = 12
    card.layer.cornerCurve = .continuous
    card.translatesAutoresizingMaskIntoConstraints = false
    return card
  }

  private func makeRoundedPlaceholder(size: CGFloat? = nil, height: CGFloat = 12, cornerRadius: CGFloat) -> UIView {
    let view = UIView()
    view.backgroundColor = .systemFill
    view.layer.cornerRadius = cornerRadius
    view.layer.cornerCurve = .continuous
    view.translatesAutoresizingMaskIntoConstraints = false
    view.heightAnchor.constraint(equalToConstant: height).isActive = true
    if let size {
      view.widthAnchor.constraint(equalToConstant: size).isActive = true
      view.heightAnchor.constraint(equalToConstant: size).isActive = true
    }
    return view
  }

  private func makeStandaloneSkeleton(title: String, config: FKSkeletonConfiguration) -> UIView {
    let container = UIStackView()
    container.axis = .vertical
    container.spacing = 6

    let caption = UILabel()
    caption.text = title
    caption.font = .preferredFont(forTextStyle: .caption1)
    caption.textColor = .secondaryLabel

    let block = FKSkeletonView()
    block.translatesAutoresizingMaskIntoConstraints = false
    block.configuration = config
    block.layer.cornerRadius = config.cornerRadius
    block.heightAnchor.constraint(equalToConstant: 52).isActive = true

    standaloneSkeletonViews.append(block)
    container.addArrangedSubview(caption)
    container.addArrangedSubview(block)
    return container
  }
}

// MARK: - UITableView

extension FKSkeletonExampleViewController: UITableViewDataSource, UITableViewDelegate {

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch tableView.tag {
    case 1001: return 3
    case 1002: return 2
    default: return 0
    }
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if tableView.tag == 1001 {
      let cell = tableView.dequeueReusableCell(withIdentifier: ReuseID.skeletonTable, for: indexPath) as! FKSkeletonTableViewCell
      Self.configureSkeletonListCell(cell)
      if isLoading {
        cell.skeletonContainer.showSkeleton(animated: false)
      } else {
        cell.skeletonContainer.hideSkeleton(animated: false)
      }
      return cell
    }

    let cell = tableView.dequeueReusableCell(withIdentifier: ReuseID.plainTable, for: indexPath)
    var content = cell.defaultContentConfiguration()
    content.text = indexPath.row == 0 ? "Order #A2026-001" : "Order #A2026-002"
    content.secondaryText = indexPath.row == 0 ? "Paid · 2 items" : "Pending · 1 item"
    cell.contentConfiguration = content
    return cell
  }

  private static func configureSkeletonListCell(_ cell: FKSkeletonTableViewCell) {
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
      line1.trailingAnchor.constraint(equalTo: c.trailingAnchor, constant: -28),
      line1.heightAnchor.constraint(equalToConstant: 12),
      line1.bottomAnchor.constraint(equalTo: c.centerYAnchor, constant: -3),

      line2.leadingAnchor.constraint(equalTo: line1.leadingAnchor),
      line2.trailingAnchor.constraint(equalTo: c.trailingAnchor, constant: -72),
      line2.heightAnchor.constraint(equalToConstant: 10),
      line2.topAnchor.constraint(equalTo: c.centerYAnchor, constant: 3),
    ])
  }
}

// MARK: - UICollectionView

extension FKSkeletonExampleViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    collectionView.tag == 1003 ? 4 : 3
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if collectionView.tag == 1003 {
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReuseID.skeletonCollection, for: indexPath) as! FKSkeletonCollectionViewCell
      Self.configureSkeletonGridCell(cell)
      if isLoading {
        cell.skeletonContainer.showSkeleton(animated: false)
      } else {
        cell.skeletonContainer.hideSkeleton(animated: false)
      }
      return cell
    }

    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReuseID.plainCollection, for: indexPath)
    cell.contentView.backgroundColor = .secondarySystemGroupedBackground
    cell.contentView.layer.cornerRadius = 10
    cell.contentView.layer.masksToBounds = true
    return cell
  }

  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else {
      return CGSize(width: 100, height: 100)
    }
    let columns: CGFloat = collectionView.tag == 1003 ? 2 : 3
    let totalSpacing = layout.minimumInteritemSpacing * (columns - 1)
    let width = floor((collectionView.bounds.width - totalSpacing) / columns)
    let height: CGFloat = collectionView.tag == 1003 ? 96 : 44
    return CGSize(width: max(70, width), height: height)
  }

  private static func configureSkeletonGridCell(_ cell: FKSkeletonCollectionViewCell) {
    cell.resetSkeletonContent()
    let c = cell.skeletonContainer

    let image = FKSkeletonView()
    image.layer.cornerRadius = 8
    let line = FKSkeletonView()
    line.layer.cornerRadius = 4

    [image, line].forEach { c.addSkeletonSubview($0) }

    NSLayoutConstraint.activate([
      image.topAnchor.constraint(equalTo: c.topAnchor),
      image.leadingAnchor.constraint(equalTo: c.leadingAnchor),
      image.trailingAnchor.constraint(equalTo: c.trailingAnchor),
      image.heightAnchor.constraint(equalTo: image.widthAnchor, multiplier: 0.6),

      line.leadingAnchor.constraint(equalTo: c.leadingAnchor, constant: 6),
      line.trailingAnchor.constraint(equalTo: c.trailingAnchor, constant: -6),
      line.topAnchor.constraint(equalTo: image.bottomAnchor, constant: 8),
      line.heightAnchor.constraint(equalToConstant: 12),
      line.bottomAnchor.constraint(lessThanOrEqualTo: c.bottomAnchor),
    ])
  }
}
