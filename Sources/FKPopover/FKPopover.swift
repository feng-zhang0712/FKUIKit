//
// FKPopover.swift
//
// 组合控件：`FKBar` + `FKPresentation`，与系统 `UIPopoverPresentationController` 无关。
// 配置见 `Configuration`；`presentationContent` / `presentationViewController` 优先于 `dataSource`；
// `barDelegate` 与 `presentation*` 在内部处理之后额外转发。
//

import UIKit
import FKBar
import FKPresentation
import FKUIKitCore

// MARK: - Delegate / DataSource

/// 组合件级生命周期与展示门禁（细粒度动画/遮罩仍可用 `presentationDelegate` 接到 `FKPresentation`）。
public protocol FKPopoverDelegate: AnyObject {
  /// 某条目已选中，即将按配置尝试展示浮层；返回 `false` 可拦截。
  func popover(_ popover: FKPopover, shouldPresentFor item: FKBar.Item, at index: Int) -> Bool
  /// 浮层即将出现（`FKPresentation` 已走 `show` 流程）。
  func popover(_ popover: FKPopover, willPresentFor item: FKBar.Item, at index: Int)
  /// 浮层已出现。
  func popover(_ popover: FKPopover, didPresentFor item: FKBar.Item, at index: Int)
  /// 浮层即将消失（含点遮罩、改选、代码关闭等）。
  func popover(_ popover: FKPopover, willDismissPresentation reason: FKPopover.PresentationDismissReason)
  /// 浮层已消失。
  func popover(_ popover: FKPopover, didDismissPresentation reason: FKPopover.PresentationDismissReason)
}

public extension FKPopoverDelegate {
  func popover(_ popover: FKPopover, shouldPresentFor item: FKBar.Item, at index: Int) -> Bool { true }
  func popover(_ popover: FKPopover, willPresentFor item: FKBar.Item, at index: Int) {}
  func popover(_ popover: FKPopover, didPresentFor item: FKBar.Item, at index: Int) {}
  func popover(_ popover: FKPopover, willDismissPresentation reason: FKPopover.PresentationDismissReason) {}
  func popover(_ popover: FKPopover, didDismissPresentation reason: FKPopover.PresentationDismissReason) {}
}

/// 按条目提供浮层内容或首选尺寸；与闭包 `presentationContent` / `presentationViewController` 并存时闭包优先。
public protocol FKPopoverDataSource: AnyObject {
  /// 可选覆盖浮层首选尺寸。
  func popover(_ popover: FKPopover, preferredPresentationSizeForItemAt index: Int) -> CGSize?
  /// 返回浮层根视图；与 `presentationViewControllerForItemAt` 二选一即可。
  func popover(_ popover: FKPopover, presentationViewForItemAt index: Int) -> UIView?
  /// 返回嵌入浮层的视图控制器。
  func popover(_ popover: FKPopover, presentationViewControllerForItemAt index: Int) -> UIViewController?
}

public extension FKPopoverDataSource {
  func popover(_ popover: FKPopover, preferredPresentationSizeForItemAt index: Int) -> CGSize? { nil }
  func popover(_ popover: FKPopover, presentationViewForItemAt index: Int) -> UIView? { nil }
  func popover(_ popover: FKPopover, presentationViewControllerForItemAt index: Int) -> UIViewController? { nil }
}

// MARK: - FKPopover

/// 横向条与锚点浮层的组合；浮层关闭时若仍选中「本次展示对应条目」可按 `Configuration.behavior` 同步取消选中。
open class FKPopover: UIView {

  /// 横向条目条。
  public let bar: FKBar = {
    let b = FKBar(frame: .zero)
    b.translatesAutoresizingMaskIntoConstraints = false
    return b
  }()

  /// 底层浮层引擎；可改 `configuration`、或挂接 `delegate`/`dataSource`（与 `FKPopover` 侧转发并存）。
  public var panel: FKPresentation { embeddedPresentation }

  private let embeddedPresentation: FKPresentation

  public weak var delegate: FKPopoverDelegate?
  public weak var dataSource: FKPopoverDataSource?

