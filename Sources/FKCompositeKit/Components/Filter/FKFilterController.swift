import UIKit

/// Selection event emitted when the user picks an option inside a filter panel.
public typealias FKFilterSelectionCallback = @MainActor (
  _ panelKind: FKFilterPanelKind,
  _ sectionID: FKFilterID?,
  _ item: FKFilterOptionItem,
  _ effectiveSelectionMode: FKFilterSelectionMode
) -> Void

@MainActor
private final class FKFilterSelectionCallbackStorage {
  var onSelection: FKFilterSelectionCallback?
}

/// Holds a weak dropdown reference so panel selection can collapse the sheet after `onSelection` fires.
@MainActor
private final class FKFilterDropdownDismissBond<TabID: Hashable> {
  weak var dropdown: FKAnchoredDropdownController<TabID>?

  func dismissAfterSelectionIfNeeded(effectiveMode: FKFilterSelectionMode) {
    guard effectiveMode == .single else { return }
    dropdown?.close(animated: true)
  }
}

/// Tab bar title overrides after single-select picks (see ``FKFilterController``).
@MainActor
private final class FKFilterTabTitleOverrideStore<TabID: Hashable> {
  private var overrides: [TabID: String] = [:]

  func displayTitle(for id: TabID, fallback fallbackTitle: @escaping () -> String) -> String {
    overrides[id] ?? fallbackTitle()
  }

  func setTitle(_ title: String, for id: TabID) {
    overrides[id] = title
  }

  func removeTitle(for id: TabID) {
    overrides[id] = nil
  }

  func removeAll() {
    overrides.removeAll(keepingCapacity: false)
  }
}

/// Filter bar + anchored dropdown, wired to ``FKFilterPanelFactory`` panel types.
///
/// This wraps ``FKAnchoredDropdownController`` so bar items use the standard chevron title style and
/// each tab’s sheet content comes from your ``FKFilterPanelFactory`` `sources`.
@MainActor
public final class FKFilterController<TabID: Hashable>: UIViewController {
  public let dropdownController: FKAnchoredDropdownController<TabID>
  public let panelFactory: FKFilterPanelFactory

  private var filterTabs: [FKFilterTab<TabID>]
  private let selectionStorage = FKFilterSelectionCallbackStorage()
  private let dismissBond = FKFilterDropdownDismissBond<TabID>()
  private let titleOverrideStore = FKFilterTabTitleOverrideStore<TabID>()

  /// Called when a panel forwards a selection (after the panel updates its model via `onChange`).
  ///
  /// For ``FKFilterSelectionMode/single`` selections, the tab’s primary title is updated to the picked
  /// ``FKFilterOptionItem/title`` before this runs, then the anchored panel collapses. Multi-select panels
  /// stay open until the user dismisses them and do not change the tab title automatically.
  public var onSelection: FKFilterSelectionCallback? {
    get { selectionStorage.onSelection }
    set { selectionStorage.onSelection = newValue }
  }

