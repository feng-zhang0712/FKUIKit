//
// FKBarPresentation.swift
//
// Composite component: `FKBar` + `FKPresentation`.
// See `Configuration` for settings.
// `presentationContent` / `presentationViewController` take precedence over `dataSource`.
// `barDelegate` and `presentation*` callbacks are forwarded after internal handling.
//

import UIKit
import FKBar
import FKPresentation
import FKUIKitCore

// MARK: - Delegate / DataSource

/// Composite-level lifecycle callbacks and presentation gating.
/// For fine-grained animation/mask callbacks, use `presentationDelegate` (from `FKPresentation`).
public protocol FKBarPresentationDelegate: AnyObject {
  /// Called when an item is selected and the panel is about to be presented.
  /// Return `false` to prevent presentation.
  func barPresentation(_ barPresentation: FKBarPresentation, shouldPresentFor item: FKBar.Item, at index: Int) -> Bool
  /// The panel is about to appear (`FKPresentation.show` has been triggered).
  func barPresentation(_ barPresentation: FKBarPresentation, willPresentFor item: FKBar.Item, at index: Int)
  /// The panel has appeared.
  func barPresentation(_ barPresentation: FKBarPresentation, didPresentFor item: FKBar.Item, at index: Int)
  /// The panel is about to be dismissed (mask tap, selection change, programmatic dismiss, etc.).
  func barPresentation(_ barPresentation: FKBarPresentation, willDismissPresentation reason: FKBarPresentation.PresentationDismissReason)
  /// The panel has been dismissed.
  func barPresentation(_ barPresentation: FKBarPresentation, didDismissPresentation reason: FKBarPresentation.PresentationDismissReason)
}

public extension FKBarPresentationDelegate {
  func barPresentation(_ barPresentation: FKBarPresentation, shouldPresentFor item: FKBar.Item, at index: Int) -> Bool { true }
  func barPresentation(_ barPresentation: FKBarPresentation, willPresentFor item: FKBar.Item, at index: Int) {}
  func barPresentation(_ barPresentation: FKBarPresentation, didPresentFor item: FKBar.Item, at index: Int) {}
  func barPresentation(_ barPresentation: FKBarPresentation, willDismissPresentation reason: FKBarPresentation.PresentationDismissReason) {}
  func barPresentation(_ barPresentation: FKBarPresentation, didDismissPresentation reason: FKBarPresentation.PresentationDismissReason) {}
}

/// Provides panel content / preferred size per item.
/// When both are present, closures `presentationContent` / `presentationViewController` take precedence over `dataSource`.
public protocol FKBarPresentationDataSource: AnyObject {
  /// Optionally override the preferred size.
  func barPresentation(_ barPresentation: FKBarPresentation, preferredPresentationSizeForItemAt index: Int) -> CGSize?
  /// Return the content root view. Provide either this or `presentationViewControllerForItemAt`.
  func barPresentation(_ barPresentation: FKBarPresentation, presentationViewForItemAt index: Int) -> UIView?
  /// Return the embedded content view controller.
  func barPresentation(_ barPresentation: FKBarPresentation, presentationViewControllerForItemAt index: Int) -> UIViewController?
}

public extension FKBarPresentationDataSource {
  func barPresentation(_ barPresentation: FKBarPresentation, preferredPresentationSizeForItemAt index: Int) -> CGSize? { nil }
  func barPresentation(_ barPresentation: FKBarPresentation, presentationViewForItemAt index: Int) -> UIView? { nil }
  func barPresentation(_ barPresentation: FKBarPresentation, presentationViewControllerForItemAt index: Int) -> UIViewController? { nil }
}

// MARK: - FKBarPresentation

/// A `FKBar` + anchored panel composite.
/// When the panel is dismissed, it may synchronize the bar selection according to `Configuration.behavior`.
open class FKBarPresentation: UIView {