  /// 额外接收 `FKBarDelegate` 回调（在 `FKPopover` 处理选中/浮层之后转发）。
  public weak var barDelegate: FKBarDelegate? {
    didSet { barProxy.forward = barDelegate }
  }

  /// 额外接收 `FKPresentationDelegate`（与 `FKPopoverDelegate` 并存）。
  public weak var presentationDelegate: FKPresentationDelegate? {
    didSet { panelDelegateProxy.forward = presentationDelegate }
  }

  /// 额外接收 `FKPresentationDataSource`（尺寸等；内容仍以 `show` 注入为准）。
  public weak var presentationDataSource: FKPresentationDataSource? {
    didSet { panelDataSourceProxy.forward = presentationDataSource }
  }

  /// 为某条目提供浮层 `UIView`；非 `nil` 时优先生效。
  public var presentationContent: ((FKPopover, Int, FKBar.Item) -> UIView?)?

  /// 为某条目提供浮层 `UIViewController`；若 `presentationContent` 已为非 `nil` 则不会调用。
  public var presentationViewController: ((FKPopover, Int, FKBar.Item) -> UIViewController?)?

  public var configuration: Configuration = .default {
    didSet { applyConfiguration(animated: false, completion: nil) }
  }

  private let barProxy = BarDelegateProxy()
  private let panelDelegateProxy = PanelDelegateProxy()
  private let panelDataSourceProxy = PanelDataSourceProxy()

  /// 当前展示所对应的条目上下文；无浮层时为 `nil`。
  public private(set) var presentationContext: (index: Int, item: FKBar.Item)?

  /// 浮层是否正在展示（透传 `FKPresentation.isPresented`）。
  public var isPresentationPresented: Bool { embeddedPresentation.isPresented }

  private var scheduledDismissReason: FKPopover.PresentationDismissReason?

  public override init(frame: CGRect) {
    embeddedPresentation = FKPresentation()
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    embeddedPresentation = FKPresentation()
    super.init(coder: coder)
    commonInit()
  }

  private func commonInit() {
    backgroundColor = .clear
    embeddedPresentation.delegate = panelDelegateProxy
    embeddedPresentation.dataSource = panelDataSourceProxy

    addSubview(bar)
    NSLayoutConstraint.activate([
      bar.topAnchor.constraint(equalTo: topAnchor),
      bar.leadingAnchor.constraint(equalTo: leadingAnchor),
      bar.trailingAnchor.constraint(equalTo: trailingAnchor),
      bar.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])

    barProxy.owner = self
    bar.delegate = barProxy

    panelDelegateProxy.owner = self
    panelDataSourceProxy.owner = self

    applyConfiguration(animated: false, completion: nil)
  }

  /// 将 `configuration.bar` / `configuration.presentation` 应用到子组件。
  public func applyConfiguration(animated: Bool = false, completion: VoidHandler? = nil) {
    bar.setConfiguration(configuration.bar, animated: animated, completion: completion)
    embeddedPresentation.configuration = configuration.presentation
  }

  /// 等价于 `bar.reloadItems`。
  public func reloadBarItems(_ items: [FKBar.Item], animated: Bool = false) {
    bar.reloadItems(items, animated: animated)
  }

  /// 关闭当前浮层（不影响 Bar 选中态）。
  public func dismissPresentation(animated: Bool = true, completion: VoidHandler? = nil) {
    guard embeddedPresentation.isPresented else {
      completion?()
      return
    }
    scheduledDismissReason = .programmatic
    embeddedPresentation.dismiss(animated: animated) {
      completion?()
    }
  }

  // MARK: - Internal（Bar 代理触发）

