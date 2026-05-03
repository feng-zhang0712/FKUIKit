import UIKit
import FKUIKit

/// A container controller that composes `FKTabBar` with an anchored embedded dropdown panel.
///
/// This component is designed for "Meituan-like" tab-based filter dropdown interactions:
/// - Tap a tab to open its panel anchored below the tab bar (default) or a custom ``UIView`` you configure.
/// - Tap the same tab again to close (toggle).
/// - Tap another tab to switch (previous closes, then new opens).
/// - Tap backdrop to close.
///
/// The dropdown presentation is powered by `FKPresentationController` in `.anchorEmbedded` mode.
/// Customize attachment using ``FKAnchoredDropdownConfiguration/anchorOverride`` or
/// ``FKAnchoredDropdownController/setCustomAnchor(source:overlayHost:)``.
@MainActor
public final class FKAnchoredDropdownController<TabID: Hashable>: UIViewController {
  /// Close reasons unified across user interactions and programmatic control.
  public enum CloseReason: Equatable, Sendable {
    /// The user tapped the already-expanded tab again.
    case repeatedTap
    /// The user tapped the backdrop or swiped to dismiss.
    case maskTapOrSwipe
    /// Closed by host code via API.
    case programmatic
    /// Closed as part of a tab switch.
    case switching
  }

  /// Current high-level state.
  public enum State: Equatable {
    case collapsed
    case expanding(tab: TabID)
    case expanded(tab: TabID)
    case collapsing(tab: TabID)
    case switching(from: TabID, to: TabID)
  }

  // MARK: - Public API

  /// Current state snapshot (read-only).
  public private(set) var state: State = .collapsed

  /// Currently selected tab id (if any).
  ///
  /// - Note: Selection does not necessarily imply the dropdown is expanded.
  public var selectedTab: TabID? { selectedTabID }

  /// Currently expanded tab id (if any).
  public var expandedTab: TabID? { expandedTabID }

  /// Tab bar host. You may provide your own host to customize the full tab bar container UI.
  public let tabBarHost: any FKAnchoredDropdownTabBarHost

  /// Underlying tab bar used for interaction and selection rendering.
  public var tabBar: FKTabBar { tabBarHost.tabBar }

  /// Component configuration.
  public var configuration: FKAnchoredDropdownConfiguration {
    didSet {
      applyConfiguration()
      rebuildTabBarItems(keepSelectedTab: selectedTabID)
    }
  }

  /// State callbacks.
  public var callbacks: FKAnchoredDropdownConfiguration.Callbacks<TabID>

