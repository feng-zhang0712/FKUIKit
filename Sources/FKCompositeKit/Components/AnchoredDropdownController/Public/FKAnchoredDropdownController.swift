import UIKit
import FKUIKit

/// Hosts an ``FKTabBar`` and presents an anchor-attached panel per tab via ``FKPresentationController``.
///
/// Typical interaction: tap a tab to expand its panel below the bar (or a custom anchor), tap again to collapse,
/// switch tabs while expanded, or dismiss via backdrop / swipe when enabled in ``FKAnchoredDropdownConfiguration/presentationConfiguration``.
@MainActor
public final class FKAnchoredDropdownController<TabID: Hashable>: UIViewController {
  /// Why the panel transitioned to the collapsed state.
  public enum DismissReason: Equatable, Sendable {
    case userToggledSameTab
    case backdropOrSwipe
    case programmatic
    case switchingTab
  }

  public enum State: Equatable {
    case collapsed
    case expanding(tab: TabID)
    case expanded(tab: TabID)
    case collapsing(tab: TabID)
    case switching(from: TabID, to: TabID)
  }

  public private(set) var state: State = .collapsed

  public var selectedTabID: TabID? { selectedTabInternal }

  public var expandedTabID: TabID? { expandedTabInternal }

  public let tabBarHost: any FKAnchoredDropdownTabBarHost

  public var tabBar: FKTabBar { tabBarHost.tabBar }

  public var configuration: FKAnchoredDropdownConfiguration {
    didSet {
      applyConfiguration()
      rebuildTabBarItems(keepSelectedTab: selectedTabInternal)
    }
  }

  public var events: FKAnchoredDropdownConfiguration.Events<TabID>

  public init(
    tabs: [FKAnchoredDropdownTab<TabID>],
    tabBarHost: (any FKAnchoredDropdownTabBarHost)? = nil,
    configuration: FKAnchoredDropdownConfiguration = .default,
    events: FKAnchoredDropdownConfiguration.Events<TabID> = .init()
  ) {
    self.tabs = tabs
    self.tabBarHost = tabBarHost ?? FKAnchoredDropdownDefaultTabBarHost()
    self.configuration = configuration
    self.events = events
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func updateTabs(_ tabs: [FKAnchoredDropdownTab<TabID>]) {
    self.tabs = tabs
    rebuildTabBarItems(keepSelectedTab: selectedTabInternal)

    if let expanded = expandedTabInternal, tabs.contains(where: { $0.id == expanded }) == false {
      collapsePanel(animated: true)
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

  public func expandPanel(for tab: TabID, animated: Bool = true) {
    enqueueDesiredExpandedTab(tab, animated: animated, collapseReasonWhenDismissing: .programmatic)
  }

  public func collapsePanel(animated: Bool = true) {
    enqueueDesiredExpandedTab(nil, animated: animated, collapseReasonWhenDismissing: .programmatic)
  }

  public func togglePanel(for tab: TabID, animated: Bool = true) {
    if expandedTabInternal == tab {
      enqueueDesiredExpandedTab(nil, animated: animated, collapseReasonWhenDismissing: .programmatic)
    } else {
      enqueueDesiredExpandedTab(tab, animated: animated, collapseReasonWhenDismissing: .programmatic)
    }
  }

  public func selectTab(_ id: TabID, animated: Bool = false) {
    guard let idx = tabs.firstIndex(where: { $0.id == id }) else { return }
    selectedTabInternal = id
    tabBar.setSelectedIndex(idx, animated: animated, notify: false, reason: .programmatic)
    rebuildTabBarItems(keepSelectedTab: id)
  }

  public func reloadTabBarItems() {
    rebuildTabBarItems(keepSelectedTab: selectedTabInternal)
  }

  public func invalidateCachedContent(for tab: TabID) {
    cachedContentControllers[tab] = nil
    refreshPresentedContentIfNeeded(forExpandedTab: tab)
  }

  public func invalidateAllCachedContent() {
    cachedContentControllers.removeAll()
    if let expanded = expandedTabInternal {
      refreshPresentedContentIfNeeded(forExpandedTab: expanded)
    }
  }

  // MARK: - Anchor & embedding

  /// Pins the panel to `source` and optionally uses a larger `overlayHost` for mask/layout bounds.
  public func setAnchor(source: UIView, overlayHost: UIView? = nil) {
    if configuration.anchorPlacement == nil {
      var next = configuration
      next.anchorPlacement = FKAnchoredDropdownAnchorPlacement()
      configuration = next
    }
    configuration.anchorPlacement?.sourceView = source
    configuration.anchorPlacement?.overlayHostView = overlayHost
  }

  public func updateAnchorPlacement(
    attachmentEdge: FKAnchor.Edge? = nil,
    expansionDirection: FKAnchor.Direction? = nil,
    horizontalAlignment: FKAnchor.Alignment? = nil,
    widthPolicy: FKAnchor.WidthPolicy? = nil,
    attachmentOffset: CGFloat? = nil
  ) {
    guard let placement = configuration.anchorPlacement else { return }
    if let attachmentEdge { placement.attachmentEdge = attachmentEdge }
    if let expansionDirection { placement.expansionDirection = expansionDirection }
    if let horizontalAlignment { placement.horizontalAlignment = horizontalAlignment }
    if let widthPolicy { placement.widthPolicy = widthPolicy }
    if let attachmentOffset { placement.attachmentOffset = attachmentOffset }
  }

  public func resetAnchorToDefault() {
    guard configuration.anchorPlacement != nil else { return }
    var next = configuration
    next.anchorPlacement = nil
    configuration = next
  }

  /// Adds this controller as a child of `parent` and pins ``view`` to `container` (default: `parent.view`).
  public func embed(in parent: UIViewController, pinTo container: UIView? = nil) {
    guard let host = container ?? parent.view else {
      assertionFailure("embed(in:pinTo:) requires a loaded parent.view or an explicit container.")
      return
    }
    parent.addChild(self)
    view.translatesAutoresizingMaskIntoConstraints = false
    host.addSubview(view)
    NSLayoutConstraint.activate([
      view.topAnchor.constraint(equalTo: host.topAnchor),
      view.leadingAnchor.constraint(equalTo: host.leadingAnchor),
      view.trailingAnchor.constraint(equalTo: host.trailingAnchor),
      view.bottomAnchor.constraint(equalTo: host.bottomAnchor),
    ])
    didMove(toParent: parent)
  }

  // MARK: - UIViewController

  public override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear
    installTabBarHost()
    applyConfiguration()
    rebuildTabBarItems(keepSelectedTab: selectedTabInternal)
    wireTabBarEvents()
  }

  public override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    reconcileIfPossible()
  }

  public override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    tabBar.realignSelection(animated: false)
  }

