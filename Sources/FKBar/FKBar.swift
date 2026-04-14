//
// FKBar.swift
//
// Horizontal scrollable item bar supporting `FKButton`, system `UIButton`, and custom item views.
//

import UIKit
import FKButton
import FKUIKitCore

// MARK: - Delegate

/// Callbacks for item selection, highlighting, and rebuilding.
/// Default implementations are empty or return `true` (override as needed).
@MainActor
public protocol FKBarDelegate: AnyObject {
  /// Return `false` to intercept an imminent selection.
  func bar(_ bar: FKBar, shouldSelect item: FKBar.Item, at index: Int) -> Bool
  /// Called when selection is about to change (may be canceled later).
  func bar(_ bar: FKBar, willSelect incomingItem: FKBar.Item, at incomingIndex: Int, from currentItem: FKBar.Item, at currentIndex: Int)
  /// Called after selection is committed.
  /// `sender` is the interactive view for the selected item.
  func bar(_ bar: FKBar, didSelect sender: UIView, for item: FKBar.Item, at index: Int)
  func bar(_ bar: FKBar, didDeselect sender: UIView, for item: FKBar.Item, at index: Int)
  /// Whether to allow highlighting / appearance preparation for an item.
  /// `prepare` is called only when `shouldHighlight` returns `true`.
  func bar(_ bar: FKBar, shouldHighlight item: FKBar.Item, at index: Int) -> Bool
  /// Called when `shouldHighlight` is `true` to refresh selected/normal appearances consistently.
  func bar(_ bar: FKBar, prepare sender: UIView, for item: FKBar.Item, at index: Int)
  /// Called after `reloadItems` completes.
  /// The parameter is the normalized item array (at most one `isSelected == true`).
  func bar(_ bar: FKBar, didReloadItems items: [FKBar.Item])
}

public extension FKBarDelegate {
  func bar(_ bar: FKBar, shouldSelect item: FKBar.Item, at index: Int) -> Bool { true }
  func bar(_ bar: FKBar, willSelect incomingItem: FKBar.Item, at incomingIndex: Int, from currentItem: FKBar.Item, at currentIndex: Int) {}
  func bar(_ bar: FKBar, didSelect sender: UIView, for item: FKBar.Item, at index: Int) {}
  func bar(_ bar: FKBar, didDeselect sender: UIView, for item: FKBar.Item, at index: Int) {}
  func bar(_ bar: FKBar, shouldHighlight item: FKBar.Item, at index: Int) -> Bool { true }
  func bar(_ bar: FKBar, prepare sender: UIView, for item: FKBar.Item, at index: Int) {}
  func bar(_ bar: FKBar, didReloadItems items: [FKBar.Item]) {}
}

// MARK: - Bar

/// Uses `UIScrollView` + `UIStackView` internally to host items.
/// Configuration is available via `Configuration`.
open class FKBar: UIView {
  
  public weak var delegate: FKBarDelegate?
  
  /// Items loaded by `reloadItems` (read-only snapshot).
  public var loadedItems: [Item] { items }
  
  /// The index of the currently selected item, or `nil` when none is selected.
  /// Useful for composite components like `FKBarPresentation`.
  public private(set) var selectedIndex: Int?
  
  private let scrollView = UIScrollView()
  private let stackView = UIStackView()
  // Internal bridge for same-module extensions (not public API).
  var _configurationScrollView: UIScrollView { scrollView }
  var _configurationStackView: UIStackView { stackView }
  
  private var items: [Item] = []
  
  private var sourceViewsByIndex: [UIView] = []

  private var isHandlingSelection = false

  /// Horizontal constraints between `scrollView.contentLayoutGuide` and `stackView` (swapped by ``Configuration/Arrangement``).
  private var horizontalLayoutConstraints: [NSLayoutConstraint] = []