  /// Creates a dropdown controller.
  ///
  /// - Parameters:
  ///   - tabs: Initial tab list.
  ///   - tabBarHost: A host object that contains an `FKTabBar`. Use the default host or provide a custom one.
  ///   - configuration: Configuration applied to the tab bar and presentation.
  ///   - callbacks: State callbacks.
  public init(
    tabs: [FKAnchoredDropdownTab<TabID>],
    tabBarHost: (any FKAnchoredDropdownTabBarHost)? = nil,
    configuration: FKAnchoredDropdownConfiguration = .default,
    callbacks: FKAnchoredDropdownConfiguration.Callbacks<TabID> = .init()
  ) {
    self.tabs = tabs
    self.tabBarHost = tabBarHost ?? FKDefaultTabDropdownTabBarHost()
    self.configuration = configuration
    self.callbacks = callbacks
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  /// Updates tabs at runtime.
  ///
  /// This method keeps the current selection when possible.
  public func setTabs(_ tabs: [FKAnchoredDropdownTab<TabID>]) {
    self.tabs = tabs
    rebuildTabBarItems(keepSelectedTab: selectedTabID)

    if let expanded = expandedTabID, tabs.contains(where: { $0.id == expanded }) == false {
      close(animated: true)
    }

    switch configuration.contentCachingPolicy {
    case .recreate:
      cachedContentControllers.removeAll()
    case .cachePerTab:
      let keep = Set(tabs.map(\.id))
      cachedContentControllers.keys
        .filter { !keep.contains($0) }
        .forEach { cachedContentControllers[$0] = nil }
    }
  }

  /// Opens the dropdown for the given tab.
  public func open(tab id: TabID, animated: Bool = true) {
    enqueueDesiredExpandedTab(id, animated: animated, closeReasonWhenCollapsing: .programmatic)
  }

  /// Closes the currently expanded dropdown (if any).
  public func close(animated: Bool = true) {
    enqueueDesiredExpandedTab(nil, animated: animated, closeReasonWhenCollapsing: .programmatic)
  }

  /// Sets the expanded tab id.
  ///
  /// Pass `nil` to collapse.
  ///
  /// This API is useful for state restoration where the expanded tab is your source of truth.
  public func setExpandedTab(_ id: TabID?, animated: Bool = true) {
    enqueueDesiredExpandedTab(id, animated: animated, closeReasonWhenCollapsing: .programmatic)
  }

  /// Toggles the dropdown for a given tab.
  public func toggle(tab id: TabID, animated: Bool = true) {
    if expandedTabID == id {
      enqueueDesiredExpandedTab(nil, animated: animated, closeReasonWhenCollapsing: .programmatic)
    } else {
      enqueueDesiredExpandedTab(id, animated: animated, closeReasonWhenCollapsing: .programmatic)
    }
  }

  /// Selects a tab in the tab bar without opening the dropdown.
  ///
  /// This is useful for restoring state while keeping the panel collapsed.
  public func select(tab id: TabID, animated: Bool = false) {
    guard let idx = tabs.firstIndex(where: { $0.id == id }) else { return }
    selectedTabID = id
    tabBar.setSelectedIndex(idx, animated: animated, notify: false, reason: .programmatic)
    rebuildTabBarItems(keepSelectedTab: id)
  }

  /// Rebuilds tab bar items from the current `tabs` array without changing selection or expansion.
  ///
  /// Call this when `makeTabBarItem` reads external state (for example, a “3 selected” subtitle) and
  /// that state changed without assigning a new `tabs` array.
  public func reloadTabBarItems() {
    rebuildTabBarItems(keepSelectedTab: selectedTabID)
  }

  /// Drops any cached content view controller for `tab` (see `configuration.contentCachingPolicy`).
  ///
  /// If that tab is currently expanded, the visible panel is replaced with a freshly resolved controller.
  public func invalidateCachedContent(for tab: TabID) {
    cachedContentControllers[tab] = nil
    refreshPresentedContentIfNeeded(forExpandedTab: tab)
  }

  /// Clears all per-tab content caches.
  ///
  /// If a tab is expanded, its panel is replaced with a freshly resolved controller for that tab only.
  public func invalidateAllCachedContent() {
    cachedContentControllers.removeAll()
    if let expanded = expandedTabID {
      refreshPresentedContentIfNeeded(forExpandedTab: expanded)
    }
  }

  // MARK: - UIViewController

  public override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear
    installTabBarHost()
    applyConfiguration()
    rebuildTabBarItems(keepSelectedTab: selectedTabID)
    wireTabBarEvents()
  }