  public init(
    tabs: [FKFilterTab<TabID>],
    panelFactory: FKFilterPanelFactory,
    configuration: FKAnchoredDropdownConfiguration = .default,
    tabBarHost: (any FKAnchoredDropdownTabBarHost)? = nil,
    callbacks: FKAnchoredDropdownConfiguration.Callbacks<TabID> = .init(),
    onSelection: FKFilterSelectionCallback? = nil
  ) {
    self.filterTabs = tabs
    self.panelFactory = panelFactory
    selectionStorage.onSelection = onSelection
    self.dropdownController = FKAnchoredDropdownController(
      tabs: Self.makeAnchoredTabs(
        tabs: tabs,
        panelFactory: panelFactory,
        selectionStorage: selectionStorage,
        dismissBond: dismissBond,
        titleOverrideStore: titleOverrideStore
      ),
      tabBarHost: tabBarHost,
      configuration: configuration,
      callbacks: callbacks
    )
    super.init(nibName: nil, bundle: nil)
    dismissBond.dropdown = dropdownController
  }

  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear
    addChild(dropdownController)
    dropdownController.loadViewIfNeeded()
    guard let hostView = dropdownController.view else {
      assertionFailure("FKFilterController child view is missing after loadViewIfNeeded()")
      return
    }
    hostView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(hostView)
    NSLayoutConstraint.activate([
      hostView.topAnchor.constraint(equalTo: view.topAnchor),
      hostView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      hostView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      hostView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    dropdownController.didMove(toParent: self)
  }

  /// Replaces the tab descriptors and rebuilds the anchored tab list (see ``FKAnchoredDropdownController/setTabs(_:)``).
  ///
  /// Clears tab title overrides so they do not carry over to the new tab set.
  public func setFilterTabs(_ tabs: [FKFilterTab<TabID>]) {
    filterTabs = tabs
    titleOverrideStore.removeAll()
    dropdownController.setTabs(
      Self.makeAnchoredTabs(
        tabs: tabs,
        panelFactory: panelFactory,
        selectionStorage: selectionStorage,
        dismissBond: dismissBond,
        titleOverrideStore: titleOverrideStore
      )
    )
  }

  /// Clears the tab bar title override for one tab so the bar shows ``FKFilterTab/title`` again.
  public func clearTabTitleOverride(for tabID: TabID) {
    titleOverrideStore.removeTitle(for: tabID)
    dropdownController.reloadTabBarItems()
  }

  /// Clears all tab bar title overrides.
  public func clearAllTabTitleOverrides() {
    titleOverrideStore.removeAll()
    dropdownController.reloadTabBarItems()
  }

  /// Invalidates cached panel content for a tab when factory data changes (see ``FKAnchoredDropdownController/invalidateCachedContent(for:)``).
  public func invalidateCachedPanelContent(for tab: TabID) {
    dropdownController.invalidateCachedContent(for: tab)
  }

  /// Pins the anchored dropdown’s **overlay host** (dimming + sheet layout bounds) to a larger view than this controller’s own bounds.
  ///
  /// By default the overlay uses ``FKAnchoredDropdownTabBarHost/view``, which is only as tall as your tab strip. The anchor layout then
  /// computes downward ``availableHeight`` from that small bounds, which often collapses to **~0** when this controller’s height is fixed
  /// to the strip (see ``FKPresentationAnchorLayout``). Pass the hosting screen container—typically the parent view controller’s `view`.
  public func pinAnchoredPresentationOverlay(to hostView: UIView) {
    dropdownController.setCustomAnchor(source: dropdownController.tabBar, overlayHost: hostView)
  }

  private static func makeAnchoredTabs(
    tabs: [FKFilterTab<TabID>],
    panelFactory: FKFilterPanelFactory,
    selectionStorage: FKFilterSelectionCallbackStorage,
    dismissBond: FKFilterDropdownDismissBond<TabID>,
    titleOverrideStore: FKFilterTabTitleOverrideStore<TabID>
  ) -> [FKAnchoredDropdownTab<TabID>] {
    tabs.map { tab in
      let tabID = tab.id
      let baseTitle = tab.title
      let titleForBar: () -> String = {
        titleOverrideStore.displayTitle(for: tabID, fallback: baseTitle)
      }
      return FKAnchoredDropdownTab.chevronTitle(
        id: tab.id,
        title: titleForBar,
        subtitle: tab.subtitle,
        titleFont: UIFont.preferredFont(forTextStyle: tab.titleTextStyle),
        subtitleFont: UIFont.preferredFont(forTextStyle: tab.subtitleTextStyle),
        chevronSize: tab.chevronSize,
        chevronSpacing: tab.chevronSpacing,
        titleSubtitleSpacing: tab.titleSubtitleSpacing,
        content: .viewController {
          panelFactory.makePanel(
            for: tab.panelKind,
            allowsMultipleSelection: tab.allowsMultipleSelection,
            onSelectItem: { sectionID, item, mode in
              if mode == .single {
                titleOverrideStore.setTitle(item.title, for: tab.id)
                dismissBond.dropdown?.reloadTabBarItems()
              }
              selectionStorage.onSelection?(tab.panelKind, sectionID, item, mode)
              dismissBond.dismissAfterSelectionIfNeeded(effectiveMode: mode)
            }
          ) ?? UIViewController()
        }
      )
    }
  }
}