  /// Cached overflow state for layouts that switch between “fill viewport” and “scroll intrinsic width”.
  private var lastHorizontalLayoutOverflowState: Bool?
  /// Last laid out bounds size; used to detect rotation/size-class width changes.
  private var lastLaidOutBoundsSize: CGSize = .zero

  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  private func commonInit() {
    backgroundColor = .clear

    scrollView.alwaysBounceVertical = false
    scrollView.alwaysBounceHorizontal = false
    scrollView.showsVerticalScrollIndicator = false
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(scrollView)

    stackView.axis = .horizontal
    stackView.alignment = .center
    stackView.distribution = .fill
    stackView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(stackView)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: topAnchor),
      scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
      scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),

      // Vertical: content height follows the visible area (no vertical scrolling),
      // and `stackView` is centered vertically within the visible area.
      // Horizontal constraints are installed by `applyArrangementFromConfiguration()`.
      stackView.centerYAnchor.constraint(equalTo: scrollView.frameLayoutGuide.centerYAnchor),
      stackView.topAnchor.constraint(greaterThanOrEqualTo: scrollView.contentLayoutGuide.topAnchor),
      stackView.bottomAnchor.constraint(lessThanOrEqualTo: scrollView.contentLayoutGuide.bottomAnchor),
    ])

    applyBarConfiguration(animated: false, completion: nil)
  }

  open override func layoutSubviews() {
    super.layoutSubviews()
    updateBarShadowPathIfNeeded()

    let currentSize = bounds.size
    let sizeDidChange = currentSize != .zero && currentSize != lastLaidOutBoundsSize
    lastLaidOutBoundsSize = currentSize

    guard scrollView.bounds.width > 0, !sourceViewsByIndex.isEmpty else { return }

    if configuration.arrangement != .leading {
      let overflows = resolvedContentOverflowsViewport()
      if lastHorizontalLayoutOverflowState != overflows {
        rebuildHorizontalLayoutConstraints(invalidateIntrinsic: true)
      }
    }

    // Keep the selected item aligned after rotations / size changes.
    // This avoids carrying stale contentOffset into the new geometry.
    if sizeDidChange {
      scrollToSelectedIndexIfNeeded(animated: false)
    }
  }

  open override var intrinsicContentSize: CGSize {
    // Provide a height even when there is no explicit height constraint.
    let width: CGFloat
    if bounds.width > 0 {
      width = bounds.width
    } else if let w = window?.windowScene?.screen.bounds.width, w > 0 {
      width = w
    } else if let w = superview?.bounds.width, w > 0 {
      width = w
    } else {
      width = 375
    }

    let fitted = stackView.systemLayoutSizeFitting(
      CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .fittingSizeLevel
    )
    return CGSize(width: UIView.noIntrinsicMetric, height: fitted.height)
  }

  // MARK: - Public

  /// Replace current items with a new array and rebuild subviews.
  /// When multiple items are marked `isSelected`, only the first one is kept as selected.
  public func reloadItems(_ items: [Item], animated: Bool = false) {
    isHandlingSelection = true
    defer { isHandlingSelection = false }

    let incomingSelectedIndex = items.firstIndex(where: { $0.isSelected })
    let normalized = items.enumerated().map { idx, item in
      var m = item
      m.isSelected = (idx == incomingSelectedIndex)
      return m
    }

    self.items = normalized
    selectedIndex = incomingSelectedIndex

    sourceViewsByIndex.removeAll(keepingCapacity: true)
    stackView.arrangedSubviews.forEach { view in
      stackView.removeArrangedSubview(view)
      view.removeFromSuperview()
    }

    for (index, item) in normalized.enumerated() {
      let view = makeView(for: item, at: index)
      sourceViewsByIndex.append(view)
      stackView.addArrangedSubview(view)
    }

    applyBarConfiguration(animated: false, completion: nil)

    updateSelectionAppearance()
    refreshPreparedAppearance()

    if animated {
      UIView.animate(withDuration: 0.25) { self.layoutIfNeeded() }
    } else {
      layoutIfNeeded()
    }

    invalidateIntrinsicContentSize()

    delegate?.bar(self, didReloadItems: normalized)
  }
  
  /// Programmatically select the item whose `id` matches.
  /// This uses the same selection logic and callbacks as a tap.
  public func selectItem(_ item: Item, animated: Bool = true, completion: VoidHandler? = nil) {
    guard let idx = items.firstIndex(where: { $0.id == item.id }) else {
      completion?()
      return
    }
    selectIndex(idx, animated: animated, completion: completion)
  }
  
  public func selectIndex(_ index: Int, animated: Bool = true, completion: VoidHandler? = nil) {
    guard index >= 0, index < items.count else {
      completion?()
      return
    }

    handleItemTap(at: index, sender: sourceViewsByIndex[safe: index], animated: animated)
    completion?()
  }
  
  /// Deselect by `id`.
  /// Effective only when the item is currently selected (independent of `selectionBehavior`).
  public func deselectItem(_ item: Item, animated: Bool = true, completion: VoidHandler? = nil) {
    guard let idx = items.firstIndex(where: { $0.id == item.id }) else {
      completion?()
      return
    }
    deselectIndex(idx, animated: animated, completion: completion)
  }

  /// Deselect a given index.
  /// Effective only when that index is currently selected.
  public func deselectIndex(_ index: Int, animated: Bool = true, completion: VoidHandler? = nil) {
    guard index >= 0, index < items.count else {
      completion?()
      return
    }
    guard items[index].isSelected else {
      completion?()
      return
    }
    guard items[index].isEnabled else {
      completion?()
      return
    }
    guard let sender = sourceViewsByIndex[safe: index] else {
      completion?()
      return
    }

    var proposed = items[index]
    proposed.isSelected = false
    commitProposedSelection(at: index, proposed: proposed, sender: sender, animated: animated)
    completion?()
  }
  
  /// Stores and applies associated configuration.
  /// `animated` and `completion` are forwarded to `applyBarConfiguration`.
  public func setConfiguration(_ configuration: Configuration, animated: Bool = false, completion: (() -> Void)? = nil) {
    setStoredConfiguration(configuration)
    applyBarConfiguration(animated: animated, completion: completion)
    invalidateIntrinsicContentSize()
  }
  
  /// Returns the "source view" for a given item.
  /// (e.g. `UIButton`, `FKButton`, or a custom wrapper).
  public func sourceView(forItemAt index: Int) -> UIView? {
    sourceViewsByIndex[safe: index]
  }

  /// Invoked by delegates to refresh visuals after `didSelect`.
  public func refreshPreparedAppearance() {
    guard let delegate else { return }
    for (idx, item) in items.enumerated() {
      guard let sender = sourceViewsByIndex[safe: idx] else { continue }
      let should = delegate.bar(self, shouldHighlight: item, at: idx)
      if should {
        delegate.bar(self, prepare: sender, for: item, at: idx)
      }
    }
  }
  
  // MARK: - Horizontal layout (configuration-driven)

  /// Applies `configuration.arrangement` and related `UIStackView.distribution` rules.
  /// Called from `applyBarConfiguration`.
  internal func applyArrangementFromConfiguration() {
    stackView.spacing = configuration.itemSpacing
    stackView.alignment = configuration.alignment
    rebuildHorizontalLayoutConstraints(invalidateIntrinsic: true)
  }

  private func rebuildHorizontalLayoutConstraints(invalidateIntrinsic: Bool) {
    NSLayoutConstraint.deactivate(horizontalLayoutConstraints)
    horizontalLayoutConstraints.removeAll(keepingCapacity: true)

    let mode = configuration.arrangement
    let overflows: Bool = {
      switch mode {
      case .leading:
        return false
      case .center, .trailing, .between, .around, .evenlyDistributed:
        return resolvedContentOverflowsViewport()
      }
    }()

    switch mode {
    case .leading:
      stackView.distribution = configuration.distribution
      horizontalLayoutConstraints = makeLeadingPinnedToContentWidthConstraints()

    case .center:
      if overflows {
        stackView.distribution = configuration.distribution
        horizontalLayoutConstraints = makeLeadingPinnedToContentWidthConstraints()
      } else {
        stackView.distribution = .fill
        horizontalLayoutConstraints = makeCenteredGroupConstraints()
      }

    case .trailing:
      if overflows {
        stackView.distribution = configuration.distribution
        horizontalLayoutConstraints = makeLeadingPinnedToContentWidthConstraints()
      } else {
        stackView.distribution = .fill
        horizontalLayoutConstraints = makeTrailingGroupConstraints()
      }

    case .between:
      if overflows {
        stackView.distribution = configuration.distribution
        horizontalLayoutConstraints = makeLeadingPinnedToContentWidthConstraints()
      } else {
        stackView.distribution = .equalSpacing
        horizontalLayoutConstraints = makeDistributedFillViewportConstraints()
      }

    case .around:
      if overflows {
        stackView.distribution = configuration.distribution
        horizontalLayoutConstraints = makeLeadingPinnedToContentWidthConstraints()
      } else {
        stackView.distribution = .equalCentering
        horizontalLayoutConstraints = makeDistributedFillViewportConstraints()
      }

    case .evenlyDistributed:
      if overflows {
        stackView.distribution = configuration.distribution
        horizontalLayoutConstraints = makeLeadingPinnedToContentWidthConstraints()
      } else {
        stackView.distribution = .fillEqually
        horizontalLayoutConstraints = makeDistributedFillViewportConstraints()
      }
    }

    NSLayoutConstraint.activate(horizontalLayoutConstraints)

    switch mode {
    case .leading:
      lastHorizontalLayoutOverflowState = nil
    default:
      lastHorizontalLayoutOverflowState = overflows
    }

    if invalidateIntrinsic {
      invalidateIntrinsicContentSize()
    }
  }

  private func makeLeadingPinnedToContentWidthConstraints() -> [NSLayoutConstraint] {
    [
      stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
    ]
  }

  private func makeCenteredGroupConstraints() -> [NSLayoutConstraint] {
    [
      stackView.centerXAnchor.constraint(equalTo: scrollView.contentLayoutGuide.centerXAnchor),
      stackView.leadingAnchor.constraint(greaterThanOrEqualTo: scrollView.contentLayoutGuide.leadingAnchor),
      stackView.trailingAnchor.constraint(lessThanOrEqualTo: scrollView.contentLayoutGuide.trailingAnchor),
      scrollView.contentLayoutGuide.widthAnchor.constraint(greaterThanOrEqualTo: scrollView.frameLayoutGuide.widthAnchor),
      scrollView.contentLayoutGuide.widthAnchor.constraint(greaterThanOrEqualTo: stackView.widthAnchor),
    ]
  }

  private func makeTrailingGroupConstraints() -> [NSLayoutConstraint] {
    [
      stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
      stackView.leadingAnchor.constraint(greaterThanOrEqualTo: scrollView.contentLayoutGuide.leadingAnchor),
      scrollView.contentLayoutGuide.widthAnchor.constraint(greaterThanOrEqualTo: scrollView.frameLayoutGuide.widthAnchor),
      scrollView.contentLayoutGuide.widthAnchor.constraint(greaterThanOrEqualTo: stackView.widthAnchor),
    ]
  }

  private func makeDistributedFillViewportConstraints() -> [NSLayoutConstraint] {
    [
      stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
      scrollView.contentLayoutGuide.widthAnchor.constraint(greaterThanOrEqualTo: scrollView.frameLayoutGuide.widthAnchor),
    ]
  }

  private func horizontalScrollContentInsetWidth() -> CGFloat {
    let isRTL = UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .rightToLeft
    let inset = configuration.contentInsets
    let left = isRTL ? inset.trailing : inset.leading
    let right = isRTL ? inset.leading : inset.trailing
    return CGFloat(left + right)
  }

  private func resolvedContentOverflowsViewport() -> Bool {
    guard !sourceViewsByIndex.isEmpty else { return false }

    let insetWidth = horizontalScrollContentInsetWidth()
    let viewport = scrollView.bounds.width - insetWidth
    let contentW = estimatedBarContentWidth()

    if viewport > 1 {
      return contentW > viewport + 0.5
    }

    if bounds.width > 0 {
      let outerViewport = bounds.width - insetWidth
      return outerViewport > 1 && contentW > outerViewport + 0.5
    }

    return false
  }

  /// Sum of item widths plus inter-item spacing (cheap; uses post-layout bounds when available).
  private func estimatedBarContentWidth() -> CGFloat {
    guard !sourceViewsByIndex.isEmpty else { return 0 }
    var total: CGFloat = 0
    for v in sourceViewsByIndex {
      let w: CGFloat
      if v.bounds.width > 0.5 {
        w = v.bounds.width
      } else {
        w = v.systemLayoutSizeFitting(
          CGSize(width: UIView.layoutFittingCompressedSize.width, height: stackView.bounds.height > 0 ? stackView.bounds.height : 44),
          withHorizontalFittingPriority: .fittingSizeLevel,
          verticalFittingPriority: .required
        ).width
      }
      total += w
    }
    total += CGFloat(max(0, sourceViewsByIndex.count - 1)) * stackView.spacing
    return total
  }

  // MARK: - Private

  private func makeView(for item: Item, at index: Int) -> UIView {
    // Setup accessibility first (delegate's prepare may override, but base info stays intact).
    func applyAccessibility(_ view: UIView) {
      if let label = item.accessibilityLabel { view.accessibilityLabel = label }
      if let hint = item.accessibilityHint { view.accessibilityHint = hint }
      if let id = item.accessibilityIdentifier { view.accessibilityIdentifier = id }
    }

    switch item.mode {
    case let .fkButton(spec):
      let button = FKButton()
      spec.apply(to: button)
      button.tag = index
      button.isSelected = item.isSelected
      button.isEnabled = item.isEnabled
      button.addTarget(self, action: #selector(handleItemControlTap(_:)), for: .touchUpInside)
      applyLayoutConstraints(from: item.layout, to: button)
      applyAccessibility(button)
      return button

    case let .button(configuration):
      let button = UIButton(type: .system)
      button.configuration = configuration
      button.tag = index
      button.isSelected = item.isSelected
      button.isEnabled = item.isEnabled
      button.addTarget(self, action: #selector(handleItemControlTap(_:)), for: .touchUpInside)
      applyLayoutConstraints(from: item.layout, to: button)
      applyAccessibility(button)
      return button

    case let .customView(custom):
      let wrapper = CustomViewWrapperView(hitTestInsets: item.layout.hitTestInsets)
      wrapper.tag = index
      wrapper.embed(
        custom,
        wrapperInsets: item.layout.wrapperInsets,
        isRTL: isRTL
      )
      applyLayoutConstraints(from: item.layout, to: wrapper)
      applyAccessibility(wrapper)

      wrapper.addGestureRecognizer(
        UITapGestureRecognizer(target: self, action: #selector(handleCustomViewTap(_:)))
      )
      return wrapper
    }
  }

  private var isRTL: Bool {
    UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .rightToLeft
  }

  private func applyLayoutConstraints(from layout: Item.Layout, to view: UIView) {
    // This bar applies fixed-size constraints to the item wrapper/control.
    // `wrapperInsets` is used only inside the custom wrapper layout.
    if let fixedWidth = layout.fixedWidth {
      view.widthAnchor.constraint(equalToConstant: fixedWidth).isActive = true
    }
    if let fixedHeight = layout.fixedHeight {
      view.heightAnchor.constraint(equalToConstant: fixedHeight).isActive = true
    }
    if let minWidth = layout.minWidth {
      view.widthAnchor.constraint(greaterThanOrEqualToConstant: minWidth).isActive = true
    }
    if let maxWidth = layout.maxWidth {
      view.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth).isActive = true
    }
    if let minHeight = layout.minHeight {
      view.heightAnchor.constraint(greaterThanOrEqualToConstant: minHeight).isActive = true
    }
    if let maxHeight = layout.maxHeight {
      view.heightAnchor.constraint(lessThanOrEqualToConstant: maxHeight).isActive = true
    }
  }

  private func updateSelectionAppearance() {
    let usesDefaultSelectionAppearance = configuration.usesDefaultSelectionAppearance

    for idx in items.indices {
      let item = items[idx]
      guard let sender = sourceViewsByIndex[safe: idx] else { continue }

      sender.isUserInteractionEnabled = item.isEnabled

      // If the sender is a control, use UIKit state so FKButton / UIButton can reflect automatically.
      if let control = sender as? UIControl {
        control.isSelected = item.isSelected
        control.isEnabled = item.isEnabled
      }

      guard usesDefaultSelectionAppearance else { continue }
      applyDefaultSelectionAppearance(to: sender, item: item)
    }
  }

  private func applyDefaultSelectionAppearance(to sender: UIView, item: Item) {
    if let uiButton = sender as? UIButton,
       var cfg = uiButton.configuration {
      // Fallback visual when delegate.prepare is not provided:
      // selected uses a soft blue background, and disabled reduces alpha.
      cfg.background.backgroundColor = item.isSelected
        ? UIColor.systemBlue.withAlphaComponent(0.16)
        : .clear
      cfg.baseForegroundColor = item.isEnabled ? .label : .secondaryLabel
      uiButton.configuration = cfg
      uiButton.alpha = item.isEnabled ? 1.0 : 0.45
      return
    }

    // Covers FKButton and custom wrappers consistently.
    sender.alpha = item.isEnabled ? (item.isSelected ? 1.0 : 0.88) : 0.45
    if !(sender is UIControl) {
      sender.backgroundColor = item.isSelected
        ? UIColor.systemBlue.withAlphaComponent(0.12)
        : .clear
    }
  }

  // MARK: - Handle click

  private func handleItemTap(
    at index: Int,
    sender: UIView?,
    animated: Bool
  ) {
    guard !isHandlingSelection else { return }
    guard index >= 0, index < items.count else { return }
    guard items[index].isEnabled else { return }
    guard let sender else { return }

    let tappedItem = items[index]

    // Compute proposed selection after this tap.
    let proposed: Item = {
      if !tappedItem.isSelected {
        var m = tappedItem
        m.isSelected = true
        return m
      }

      switch tappedItem.selectionBehavior {
      case .toggle:
        var m = tappedItem
        m.isSelected = false
        return m
      case .alwaysSelect:
        return tappedItem
      case .none:
        return tappedItem
      }
    }()

    commitProposedSelection(at: index, proposed: proposed, sender: sender, animated: animated)
  }

  /// Commit the proposed selection state and run the same callback chain as a tap
  /// (`actionHandler` → delegate gate → apply state → `didDeselect`/`didSelect` → scroll).
  private func commitProposedSelection(at index: Int, proposed: Item, sender: UIView, animated: Bool) {
    let tappedItem = items[index]
    let previousSelectedIndex = selectedIndex

    // 1) Action handler first (matches demo comment).
    if let handler = tappedItem.actionHandler {
      handler(proposed)
    }

    // 2) Delegate gatekeeping.
    if let delegate {
      _ = delegate.bar(self, shouldHighlight: proposed, at: index)
      let shouldSelect = delegate.bar(self, shouldSelect: proposed, at: index)
      if !shouldSelect { return }

      let currentIndex = selectedIndex
      let currentItem = currentIndex.flatMap { items[safe: $0] } ?? tappedItem
      delegate.bar(
        self,
        willSelect: proposed,
        at: index,
        from: currentItem,
        at: currentIndex ?? -1
      )
    }

    // 3) Apply selection state (single selected at most).
    applySelection(withProposed: proposed, at: index)

    // 4) Visual prepare.
    updateSelectionAppearance()
    refreshPreparedAppearance()

    // 5) Delegate notification.
    if let delegate {
      let newSelectedIndex = selectedIndex

      // Call didDeselect first (if the selected item changes).
      if let prevIndex = previousSelectedIndex, prevIndex != newSelectedIndex {
        if let prevSender = sourceViewsByIndex[safe: prevIndex] {
          delegate.bar(
            self,
            didDeselect: prevSender,
            for: items[prevIndex],
            at: prevIndex
          )
        }
      }

      // Then call didSelect (only when the tapped item ends up being selected).
      if items[index].isSelected {
        delegate.bar(self, didSelect: sender, for: items[index], at: index)
      }
    }

    // 6) Scroll after selection.
    scrollToSelectedIndexIfNeeded(animated: animated)
  }

  private func applySelection(withProposed proposed: Item, at index: Int) {
    if proposed.isSelected {
      for idx in items.indices {
        items[idx].isSelected = (idx == index)
      }
      selectedIndex = index
    } else {
      for idx in items.indices {
        items[idx].isSelected = false
      }
      selectedIndex = nil
    }
  }

  private func scrollToSelectedIndexIfNeeded(animated: Bool) {
    guard let selectedIndex else { return }
    guard configuration.selectionScroll.isEnabled else { return }
    // Keep the row visually fixed when all items already fit in the visible bar.
    // Auto-scroll should only happen in true overflow scenarios.
    guard resolvedContentOverflowsViewport() else {
      let preserveY = scrollView.contentOffset.y
      let resetX = -scrollView.contentInset.left
      let current = scrollView.contentOffset
      guard abs(current.x - resetX) > 0.5 else { return }

      let duration = configuration.selectionScroll.animation.duration
      if animated, duration > 0 {
        UIView.animate(withDuration: duration) {
          self.scrollView.contentOffset = CGPoint(x: resetX, y: preserveY)
        }
      } else {
        scrollView.contentOffset = CGPoint(x: resetX, y: preserveY)
      }
      return
    }

    guard let targetView = sourceViewsByIndex[safe: selectedIndex] else { return }
    layoutIfNeeded()

    let targetRect = targetView.convert(targetView.bounds, to: scrollView)
    let insets = scrollView.contentInset

    let alignment = items[selectedIndex].layout.scrollAlignment
    let xOffset: CGFloat = {
      switch alignment {
      case .leading:
        return targetRect.minX - insets.left
      case .center:
        return targetRect.midX - scrollView.bounds.width / 2
      case .trailing:
        return targetRect.maxX - scrollView.bounds.width + insets.right
      }
    }()

    let minX = -insets.left
    let maxX = max(minX, scrollView.contentSize.width - scrollView.bounds.width + insets.right)
    let clamped = min(max(xOffset, minX), maxX)

    let duration = configuration.selectionScroll.animation.duration
    let preserveY = scrollView.contentOffset.y
    if animated, duration > 0 {
      UIView.animate(withDuration: duration) {
        self.scrollView.contentOffset = CGPoint(x: clamped, y: preserveY)
      }
    } else {
      scrollView.contentOffset = CGPoint(x: clamped, y: preserveY)
    }
  }

  @objc private func handleItemControlTap(_ sender: UIControl) {
    let index = sender.tag
    handleItemTap(
      at: index,
      sender: sender,
      animated: true
    )
  }

  @objc private func handleCustomViewTap(_ recognizer: UITapGestureRecognizer) {
    guard let view = recognizer.view else { return }
    let index = view.tag
    handleItemTap(
      at: index,
      sender: view,
      animated: true
    )
  }

  // MARK: - Custom view wrapper

  private final class CustomViewWrapperView: UIView {
    private let hitTestInsets: UIEdgeInsets

    init(hitTestInsets: UIEdgeInsets) {
      self.hitTestInsets = hitTestInsets
      super.init(frame: .zero)
      isOpaque = false
      backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
      self.hitTestInsets = .zero
      super.init(coder: coder)
      isOpaque = false
      backgroundColor = .clear
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
      guard hitTestInsets != .zero else { return super.point(inside: point, with: event) }
      let expanded = bounds.inset(by: UIEdgeInsets(
        top: -hitTestInsets.top,
        left: -hitTestInsets.left,
        bottom: -hitTestInsets.bottom,
        right: -hitTestInsets.right
      ))
      return expanded.contains(point)
    }

    func embed(_ content: UIView, wrapperInsets: NSDirectionalEdgeInsets, isRTL: Bool) {
      content.translatesAutoresizingMaskIntoConstraints = false
      addSubview(content)

      let leading = isRTL ? wrapperInsets.trailing : wrapperInsets.leading
      let trailing = isRTL ? wrapperInsets.leading : wrapperInsets.trailing

      NSLayoutConstraint.activate([
        content.topAnchor.constraint(equalTo: topAnchor, constant: wrapperInsets.top),
        content.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -wrapperInsets.bottom),
        content.leadingAnchor.constraint(equalTo: leadingAnchor, constant: leading),
        content.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -trailing),
      ])
    }
  }
}

private extension Array {
  subscript(safe index: Int) -> Element? {
    guard indices.contains(index) else { return nil }
    return self[index]
  }
}