  fileprivate func onBarDidSelect(sender: UIView, item: FKBar.Item, at index: Int) {
    guard configuration.behavior.presentsOnSelection else { return }
    guard delegate?.popover(self, shouldPresentFor: item, at: index) ?? true else { return }

    if configuration.behavior.ignoresRepeatedSelectWhilePresented,
       embeddedPresentation.isPresented,
       presentationContext?.index == index {
      return
    }

    guard let host = configuration.presentationHost.resolve(from: self), host.bounds.width > 0 else {
      assertionFailure("FKPopover: 无法解析 presentationHost，请检查是否已加入视图层级或改用 `.explicit`。")
      return
    }

    if let view = presentationContent?(self, index, item) {
      presentPanel(content: .view(view), anchor: sender, item: item, at: index, in: host)
      return
    }
    if let vc = presentationViewController?(self, index, item) {
      presentPanel(content: .viewController(vc), anchor: sender, item: item, at: index, in: host)
      return
    }
    if let view = dataSource?.popover(self, presentationViewForItemAt: index) {
      presentPanel(content: .view(view), anchor: sender, item: item, at: index, in: host)
      return
    }
    if let vc = dataSource?.popover(self, presentationViewControllerForItemAt: index) {
      presentPanel(content: .viewController(vc), anchor: sender, item: item, at: index, in: host)
      return
    }
  }

  fileprivate func onBarDidDeselect(item: FKBar.Item, at index: Int) {
    let hasSelection = bar.loadedItems.contains(where: \.isSelected)

    if !hasSelection {
      guard configuration.behavior.dismissesWhenSelectionCleared else { return }
      guard embeddedPresentation.isPresented else { return }
      scheduledDismissReason = .selectionCleared
      embeddedPresentation.dismiss(animated: true, completion: nil)
      return
    }

    guard configuration.behavior.dismissBeforeChangingSelection else { return }
    guard embeddedPresentation.isPresented else { return }
    scheduledDismissReason = .selectionChanged
    embeddedPresentation.dismiss(animated: false, completion: nil)
  }

  private enum PresentContent {
    case view(UIView)
    case viewController(UIViewController)
  }

  private func presentPanel(
    content: PresentContent,
    anchor: UIView,
    item: FKBar.Item,
    at index: Int,
    in host: UIView
  ) {
    presentationContext = (index, item)

    switch content {
    case let .view(view):
      embeddedPresentation.show(from: anchor, sourceRect: nil, content: view, in: host, animated: true, completion: nil)
    case let .viewController(vc):
      embeddedPresentation.show(from: anchor, sourceRect: nil, content: vc, in: host, animated: true, completion: nil)
    }
  }

  fileprivate func dismissReasonForCallbacks() -> FKPopover.PresentationDismissReason {
    scheduledDismissReason ?? .maskTap
  }

  fileprivate func clearDismissSchedulingAfterCallbacks() {
    scheduledDismissReason = nil
  }

  fileprivate func clearPresentationContext() {
    presentationContext = nil
  }

  /// 浮层已关闭且并非「Bar 上已改选其他项」时，取消与本次浮层对应的条目选中并走 Bar 的完整重置（`deselectIndex` → 外观 / `prepare`）。
  fileprivate func synchronizeBarSelectionAfterPresentationDismissed() {
    guard let idx = presentationContext?.index else { return }
    // 仅当当前选中项仍是「弹出该浮层」的那一项时才取消选中，避免改选条目时误动新选中态。
    guard bar.selectedIndex == idx else { return }
    bar.deselectIndex(idx, animated: false, completion: nil)
  }
}

// MARK: - PresentationHost 解析

private extension FKPopover.Configuration.PresentationHost {
  @MainActor
  func resolve(from popover: FKPopover) -> UIView? {
    switch self {
    case .automatic:
      return popover.superview ?? popover.window
    case .superview:
      return popover.superview
    case .window:
      return popover.window
    case .explicit(let box):
      return box.view
    }
  }
}

// MARK: - Bar 代理多路转发

private final class BarDelegateProxy: FKBarDelegate {
  weak var owner: FKPopover?
  weak var forward: FKBarDelegate?

  func bar(_ bar: FKBar, shouldSelect item: FKBar.Item, at index: Int) -> Bool {
    forward?.bar(bar, shouldSelect: item, at: index) ?? true
  }

