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

@MainActor
private final class FKFilterDropdownDismissBond<TabID: Hashable> {
  weak var dropdown: FKAnchoredDropdownController<TabID>?

  func dismissAfterSelectionIfNeeded(effectiveMode: FKFilterSelectionMode) {
    guard effectiveMode == .single else { return }
    dropdown?.collapsePanel(animated: true)
  }
}

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

/// Filter bar plus anchored dropdown, driven by ``FKFilterPanelFactory``.
@MainActor
public final class FKFilterController<TabID: Hashable>: UIViewController {
  public let dropdownController: FKAnchoredDropdownController<TabID>
  public let panelFactory: FKFilterPanelFactory

  private var filterTabs: [FKFilterTab<TabID>]
  private let selectionStorage = FKFilterSelectionCallbackStorage()
  private let dismissBond = FKFilterDropdownDismissBond<TabID>()
  private let titleOverrideStore = FKFilterTabTitleOverrideStore<TabID>()

  /// Called when a panel reports a selection (after the panel updates its model via `onChange`).
  ///
  /// For single-select panels the tab title updates to the picked item, then the panel collapses.
  public var onSelection: FKFilterSelectionCallback? {
    get { selectionStorage.onSelection }
    set { selectionStorage.onSelection = newValue }
  }

  public init(
    tabs: [FKFilterTab<TabID>],
    panelFactory: FKFilterPanelFactory,
    configuration: FKAnchoredDropdownConfiguration = .default,
    tabBarHost: (any FKAnchoredDropdownTabBarHost)? = nil,
    events: FKAnchoredDropdownConfiguration.Events<TabID> = .init(),
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
      events: events
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

  /// Replaces filter tabs and refreshes the anchored bar. Clears title overrides.
  public func setFilterTabs(_ tabs: [FKFilterTab<TabID>]) {
    filterTabs = tabs
    titleOverrideStore.removeAll()
    dropdownController.updateTabs(
      Self.makeAnchoredTabs(
        tabs: tabs,
        panelFactory: panelFactory,
        selectionStorage: selectionStorage,
        dismissBond: dismissBond,
        titleOverrideStore: titleOverrideStore
      )
    )
  }

  public func clearTabTitleOverride(for tabID: TabID) {
    titleOverrideStore.removeTitle(for: tabID)
    dropdownController.reloadTabBarItems()
  }

  public func clearAllTabTitleOverrides() {
    titleOverrideStore.removeAll()
    dropdownController.reloadTabBarItems()
  }

  public func invalidateCachedPanelContent(for tab: TabID) {
    dropdownController.invalidateCachedContent(for: tab)
  }

  /// Pins mask and panel layout to `hostView` (e.g. the parent screen’s root view) while keeping the tab bar as the anchor source.
  public func pinAnchoredPresentationOverlay(to hostView: UIView) {
    dropdownController.setAnchor(source: dropdownController.tabBar, overlayHost: hostView)
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
