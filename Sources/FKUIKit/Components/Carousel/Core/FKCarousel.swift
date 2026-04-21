//
// FKCarousel.swift
//

import UIKit

/// High-performance, infinitely looping carousel component based on `UICollectionView`.
///
/// `FKCarousel` is designed for production banner/card scenarios and combines
/// virtualization, cell reuse, and timer-driven playback with a simple API surface.
@MainActor
public final class FKCarousel: UIView {
  /// Called when user taps a carousel item.
  ///
  /// The first argument is the logical index in original data source order.
  public var onItemSelected: ((Int, FKCarouselItem) -> Void)?
  /// Called whenever visible page changes.
  ///
  /// The argument is the logical index in original data source order.
  public var onPageChanged: ((Int) -> Void)?

  /// Collection layout driving paged horizontal/vertical scrolling.
  private let flowLayout = UICollectionViewFlowLayout()
  /// Main rendering view responsible for cell reuse and smooth paging behavior.
  private lazy var collectionView: UICollectionView = {
    flowLayout.minimumLineSpacing = 0
    flowLayout.minimumInteritemSpacing = 0
    flowLayout.scrollDirection = .horizontal
    let view = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
    view.isPagingEnabled = true
    view.showsHorizontalScrollIndicator = false
    view.showsVerticalScrollIndicator = false
    view.backgroundColor = .clear
    view.decelerationRate = .fast
    view.translatesAutoresizingMaskIntoConstraints = false
    view.dataSource = self
    view.delegate = self
    view.register(FKCarouselImageCell.self, forCellWithReuseIdentifier: FKCarouselImageCell.reuseIdentifier)
    view.register(FKCarouselCustomViewCell.self, forCellWithReuseIdentifier: FKCarouselCustomViewCell.reuseIdentifier)
    return view
  }()

  /// Internal page control synchronized with logical index changes.
  private let pageControl = FKCarouselPageControl()
  /// Effective configuration currently applied to this instance.
  private var configuration = FKCarouselConfiguration()
  /// Logical data source items.
  private var items: [FKCarouselItem] = []
  /// Timer used for auto-scroll playback.
  private var autoScrollTimer: Timer?
  /// Indicates whether initial centering scroll must run after layout.
  private var pendingInitialScroll = false
  /// Last known size used to detect layout/rotation changes.
  private var lastKnownBoundsSize: CGSize = .zero
  /// Current logical page index in range `0..<items.count`.
  private var currentLogicalIndex = 0
  /// Virtualization multiplier used for infinite-loop index space.
  private let infiniteMultiplier = 200