  func bar(
    _ bar: FKBar,
    willSelect incomingItem: FKBar.Item,
    at incomingIndex: Int,
    from currentItem: FKBar.Item,
    at currentIndex: Int
  ) {
    forward?.bar(bar, willSelect: incomingItem, at: incomingIndex, from: currentItem, at: currentIndex)
  }

  func bar(_ bar: FKBar, didSelect sender: UIView, for item: FKBar.Item, at index: Int) {
    forward?.bar(bar, didSelect: sender, for: item, at: index)
    owner?.onBarDidSelect(sender: sender, item: item, at: index)
  }

  func bar(_ bar: FKBar, didDeselect sender: UIView, for item: FKBar.Item, at index: Int) {
    forward?.bar(bar, didDeselect: sender, for: item, at: index)
    owner?.onBarDidDeselect(item: item, at: index)
  }

  func bar(_ bar: FKBar, shouldHighlight item: FKBar.Item, at index: Int) -> Bool {
    forward?.bar(bar, shouldHighlight: item, at: index) ?? true
  }

  func bar(_ bar: FKBar, prepare sender: UIView, for item: FKBar.Item, at index: Int) {
    forward?.bar(bar, prepare: sender, for: item, at: index)
  }

  func bar(_ bar: FKBar, didReloadItems items: [FKBar.Item]) {
    forward?.bar(bar, didReloadItems: items)
  }
}

// MARK: - FKPresentation Delegate 转发

private final class PanelDelegateProxy: FKPresentationDelegate {
  weak var owner: FKPopover?
  weak var forward: FKPresentationDelegate?

  func presentationWillPresent(_ presentation: FKPresentation) {
    guard let owner else {
      forward?.presentationWillPresent(presentation)
      return
    }
    if let ctx = owner.presentationContext {
      owner.delegate?.popover(owner, willPresentFor: ctx.item, at: ctx.index)
    }
    forward?.presentationWillPresent(presentation)
  }

  func presentationDidPresent(_ presentation: FKPresentation) {
    guard let owner else {
      forward?.presentationDidPresent(presentation)
      return
    }
    if let ctx = owner.presentationContext {
      owner.delegate?.popover(owner, didPresentFor: ctx.item, at: ctx.index)
    }
    forward?.presentationDidPresent(presentation)
  }

  func presentationShouldDismiss(_ presentation: FKPresentation) -> Bool {
    forward?.presentationShouldDismiss(presentation) ?? true
  }

  func presentationWillDismiss(_ presentation: FKPresentation) {
    guard let owner else {
      forward?.presentationWillDismiss(presentation)
      return
    }
    let r = owner.dismissReasonForCallbacks()
    owner.delegate?.popover(owner, willDismissPresentation: r)
    forward?.presentationWillDismiss(presentation)
  }

  func presentationDidDismiss(_ presentation: FKPresentation) {
    guard let owner else {
      forward?.presentationDidDismiss(presentation)
      return
    }
    owner.synchronizeBarSelectionAfterPresentationDismissed()
    let r = owner.dismissReasonForCallbacks()
    owner.delegate?.popover(owner, didDismissPresentation: r)
    owner.clearDismissSchedulingAfterCallbacks()
    owner.clearPresentationContext()
    forward?.presentationDidDismiss(presentation)
  }

  func presentation(_ presentation: FKPresentation, willRepositionTo rect: inout CGRect, in view: inout UIView) {
    forward?.presentation(presentation, willRepositionTo: &rect, in: &view)
  }
}

// MARK: - FKPresentation DataSource 转发

private final class PanelDataSourceProxy: FKPresentationDataSource {
  weak var owner: FKPopover?
  weak var forward: FKPresentationDataSource?

  func presentationPreferredSize(_ presentation: FKPresentation) -> CGSize? {
    if let owner, let idx = owner.presentationContext?.index {
      if let s = owner.dataSource?.popover(owner, preferredPresentationSizeForItemAt: idx) {
        return s
      }
    }
    return forward?.presentationPreferredSize(presentation)
  }

  func presentationContentView(_ presentation: FKPresentation) -> UIView? {
    forward?.presentationContentView(presentation)
  }
}