  public override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    // External callers may request `open(tab:)` before this controller is attached to a window
    // (deep links, state restoration, push transitions). We keep the desired state and reconcile here.
    reconcileIfPossible()
  }

  public override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    // When container size changes (rotation, split view), rebuild items so custom tab views can
    // respond if they measure based on bounds. Avoid reloading if not needed.
    tabBar.realignSelection(animated: false)
  }

  // MARK: - Internal storage

  private var tabs: [FKAnchoredDropdownTab<TabID>] = []
  private var selectedTabID: TabID?
  private var expandedTabID: TabID? {
    didSet { callbacks.expandedTabDidChange?(expandedTabID) }
  }

  private var fkPresentationController: FKPresentationController?
  private var presentedContentContainer: FKAnchoredDropdownContentContainerViewController?
  private var scheduledCloseReason: CloseReason?
  private var lastClosingTabID: TabID?
  private var pendingSwitchTargetTabID: TabID?
  private var pendingSwitchAnimated: Bool = true
  private var isSwitchingContentInPlace: Bool = false

  private struct DesiredExpandedRequest: Equatable {
    var tab: TabID?
    var animated: Bool
    var closeReasonWhenCollapsing: CloseReason
  }

  private var desiredExpanded: DesiredExpandedRequest?
  private var isReconciling = false
  private var cachedContentControllers: [TabID: UIViewController] = [:]

  // MARK: - Setup

  private func installTabBarHost() {
    let hostView = tabBarHost.view
    hostView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(hostView)
    NSLayoutConstraint.activate([
      hostView.topAnchor.constraint(equalTo: view.topAnchor),
      hostView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      hostView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      hostView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  private func wireTabBarEvents() {
    tabBar.tapEventTriggerBehavior = .onceAfterSelection
    tabBar.onSelectionChanged = { [weak self] item, index, reason in
      guard let self else { return }
      guard reason == .userTap else { return }
      guard let tab = self.tabs[safe: index] else { return }
      self.selectedTabID = tab.id
      self.handleUserTap(tab: tab.id)
    }
    tabBar.onReselect = { [weak self] item, index in
      guard let self else { return }
      guard let tab = self.tabs[safe: index] else { return }
      self.selectedTabID = tab.id
      self.handleUserTap(tab: tab.id)
    }
  }

  private func handleUserTap(tab id: TabID) {
    if let expanded = expandedTabID {
      if expanded == id {
        enqueueDesiredExpandedTab(nil, animated: true, closeReasonWhenCollapsing: .repeatedTap)
      } else {
        enqueueDesiredExpandedTab(id, animated: true, closeReasonWhenCollapsing: .switching)
      }
      return
    }
    enqueueDesiredExpandedTab(id, animated: true, closeReasonWhenCollapsing: .programmatic)
  }

  private func applyConfiguration() {
    tabBar.configuration = configuration.tabBarConfiguration
  }

  // MARK: - Tab bar items

  private func rebuildTabBarItems(keepSelectedTab: TabID?) {
    let snapshot = FKAnchoredDropdownTab<TabID>.StateSnapshot(
      expandedTab: expandedTabID,
      selectedTab: keepSelectedTab
    )
    let items = tabs.map { $0.makeTabBarItem(snapshot) }
    tabBar.reload(items: items, updatePolicy: .preserveSelection)
    if let keepSelectedTab, let idx = tabs.firstIndex(where: { $0.id == keepSelectedTab }) {
      tabBar.setSelectedIndex(idx, animated: false, notify: false, reason: .programmatic)
    }
  }

  // MARK: - Command reconciliation

  private func enqueueDesiredExpandedTab(_ tab: TabID?, animated: Bool, closeReasonWhenCollapsing: CloseReason) {
    desiredExpanded = DesiredExpandedRequest(tab: tab, animated: animated, closeReasonWhenCollapsing: closeReasonWhenCollapsing)
    reconcileIfPossible()
  }

  private func reconcileIfPossible() {
    guard isReconciling == false else { return }
    guard let desiredExpanded else { return }
    guard isSwitchingContentInPlace == false else { return }
    guard let presented = fkPresentationController else {
      // No active controller. Either present, or remain collapsed.
      if let target = desiredExpanded.tab {
        let started = transitionToExpand(tab: target, animated: desiredExpanded.animated)
        if started {
          self.desiredExpanded = nil
        }
        return
      }
      self.desiredExpanded = nil
      return
    }
    guard presented.isTransitioning == false else { return }

    isReconciling = true
    defer { isReconciling = false }

    let currentExpanded = expandedTabID
    let target = desiredExpanded.tab
    let animated = desiredExpanded.animated
    let closeReasonWhenCollapsing = desiredExpanded.closeReasonWhenCollapsing
    self.desiredExpanded = nil

    switch (currentExpanded, target) {
    case (nil, nil):
      return
    case (nil, .some(let to)):
      transitionToExpand(tab: to, animated: animated)
    case (.some, nil):
      transitionToCollapse(reason: closeReasonWhenCollapsing, animated: animated)
    case (.some(let from), .some(let to)):
      if from == to {
        // already expanded, do nothing
        return
      }
      transitionToSwitch(from: from, to: to, animated: animated)
    }
  }

  // MARK: - Transitions

  @discardableResult
  private func transitionToExpand(tab id: TabID, animated: Bool) -> Bool {
    guard let tab = tabs.first(where: { $0.id == id }) else { return false }
    guard fkPresentationController == nil else { return false }
    guard viewIfLoaded?.window != nil else { return false }

    callbacks.willOpen?(id)
    setState(.expanding(tab: id))
    expandedTabID = id
    rebuildTabBarItems(keepSelectedTab: selectedTabID ?? id)

    let container = FKAnchoredDropdownContentContainerViewController()
    container.onPreferredContentSizeDidChange = { [weak self] in
      guard let self else { return }
      let shouldAnimate = self.configuration.switchAnimationStyle.isReplaceInPlace
      self.fkPresentationController?.updateLayout(
        animated: shouldAnimate,
        duration: shouldAnimate ? 0.24 : 0,
        options: .curveEaseInOut
      )
    }
    let contentVC = resolveContentController(for: tab)
    container.setContent(contentVC, transition: .none, completion: nil)
    presentedContentContainer = container

    var cfg = configuration.presentationConfiguration
    cfg.dismissBehavior.allowsTapOutside = configuration.allowsTapOutsideToDismiss
    cfg.dismissBehavior.allowsSwipe = configuration.allowsSwipeToDismiss
    cfg.dismissBehavior.allowsBackdropTap = configuration.allowsBackdropTapToDismiss
    cfg.layout = .anchor(makePresentationAnchorConfiguration())

    let controller = FKPresentationController(contentController: container, configuration: cfg, delegate: self)
    fkPresentationController = controller
    controller.present(from: self, animated: animated, completion: nil)
    return true
  }

  private func resolveContentController(for tab: FKAnchoredDropdownTab<TabID>) -> UIViewController {
    switch configuration.contentCachingPolicy {
    case .recreate:
      return makeContentController(for: tab)
    case .cachePerTab:
      if let cached = cachedContentControllers[tab.id] {
        return cached
      }
      let created = makeContentController(for: tab)
      cachedContentControllers[tab.id] = created
      return created
    }
  }

  private func makeContentController(for tab: FKAnchoredDropdownTab<TabID>) -> UIViewController {
    switch tab.content {
    case let .viewController(make):
      return make()
    case let .view(make):
      return FKAnchoredDropdownViewWrappingController(makeView: make)
    }
  }

  private func refreshPresentedContentIfNeeded(forExpandedTab tab: TabID) {
    guard expandedTabID == tab, let container = presentedContentContainer,
          let tabModel = tabs.first(where: { $0.id == tab }) else { return }
    let next = resolveContentController(for: tabModel)
    container.setContent(next, transition: .none, completion: nil)
  }

  private func transitionToCollapse(reason: CloseReason, animated: Bool) {
    guard let controller = fkPresentationController else { return }
    let closingTab = expandedTabID
    lastClosingTabID = closingTab
    scheduledCloseReason = reason
    if let closingTab {
      callbacks.willClose?(closingTab, reason)
      setState(.collapsing(tab: closingTab))
    } else {
      callbacks.willClose?(nil, reason)
      setState(.collapsed)
    }
    controller.dismiss(animated: animated, completion: nil)
  }

  private func transitionToSwitch(from: TabID, to: TabID, animated: Bool) {
    guard let controller = fkPresentationController else {
      transitionToExpand(tab: to, animated: animated)
      return
    }
    callbacks.willSwitch?(from, to)
    setState(.switching(from: from, to: to))

    let style = configuration.switchAnimationStyle
    switch style {
    case let .dismissThenPresent(dismissAnimated, presentAnimated):
      callbacks.willClose?(from, .switching)
      lastClosingTabID = from
      scheduledCloseReason = .switching
      pendingSwitchTargetTabID = to
      pendingSwitchAnimated = presentAnimated
      controller.dismiss(animated: dismissAnimated, completion: nil)

    case let .replaceInPlace(animation):
      guard let container = presentedContentContainer else {
        // Fallback to safe behavior.
        callbacks.willClose?(from, .switching)
        lastClosingTabID = from
        scheduledCloseReason = .switching
        pendingSwitchTargetTabID = to
        pendingSwitchAnimated = true
        controller.dismiss(animated: false, completion: nil)
        return
      }
      guard let tab = tabs.first(where: { $0.id == to }) else { return }
      let nextContent = resolveContentController(for: tab)

      // Update expanded state early so tab UI can reflect "expanded" for the new tab.
      expandedTabID = to
      rebuildTabBarItems(keepSelectedTab: selectedTabID ?? to)

      isSwitchingContentInPlace = true
      container.setContent(nextContent, transition: containerTransition(for: animation)) { [weak self] in
        guard let self else { return }
        self.fkPresentationController?.updateLayout(animated: true, duration: 0.24, options: .curveEaseInOut)
        self.isSwitchingContentInPlace = false
        // The user might have tapped another tab while we were animating.
        // Only commit `didSwitch` if we actually ended on the expected target.
        if self.expandedTabID == to {
          self.callbacks.didSwitch?(from, to)
          self.setState(.expanded(tab: to))
        }
        self.reconcileIfPossible()
      }
    }
  }
}

// MARK: - FKPresentationControllerDelegate

extension FKAnchoredDropdownController: FKPresentationControllerDelegate {
  public func presentationControllerWillPresent(_ controller: FKPresentationController) {}

  public func presentationControllerDidPresent(_ controller: FKPresentationController) {
    guard let expanded = expandedTabID else { return }
    callbacks.didOpen?(expanded)
    setState(.expanded(tab: expanded))
    reconcileIfPossible()
  }

  public func presentationControllerWillDismiss(_ controller: FKPresentationController) {
    // User-driven dismissal (backdrop tap / swipe) flows here.
    if scheduledCloseReason == nil {
      scheduledCloseReason = .maskTapOrSwipe
      lastClosingTabID = expandedTabID
      callbacks.willClose?(expandedTabID, .maskTapOrSwipe)
      if let expanded = expandedTabID {
        setState(.collapsing(tab: expanded))
      }
    }
  }

  public func presentationControllerDidDismiss(_ controller: FKPresentationController) {
    let reason = scheduledCloseReason ?? .maskTapOrSwipe
    let closingTab = lastClosingTabID ?? expandedTabID

    // Clear current presentation state first so any follow-up open can proceed.
    fkPresentationController = nil
    presentedContentContainer = nil
    expandedTabID = nil
    scheduledCloseReason = nil
    lastClosingTabID = nil

    callbacks.didClose?(closingTab, reason)
    setState(.collapsed)
    rebuildTabBarItems(keepSelectedTab: selectedTabID)

    if let fromTo = resolvePendingSwitchAfterDismiss(previouslyExpanded: closingTab) {
      callbacks.didSwitch?(fromTo.from, fromTo.to)
      transitionToExpand(tab: fromTo.to, animated: fromTo.animated)
      return
    }

    reconcileIfPossible()
  }

  public func presentationController(_ controller: FKPresentationController, didUpdateProgress progress: CGFloat) {}

  public func presentationController(_ controller: FKPresentationController, didChangeDetent detent: FKPresentationDetent, index: Int) {}
}

private extension FKAnchoredDropdownController {
  func containerTransition(for animation: FKAnchoredDropdownConfiguration.ReplaceInPlaceAnimation) -> FKAnchoredDropdownContentContainerViewController.Transition {
    switch animation {
    case let .crossfade(duration):
      return .crossfade(duration: duration)
    case let .slideVertical(direction, duration):
      let d: FKAnchoredDropdownContentContainerViewController.Transition.SlideDirection = (direction == .up) ? .up : .down
      return .slideVertical(direction: d, duration: duration)
    }
  }
}

private extension FKAnchoredDropdownConfiguration.SwitchAnimationStyle {
  var isReplaceInPlace: Bool {
    if case .replaceInPlace = self { return true }
    return false
  }
}

private extension FKAnchoredDropdownController {
  func setState(_ newValue: State) {
    if state == newValue { return }
    state = newValue
    callbacks.stateDidChange?(newValue)
  }
}

private extension FKAnchoredDropdownController {
  func resolvePendingSwitchAfterDismiss(previouslyExpanded: TabID?) -> (from: TabID, to: TabID, animated: Bool)? {
    guard let from = previouslyExpanded else {
      pendingSwitchTargetTabID = nil
      return nil
    }
    guard let to = pendingSwitchTargetTabID else { return nil }
    let animated = pendingSwitchAnimated
    pendingSwitchTargetTabID = nil
    pendingSwitchAnimated = true
    return (from: from, to: to, animated: animated)
  }
}

private extension Array {
  subscript(safe index: Int) -> Element? {
    guard indices.contains(index) else { return nil }
    return self[index]
  }
}