  /// Creates a carousel with default global configuration.
  public override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
    apply(configuration: FKCarouselManager.shared.templateConfiguration)
  }

  /// Creates a carousel for Interface Builder/XIB usage.
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupUI()
    apply(configuration: FKCarouselManager.shared.templateConfiguration)
  }

  /// Ensures timer is invalidated and does not outlive the view.
  @MainActor deinit {
    stopAutoScroll()
  }

  /// Applies a fresh configuration to current carousel instance.
  ///
  /// - Parameter configuration: New configuration object.
  ///
  /// Calling this method updates scroll direction, appearance, page control rendering,
  /// and auto-scroll state without replacing existing data.
  public func apply(configuration: FKCarouselConfiguration) {
    self.configuration = configuration
    flowLayout.scrollDirection = configuration.direction.collectionScrollDirection
    updateAppearance()
    updatePageControlFrame()
    updatePageControl()
    updateScrollingCapability()
    restartAutoScrollIfNeeded()
  }

  /// Reloads carousel content source.
  ///
  /// - Parameter items: Data source to render.
  ///
  /// The method preserves the nearest valid logical index, refreshes page control state,
  /// and reapplies scroll capability rules (for example, single-item adaptation).
  public func reload(items: [FKCarouselItem]) {
    self.items = items
    currentLogicalIndex = min(currentLogicalIndex, max(0, items.count - 1))
    pendingInitialScroll = true
    collectionView.reloadData()
    updatePageControl()
    updateScrollingCapability()
    restartAutoScrollIfNeeded()
    setNeedsLayout()
  }

  /// Scrolls to a target logical page.
  ///
  /// - Parameters:
  ///   - page: Zero-based logical index.
  ///   - animated: Whether to animate the transition.
  ///
  /// The target logical index is converted into a virtual index when infinite mode is enabled.
  public func scrollToPage(_ page: Int, animated: Bool = true) {
    guard !items.isEmpty else { return }
    let logical = min(max(0, page), items.count - 1)
    let targetVirtual = canInfiniteLoop ? centeredVirtualIndex(for: logical) : logical
    let indexPath = IndexPath(item: targetVirtual, section: 0)
    collectionView.scrollToItem(at: indexPath, at: scrollPosition, animated: animated)
    currentLogicalIndex = logical
    pageControl.setCurrentPage(logical)
    onPageChanged?(logical)
  }

  /// Starts automatic scrolling.
  ///
  /// Auto scrolling is enabled only when:
  /// - auto-scroll is enabled in configuration
  /// - item count is greater than one
  /// - view is attached to a window
  public func startAutoScroll() {
    guard canAutoScroll else { return }
    stopAutoScroll()
    autoScrollTimer = Timer.scheduledTimer(withTimeInterval: configuration.autoScrollInterval, repeats: true) { [weak self] _ in
      self?.advanceAutoScroll()
    }
    if let timer = autoScrollTimer {
      RunLoop.main.add(timer, forMode: .common)
    }
  }

  /// Stops automatic scrolling and destroys the timer instance.
  public func stopAutoScroll() {
    autoScrollTimer?.invalidate()
    autoScrollTimer = nil
  }

  /// Pauses automatic scrolling without invalidating the timer.
  public func pauseAutoScroll() {
    autoScrollTimer?.fireDate = .distantFuture
  }

  /// Resumes automatic scrolling after a pause.
  ///
  /// If no timer exists, this method creates one by calling `startAutoScroll()`.
  public func resumeAutoScroll() {
    guard autoScrollTimer != nil else {
      startAutoScroll()
      return
    }
    autoScrollTimer?.fireDate = .init(timeIntervalSinceNow: configuration.autoScrollInterval)
  }

  /// Handles size changes, rotation updates, and initial index positioning.
  public override func layoutSubviews() {
    super.layoutSubviews()
    updatePageControlFrame()
    updateAppearance()

    // Recompute item size on bounds changes for rotation and dynamic layout adaptation.
    guard bounds.size != lastKnownBoundsSize else { return }
    lastKnownBoundsSize = bounds.size
    flowLayout.itemSize = bounds.size
    flowLayout.invalidateLayout()

    // Initial render jumps to the middle virtual section for seamless infinite looping.
    if pendingInitialScroll {
      performInitialScrollIfNeeded()
    } else if !items.isEmpty {
      scrollToPage(currentLogicalIndex, animated: false)
    }
  }

  /// Restarts auto-scroll behavior when window attachment changes.
  public override func didMoveToWindow() {
    super.didMoveToWindow()
    restartAutoScrollIfNeeded()
  }
}

private extension FKCarousel {
  /// Returns `true` when virtual infinite-loop behavior should be active.
  var canInfiniteLoop: Bool {
    configuration.isInfiniteEnabled && items.count > 1
  }

  /// Returns `true` when timer-based auto playback can run safely.
  var canAutoScroll: Bool {
    configuration.isAutoScrollEnabled && items.count > 1 && window != nil
  }

  /// Total `UICollectionView` item count after applying virtualization rules.
  var virtualItemCount: Int {
    guard !items.isEmpty else { return 0 }
    return canInfiniteLoop ? items.count * infiniteMultiplier : items.count
  }

  /// Correct centered scroll position for current axis.
  var scrollPosition: UICollectionView.ScrollPosition {
    configuration.direction == .horizontal ? .centeredHorizontally : .centeredVertically
  }

