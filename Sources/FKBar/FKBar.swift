//
// FKBar.swift
//
// 横向可滚动条目条：支持 `FKButton`、系统 `UIButton` 与自定义视图等条目模式。
//

import UIKit
import FKButton
import FKUIKitCore

// MARK: - Delegate

/// 条目选中、高亮与重建时的回调；默认实现为空或 `true`，按需覆写。
@MainActor
public protocol FKBarDelegate: AnyObject {
  /// 返回 `false` 可拦截即将发生的选中。
  func bar(_ bar: FKBar, shouldSelect item: FKBar.Item, at index: Int) -> Bool
  /// 选中即将变化时调用（仍可能发生后续取消）。
  func bar(_ bar: FKBar, willSelect incomingItem: FKBar.Item, at incomingIndex: Int, from currentItem: FKBar.Item, at currentIndex: Int)
  /// 选中已提交；`sender` 为条目对应可交互视图。
  func bar(_ bar: FKBar, didSelect sender: UIView, for item: FKBar.Item, at index: Int)
  func bar(_ bar: FKBar, didDeselect sender: UIView, for item: FKBar.Item, at index: Int)
  /// 是否允许对条目做高亮/准备外观；`prepare` 前会先询问。
  func bar(_ bar: FKBar, shouldHighlight item: FKBar.Item, at index: Int) -> Bool
  /// 在 `shouldHighlight` 为 `true` 时调用，用于统一刷新选中/常态外观。
  func bar(_ bar: FKBar, prepare sender: UIView, for item: FKBar.Item, at index: Int)
  /// `reloadItems` 完成后调用，参数为规范化后的条目数组（至多一个 `isSelected == true`）。
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

/// 内部使用 `UIScrollView` + `UIStackView` 承载条目；配置见 `Configuration` 关联属性。
open class FKBar: UIView {
  
  public weak var delegate: FKBarDelegate?
  
  /// 当前已由 `reloadItems` 加载的条目（只读快照）。
  public var loadedItems: [Item] { items }
  
  /// 当前选中条目的下标；无选中时为 `nil`（供 `FKPopover` 等组合组件判断选中态）。
  public private(set) var selectedIndex: Int?
  
  private let scrollView = UIScrollView()
  private let stackView = UIStackView()
  
  private var items: [Item] = []
  
  private var sourceViewsByIndex: [UIView] = []

  private var isHandlingSelection = false

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

    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.showsVerticalScrollIndicator = false
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.alwaysBounceVertical = false
    scrollView.alwaysBounceHorizontal = false
    addSubview(scrollView)

    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .horizontal
    stackView.alignment = .center
    stackView.distribution = .fill
    scrollView.addSubview(stackView)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: topAnchor),
      scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
      scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),

      // 横向：内容由 stackView 宽度决定；纵向：内容高度与可视区域一致（不纵向滚动），stack 在可视区内垂直居中。
      stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
      stackView.centerYAnchor.constraint(equalTo: scrollView.frameLayoutGuide.centerYAnchor),
      stackView.topAnchor.constraint(greaterThanOrEqualTo: scrollView.contentLayoutGuide.topAnchor),
      scrollView.contentLayoutGuide.bottomAnchor.constraint(greaterThanOrEqualTo: stackView.bottomAnchor),
      scrollView.contentLayoutGuide.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
    ])

    applyBarConfiguration(animated: false, completion: nil)
  }

  open override var intrinsicContentSize: CGSize {
    // 让外部在没有显式 height 约束时能拿到高度。
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

  // MARK: - Public API

  /// 用新数组替换当前条目并重建子视图；多个 `isSelected` 时仅保留第一个为选中。
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
  
  /// 以编程方式选中与 `id` 匹配的条目（会走与点击一致的选中逻辑与回调）。
  public func selectItem(_ item: Item, animated: Bool = true, completion: VoidHandler? = nil) {
    guard let idx = items.firstIndex(where: { $0.id == item.id }) else {
      completion?()
      return
    }
    selectIndex(idx, animated: animated, completion: completion)
  }
  
  /// 按 `id` 取消选中：仅当该条目当前为选中态时生效（与 `selectionBehavior` 无关）。
  public func deselectItem(_ item: Item, animated: Bool = true, completion: VoidHandler? = nil) {
    guard let idx = items.firstIndex(where: { $0.id == item.id }) else {
      completion?()
      return
    }
    deselectIndex(idx, animated: animated, completion: completion)
  }

  public func selectIndex(_ index: Int, animated: Bool = true, completion: VoidHandler? = nil) {
    guard index >= 0, index < items.count else {
      completion?()
      return
    }

    handleItemTap(at: index, sender: sourceViewsByIndex[safe: index], triggeredByTap: false, animated: animated)
    completion?()
  }

  /// 取消指定下标的选中态：仅当该下标当前为选中项时生效。
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
  
  /// 写入关联配置并应用；`animated` 与 `completion` 传给 `applyBarConfiguration`。
  public func setConfiguration(_ configuration: Configuration, animated: Bool = false, completion: (() -> Void)? = nil) {
    self.configuration = configuration
    applyBarConfiguration(animated: animated, completion: completion)
    invalidateIntrinsicContentSize()
  }
  
  // MARK: - Private
  
  // MARK: - Handle click

  /// 供 delegate / 外部调试获取条目对应的“源视图”（UIButton / FKButton / custom wrapper）。
  public func sourceView(forItemAt index: Int) -> UIView? {
    sourceViewsByIndex[safe: index]
  }

  /// 供 delegate 在 `didSelect` 中统一刷新视觉。
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

  private func makeView(for item: Item, at index: Int) -> UIView {
    // 先做无障碍（delegate 的 prepare 可能会覆盖，但不会伤害基础信息）。
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
    // 本轮 bar 只声明性的把宽高类约束应用到条目外层 wrapper/控件；
    // wrapperInsets 只用于 custom wrapper 内部布局。
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

  private func updateSelectionAppearance(selectedIndex: Int? = nil) {
    for idx in items.indices {
      let item = items[idx]
      guard let sender = sourceViewsByIndex[safe: idx] else { continue }

      sender.isUserInteractionEnabled = item.isEnabled

      // If the sender is a control, use UIKit state so FKButton / UIButton can reflect automatically.
      if let control = sender as? UIControl {
        control.isSelected = item.isSelected
        control.isEnabled = item.isEnabled

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
        }
      } else {
        // For pure UIView wrapper: delegate prepare will handle alpha/background if needed.
        sender.alpha = item.isEnabled ? (item.isSelected ? 1.0 : 0.88) : 0.45
      }
    }
  }

  private func handleItemTap(
    at index: Int,
    sender: UIView?,
    triggeredByTap: Bool,
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

  /// 提交 `proposed` 选中态并走与点击一致的回调链（`actionHandler` → delegate 门禁 → 应用状态 → `didDeselect`/`didSelect` → 滚动）。
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

      // 先回调 deselect（如果选中项变化了）。
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

      // 再回调 select（仅当“点击项最终处于 selected”）。
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
    let maxX = scrollView.contentSize.width - scrollView.bounds.width + insets.right
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
      triggeredByTap: true,
      animated: true
    )
  }

  @objc private func handleCustomViewTap(_ recognizer: UITapGestureRecognizer) {
    guard let view = recognizer.view else { return }
    let index = view.tag
    handleItemTap(
      at: index,
      sender: view,
      triggeredByTap: true,
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