  // MARK: - Private

  private var tabs: [FKAnchoredDropdownTab<TabID>] = []
  private var selectedTabInternal: TabID?
  private var expandedTabInternal: TabID? {
    didSet { events.onExpandedTabChange?(expandedTabInternal) }
  }

  private var fkPresentationController: FKPresentationController?
  private var presentedContentContainer: FKAnchoredDropdownContentContainerViewController?
  private var scheduledDismissReason: DismissReason?
  private var lastCollapsingTabID: TabID?
  private var pendingSwitchTargetTabID: TabID?
  private var pendingSwitchAnimated: Bool = true
  private var isSwitchingContentInPlace: Bool = false

  private struct DesiredExpandedRequest: Equatable {
    var tab: TabID?
    var animated: Bool
    var collapseReasonWhenDismissing: DismissReason
  }

  private var desiredExpanded: DesiredExpandedRequest?
  private var isReconciling = false
  private var cachedContentControllers: [TabID: UIViewController] = [:]

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
    tabBar.onSelectionChanged = { [weak self] _, index, reason in
      guard let self else { return }
      guard reason == .userTap else { return }
      guard let tab = self.tabs[safe: index] else { return }
      self.selectedTabInternal = tab.id
      self.handleUserTap(tab: tab.id)
    }
    tabBar.onReselect = { [weak self] _, index in
      guard let self else { return }
      guard let tab = self.tabs[safe: index] else { return }
      self.selectedTabInternal = tab.id
      self.handleUserTap(tab: tab.id)
    }
  }

  private func handleUserTap(tab id: TabID) {
    if let expanded = expandedTabInternal {
      if expanded == id {
        enqueueDesiredExpandedTab(nil, animated: true, collapseReasonWhenDismissing: .userToggledSameTab)
      } else {
        enqueueDesiredExpandedTab(id, animated: true, collapseReasonWhenDismissing: .switchingTab)
      }
      return
    }
    enqueueDesiredExpandedTab(id, animated: true, collapseReasonWhenDismissing: .programmatic)
  }

  private func applyConfiguration() {
    tabBar.configuration = configuration.tabBarConfiguration
  }

  private func rebuildTabBarItems(keepSelectedTab: TabID?, forceCollapsedChrome: Bool = false) {
    let snapshot = FKAnchoredDropdownTab<TabID>.StateSnapshot(
      expandedTab: forceCollapsedChrome ? nil : expandedTabInternal,
      selectedTab: keepSelectedTab
    )
    let items = tabs.map { $0.makeTabBarItem(snapshot) }
    tabBar.reload(items: items, updatePolicy: .preserveSelection)
    if let keepSelectedTab, let idx = tabs.firstIndex(where: { $0.id == keepSelectedTab }) {
      tabBar.setSelectedIndex(idx, animated: true, notify: false, reason: .programmatic)
    }
    tabBar.reapplyVisibleItemConfigurations()
  }

  private func enqueueDesiredExpandedTab(_ tab: TabID?, animated: Bool, collapseReasonWhenDismissing: DismissReason) {
    desiredExpanded = DesiredExpandedRequest(tab: tab, animated: animated, collapseReasonWhenDismissing: collapseReasonWhenDismissing)
    reconcileIfPossible()
  }

  private func reconcileIfPossible() {
    guard isReconciling == false else { return }
    guard let desiredExpanded else { return }
    guard isSwitchingContentInPlace == false else { return }
    guard let presented = fkPresentationController else {
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

    let currentExpanded = expandedTabInternal
    let target = desiredExpanded.tab
    let animated = desiredExpanded.animated
    let collapseReasonWhenDismissing = desiredExpanded.collapseReasonWhenDismissing
    self.desiredExpanded = nil

    switch (currentExpanded, target) {
    case (nil, nil):
      return
    case (nil, .some(let to)):
      transitionToExpand(tab: to, animated: animated)
    case (.some, nil):
      transitionToCollapse(reason: collapseReasonWhenDismissing, animated: animated)
    case (.some(let from), .some(let to)):
      if from == to { return }
      transitionToSwitch(from: from, to: to, animated: animated)
    }
  }

  @discardableResult
  private func transitionToExpand(tab id: TabID, animated: Bool) -> Bool {
    guard let tab = tabs.first(where: { $0.id == id }) else { return false }
    guard fkPresentationController == nil else { return false }
    guard viewIfLoaded?.window != nil else { return false }

    events.onWillExpand?(id)
    setState(.expanding(tab: id))
    expandedTabInternal = id
    rebuildTabBarItems(keepSelectedTab: selectedTabInternal ?? id)

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
    guard expandedTabInternal == tab, let container = presentedContentContainer,
          let tabModel = tabs.first(where: { $0.id == tab }) else { return }
    let next = resolveContentController(for: tabModel)
    container.setContent(next, transition: .none, completion: nil)
  }

  private func transitionToCollapse(reason: DismissReason, animated: Bool) {
    guard let controller = fkPresentationController else { return }
    let closingTab = expandedTabInternal
    lastCollapsingTabID = closingTab
    scheduledDismissReason = reason
    rebuildTabBarItems(keepSelectedTab: selectedTabInternal, forceCollapsedChrome: true)
    if let closingTab {
      events.onWillCollapse?(closingTab, reason)
      setState(.collapsing(tab: closingTab))
    } else {
      events.onWillCollapse?(nil, reason)
      setState(.collapsed)
    }
    controller.dismiss(animated: animated, completion: nil)
  }

  private func transitionToSwitch(from: TabID, to: TabID, animated: Bool) {
    guard let controller = fkPresentationController else {
      transitionToExpand(tab: to, animated: animated)
      return
    }
    events.onWillSwitchTab?(from, to)
    setState(.switching(from: from, to: to))

    let style = configuration.switchAnimationStyle
    switch style {
    case let .dismissThenPresent(dismissAnimated, presentAnimated):
      events.onWillCollapse?(from, .switchingTab)
      lastCollapsingTabID = from
      scheduledDismissReason = .switchingTab
      pendingSwitchTargetTabID = to
      pendingSwitchAnimated = presentAnimated
      controller.dismiss(animated: dismissAnimated, completion: nil)

    case let .replaceInPlace(animation):
      guard let container = presentedContentContainer else {
        events.onWillCollapse?(from, .switchingTab)
        lastCollapsingTabID = from
        scheduledDismissReason = .switchingTab
        pendingSwitchTargetTabID = to
        pendingSwitchAnimated = true
        controller.dismiss(animated: false, completion: nil)
        return
      }
      guard let tab = tabs.first(where: { $0.id == to }) else { return }
      let nextContent = resolveContentController(for: tab)

      expandedTabInternal = to
      rebuildTabBarItems(keepSelectedTab: selectedTabInternal ?? to)

      isSwitchingContentInPlace = true
      container.setContent(nextContent, transition: containerTransition(for: animation)) { [weak self] in
        guard let self else { return }
        self.fkPresentationController?.updateLayout(animated: true, duration: 0.24, options: .curveEaseInOut)
        self.isSwitchingContentInPlace = false
        if self.expandedTabInternal == to {
          self.events.onDidSwitchTab?(from, to)
          self.setState(.expanded(tab: to))
        }
        self.reconcileIfPossible()
      }
    }
  }

  private func makePresentationAnchorConfiguration() -> FKAnchorConfiguration {
    let placement = configuration.anchorPlacement
    let sourceView = placement?.sourceView ?? tabBarHost.tabBar
    let hostView = placement?.overlayHostView ?? tabBarHost.view

    return FKAnchorConfiguration(
      anchor: FKAnchor(
        sourceView: sourceView,
        edge: placement?.attachmentEdge ?? .bottom,
        direction: placement?.expansionDirection ?? .down,
        alignment: placement?.horizontalAlignment ?? .fill,
        widthPolicy: placement?.widthPolicy ?? .matchContainer,
        offset: placement?.attachmentOffset ?? 0
      ),
      hostStrategy: .inProvidedContainer(FKWeakReference(hostView)),
      zOrderPolicy: .keepAnchorAbovePresentation,
      maskCoveragePolicy: .belowAnchorOnly
    )
  }

  private func setState(_ newValue: State) {
    if state == newValue { return }
    state = newValue
    events.onStateChange?(newValue)
  }

  private func resolvePendingSwitchAfterDismiss(previouslyExpanded: TabID?) -> (from: TabID, to: TabID, animated: Bool)? {
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

  private func containerTransition(for animation: FKAnchoredDropdownConfiguration.ReplaceInPlaceAnimation) -> FKAnchoredDropdownContentContainerViewController.Transition {
    switch animation {
    case let .crossfade(duration):
      return .crossfade(duration: duration)
    case let .slideVertical(direction, duration):
      let d: FKAnchoredDropdownContentContainerViewController.Transition.SlideDirection = (direction == .up) ? .up : .down
      return .slideVertical(direction: d, duration: duration)
    }
  }
}

// MARK: - FKPresentationControllerDelegate

extension FKAnchoredDropdownController: FKPresentationControllerDelegate {
  public func presentationControllerDidPresent(_ controller: FKPresentationController) {
    guard let expanded = expandedTabInternal else { return }
    events.onDidExpand?(expanded)
    setState(.expanded(tab: expanded))
    reconcileIfPossible()
  }

  public func presentationControllerWillDismiss(_ controller: FKPresentationController) {
    if scheduledDismissReason == nil {
      scheduledDismissReason = .backdropOrSwipe
      lastCollapsingTabID = expandedTabInternal
      rebuildTabBarItems(keepSelectedTab: selectedTabInternal, forceCollapsedChrome: true)
      events.onWillCollapse?(expandedTabInternal, .backdropOrSwipe)
      if let expanded = expandedTabInternal {
        setState(.collapsing(tab: expanded))
      }
    }
  }

  public func presentationControllerDidDismiss(_ controller: FKPresentationController) {
    let reason = scheduledDismissReason ?? .backdropOrSwipe
    let collapsingTab = lastCollapsingTabID ?? expandedTabInternal

    fkPresentationController = nil
    presentedContentContainer = nil
    expandedTabInternal = nil
    scheduledDismissReason = nil
    lastCollapsingTabID = nil

    events.onDidCollapse?(collapsingTab, reason)
    setState(.collapsed)
    rebuildTabBarItems(keepSelectedTab: selectedTabInternal)

    if let fromTo = resolvePendingSwitchAfterDismiss(previouslyExpanded: collapsingTab) {
      events.onDidSwitchTab?(fromTo.from, fromTo.to)
      transitionToExpand(tab: fromTo.to, animated: fromTo.animated)
      return
    }

    reconcileIfPossible()
  }
}

private extension FKAnchoredDropdownConfiguration.SwitchAnimationStyle {
  var isReplaceInPlace: Bool {
    if case .replaceInPlace = self { return true }
    return false
  }
}