  /// The bar.
  public let bar: FKBar = {
    let b = FKBar(frame: .zero)
    b.translatesAutoresizingMaskIntoConstraints = false
    return b
  }()

  /// Underlying panel engine. You may set its `configuration` or attach its `delegate` / `dataSource`.
  public var panel: FKPresentation { embeddedPresentation }

  private let embeddedPresentation: FKPresentation

  public weak var delegate: FKBarPresentationDelegate?
  public weak var dataSource: FKBarPresentationDataSource?

  /// An additional `FKBarDelegate` receiver (forwarded after `FKBarPresentation` internal handling).
  public weak var barDelegate: FKBarDelegate? {
    didSet { barProxy.forward = barDelegate }
  }

  /// An additional `FKPresentationDelegate` receiver (coexists with `FKBarPresentationDelegate`).
  public weak var presentationDelegate: FKPresentationDelegate? {
    didSet { panelDelegateProxy.forward = presentationDelegate }
  }

  /// An additional `FKPresentationDataSource` receiver (e.g. sizing).
  public weak var presentationDataSource: FKPresentationDataSource? {
    didSet { panelDataSourceProxy.forward = presentationDataSource }
  }

  /// Provides a content `UIView` per item. When non-nil, takes precedence.
  public var presentationContent: ((FKBarPresentation, Int, FKBar.Item) -> UIView?)?

  /// Provides a content `UIViewController` per item. Not called when `presentationContent` returns non-nil.
  public var presentationViewController: ((FKBarPresentation, Int, FKBar.Item) -> UIViewController?)?

  public var configuration: Configuration = .default {
    didSet { applyConfiguration(animated: false, completion: nil) }
  }

  private let barProxy = BarDelegateProxy()
  private let panelDelegateProxy = PanelDelegateProxy()
  private let panelDataSourceProxy = PanelDataSourceProxy()

  /// The currently presented item context, or `nil` when not presented.
  public private(set) var presentationContext: (index: Int, item: FKBar.Item)?

  /// Whether the panel is presented (mirrors `FKPresentation.isPresented`).
  public var isPresentationPresented: Bool { embeddedPresentation.isPresented }

  private var scheduledDismissReason: FKBarPresentation.PresentationDismissReason?

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

  /// Applies `configuration.bar` / `configuration.presentation` to child components.
  public func applyConfiguration(animated: Bool = false, completion: VoidHandler? = nil) {
    bar.setConfiguration(configuration.bar, animated: animated, completion: completion)
    embeddedPresentation.configuration = configuration.presentation
  }

  /// Equivalent to `bar.reloadItems`.
  public func reloadBarItems(_ items: [FKBar.Item], animated: Bool = false) {
    bar.reloadItems(items, animated: animated)
  }

  /// Dismisses the current panel (does not change bar selection).
  public func dismissPresentation(animated: Bool = true, completion: VoidHandler? = nil) {
    guard embeddedPresentation.isPresented else {
      completion?()
      return
    }
    scheduledDismissReason = .programmatic
    embeddedPresentation.dismiss(animated: animated, completion: completion)
  }

  // MARK: - Bar