  /// Builds view hierarchy and static constraints.
  func setupUI() {
    isAccessibilityElement = false
    backgroundColor = .clear
    addSubview(collectionView)
    addSubview(pageControl)
    pageControl.translatesAutoresizingMaskIntoConstraints = true
    NSLayoutConstraint.activate([
      collectionView.topAnchor.constraint(equalTo: topAnchor),
      collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
      collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }

  /// Applies corner/border/shadow/content style from configuration.
  func updateAppearance() {
    let style = configuration.containerStyle
    collectionView.layer.cornerRadius = style.cornerRadius
    collectionView.layer.borderWidth = style.borderWidth
    collectionView.layer.borderColor = style.borderColor.cgColor
    collectionView.layer.masksToBounds = true

    // Shadow is rendered on outer host; collection content remains clipped for corner safety.
    layer.shadowColor = style.shadowColor.cgColor
    layer.shadowOpacity = style.shadowOpacity
    layer.shadowRadius = style.shadowRadius
    layer.shadowOffset = style.shadowOffset
    layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: style.cornerRadius).cgPath
  }

  /// Applies single-item adaptation to scrolling and page control visibility.
  func updateScrollingCapability() {
    let enabled = items.count > 1
    collectionView.isScrollEnabled = enabled
    pageControl.isHidden = !configuration.showsPageControl || items.count <= 1
  }

  /// Rebuilds page control with latest page count and current logical index.
  func updatePageControl() {
    pageControl.update(
      numberOfPages: items.count,
      currentPage: currentLogicalIndex,
      style: configuration.pageControlStyle
    )
  }

  /// Computes and applies page control frame with alignment/inset rules.
  func updatePageControlFrame() {
    let fixedHeight: CGFloat = 24
    let insets = configuration.pageControlInsets
    let maxWidth = max(0, bounds.width - insets.left - insets.right)
    let width = min(maxWidth, max(60, CGFloat(max(items.count, 1)) * (configuration.pageControlStyle.selectedDotSize.width + configuration.pageControlStyle.spacing)))
    let y = max(0, bounds.height - fixedHeight - insets.bottom)
    let x: CGFloat
    switch configuration.pageControlAlignment {
    case .center:
      x = (bounds.width - width) * 0.5
    case .left:
      x = insets.left
    case .right:
      x = bounds.width - insets.right - width
    }
    pageControl.frame = CGRect(x: x, y: y, width: width, height: fixedHeight)
  }

  /// Performs first non-animated positioning after data reload and layout completion.
  func performInitialScrollIfNeeded() {
    guard pendingInitialScroll, !items.isEmpty else { return }
    pendingInitialScroll = false
    // In infinite mode, start near the middle to keep large headroom in both directions.
    let target = canInfiniteLoop ? centeredVirtualIndex(for: currentLogicalIndex) : currentLogicalIndex
    collectionView.layoutIfNeeded()
    collectionView.scrollToItem(at: IndexPath(item: target, section: 0), at: scrollPosition, animated: false)
    pageControl.setCurrentPage(currentLogicalIndex)
  }

  /// Maps any virtual item index to logical data index (`0..<items.count`).
  ///
  /// This modulo mapping is the foundation of the infinite-loop virtualization model.
  func logicalIndex(forVirtualIndex index: Int) -> Int {
    guard !items.isEmpty else { return 0 }
    let count = items.count
    let value = index % count
    return value >= 0 ? value : value + count
  }

  /// Places a logical page around middle section to avoid edge flashes while infinitely scrolling.
  ///
  /// Centering prevents users from reaching virtualization boundaries during normal interaction.
  func centeredVirtualIndex(for logicalIndex: Int) -> Int {
    guard canInfiniteLoop, !items.isEmpty else { return logicalIndex }
    let middle = virtualItemCount / 2
    let base = middle - middle % items.count
    return base + logicalIndex
  }

  /// Recreates timer according to latest state and configuration.
  func restartAutoScrollIfNeeded() {
    stopAutoScroll()
    startAutoScroll()
  }

  /// Moves to next item and recenters the virtual index when needed.
  ///
  /// Called by timer ticks to produce continuous auto-play behavior.
  func advanceAutoScroll() {
    guard !items.isEmpty else { return }
    let current = nearestVirtualIndex()
    let next = min(current + 1, max(0, virtualItemCount - 1))
    collectionView.scrollToItem(at: IndexPath(item: next, section: 0), at: scrollPosition, animated: true)
  }

  /// Determines nearest visible virtual index based on collection view center point.
  func nearestVirtualIndex() -> Int {
    guard !items.isEmpty else { return 0 }
    let center = CGPoint(x: collectionView.bounds.midX + collectionView.contentOffset.x, y: collectionView.bounds.midY + collectionView.contentOffset.y)
    return collectionView.indexPathForItem(at: center)?.item ?? centeredVirtualIndex(for: currentLogicalIndex)
  }

  /// Re-centers index when user reaches virtual boundaries.
  ///
  /// This silent recenter operation is the key to keeping infinite scrolling seamless.
  func recenterIfNeeded(at virtualIndex: Int) {
    guard canInfiniteLoop, items.count > 1 else { return }
    let threshold = items.count * 2
    if virtualIndex < threshold || virtualIndex > virtualItemCount - threshold {
      let logical = logicalIndex(forVirtualIndex: virtualIndex)
      let middle = centeredVirtualIndex(for: logical)
      // Non-animated jump keeps the same logical page while resetting virtual headroom.
      collectionView.scrollToItem(at: IndexPath(item: middle, section: 0), at: scrollPosition, animated: false)
    }
  }

  /// Synchronizes logical page state and notifies external callback.
  func syncCurrentPage(from virtualIndex: Int) {
    guard !items.isEmpty else { return }
    let logical = logicalIndex(forVirtualIndex: virtualIndex)
    guard logical != currentLogicalIndex else { return }
    currentLogicalIndex = logical
    pageControl.setCurrentPage(logical)
    onPageChanged?(logical)
  }
}

extension FKCarousel: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
  /// Returns virtual item count used by collection view.
  public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    virtualItemCount
  }

  /// Dequeues and configures reusable carousel cells.
  ///
  /// Image and custom-view content paths are split to avoid unnecessary view work.
  public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard !items.isEmpty else { return UICollectionViewCell() }
    let logicalIndex = logicalIndex(forVirtualIndex: indexPath.item)
    let item = items[logicalIndex]

    switch item {
    case .customView, .customViewProvider:
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FKCarouselCustomViewCell.reuseIdentifier, for: indexPath) as! FKCarouselCustomViewCell
      cell.configure(with: item)
      return cell
    case .image, .url:
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FKCarouselImageCell.reuseIdentifier, for: indexPath) as! FKCarouselImageCell
      cell.configure(
        with: item,
        placeholder: configuration.placeholderImage,
        failureImage: configuration.failureImage,
        contentMode: configuration.containerStyle.contentMode
      )
      return cell
    }
  }

  /// Handles item tap and forwards logical index callback.
  public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard !items.isEmpty else { return }
    let logical = logicalIndex(forVirtualIndex: indexPath.item)
    onItemSelected?(logical, items[logical])
  }

  /// Pauses auto-play when user starts manual gesture interaction.
  public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    pauseAutoScroll()
  }

  /// Restores page state and resumes auto-play when drag ends without deceleration.
  public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if !decelerate {
      let index = nearestVirtualIndex()
      syncCurrentPage(from: index)
      recenterIfNeeded(at: index)
      resumeAutoScroll()
    }
  }

  /// Finalizes logical page state after deceleration completes.
  public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    let index = nearestVirtualIndex()
    syncCurrentPage(from: index)
    recenterIfNeeded(at: index)
    resumeAutoScroll()
  }

  /// Finalizes logical page state after timer-driven animated scroll completes.
  public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
    let index = nearestVirtualIndex()
    syncCurrentPage(from: index)
    recenterIfNeeded(at: index)
  }
}