  fileprivate func onBarDidSelect(sender: UIView, item: FKBar.Item, at index: Int) {
    guard configuration.behavior.presentsOnSelection else { return }
    guard delegate?.barPresentation(self, shouldPresentFor: item, at: index) ?? true else { return }

    if configuration.behavior.ignoresRepeatedSelectWhilePresented,
       embeddedPresentation.isPresented,
       presentationContext?.index == index {
      return
    }

    guard let host = configuration.presentationHost.resolve(from: self), host.bounds.width > 0 else {
      assertionFailure("FKBarPresentation: failed to resolve presentationHost. Ensure it is in the view hierarchy or use `.explicit`.")
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
    if let view = dataSource?.barPresentation(self, presentationViewForItemAt: index) {
      presentPanel(content: .view(view), anchor: sender, item: item, at: index, in: host)
      return
    }
    if let vc = dataSource?.barPresentation(self, presentationViewControllerForItemAt: index) {
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

  fileprivate func dismissReasonForCallbacks() -> FKBarPresentation.PresentationDismissReason {
    scheduledDismissReason ?? .maskTap
  }

  fileprivate func clearDismissSchedulingAfterCallbacks() {
    scheduledDismissReason = nil
  }

  fileprivate func clearPresentationContext() {
    presentationContext = nil
  }

  /// If the panel is dismissed and the bar selection hasn't changed to another item,
  /// deselect the item that triggered the panel and let `FKBar` run its full reset path.
  fileprivate func synchronizeBarSelectionAfterPresentationDismissed() {
    guard let idx = presentationContext?.index else { return }
    // Only deselect if the current selection still matches the presenting item.
    guard bar.selectedIndex == idx else { return }
    bar.deselectIndex(idx, animated: false, completion: nil)
  }
}

// MARK: - PresentationHost resolve

private extension FKBarPresentation.Configuration.PresentationHost {
  @MainActor
  func resolve(from barPresentation: FKBarPresentation) -> UIView? {
    switch self {
    case .automatic:
      return barPresentation.superview ?? barPresentation.window
    case .superview:
      return barPresentation.superview
    case .window:
      return barPresentation.window
    case .explicit(let box):
      return box.view
    }
  }
}

// MARK: - FKBarDelegate

private final class BarDelegateProxy: FKBarDelegate {
  weak var owner: FKBarPresentation?
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

// MARK: - FKPresentationDelegate

private final class PanelDelegateProxy: FKPresentationDelegate {
  weak var owner: FKBarPresentation?
  weak var forward: FKPresentationDelegate?

  func presentationWillPresent(_ presentation: FKPresentation) {
    guard let owner else {
      forward?.presentationWillPresent(presentation)
      return
    }
    if let ctx = owner.presentationContext {
      owner.delegate?.barPresentation(owner, willPresentFor: ctx.item, at: ctx.index)
    }
    forward?.presentationWillPresent(presentation)
  }

  func presentationDidPresent(_ presentation: FKPresentation) {
    guard let owner else {
      forward?.presentationDidPresent(presentation)
      return
    }
    if let ctx = owner.presentationContext {
      owner.delegate?.barPresentation(owner, didPresentFor: ctx.item, at: ctx.index)
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
    owner.delegate?.barPresentation(owner, willDismissPresentation: r)
    forward?.presentationWillDismiss(presentation)
  }

  func presentationDidDismiss(_ presentation: FKPresentation) {
    guard let owner else {
      forward?.presentationDidDismiss(presentation)
      return
    }
    owner.synchronizeBarSelectionAfterPresentationDismissed()
    let r = owner.dismissReasonForCallbacks()
    owner.delegate?.barPresentation(owner, didDismissPresentation: r)
    owner.clearDismissSchedulingAfterCallbacks()
    owner.clearPresentationContext()
    forward?.presentationDidDismiss(presentation)
  }

  func presentation(_ presentation: FKPresentation, willRepositionTo rect: inout CGRect, in view: inout UIView) {
    forward?.presentation(presentation, willRepositionTo: &rect, in: &view)
  }
}

// MARK: - FKPresentationDataSource

private final class PanelDataSourceProxy: FKPresentationDataSource {
  weak var owner: FKBarPresentation?
  weak var forward: FKPresentationDataSource?

  func presentationPreferredSize(_ presentation: FKPresentation) -> CGSize? {
    if let owner, let idx = owner.presentationContext?.index {
      if let s = owner.dataSource?.barPresentation(owner, preferredPresentationSizeForItemAt: idx) {
        return s
      }
    }
    return forward?.presentationPreferredSize(presentation)
  }

  func presentationContentView(_ presentation: FKPresentation) -> UIView? {
    forward?.presentationContentView(presentation)
  }
}
