import UIKit

/// Called after the panel updates its model when the user selects an option.
public typealias FKFilterItemSelectionHandler = @MainActor (
  _ panelKind: FKFilterPanelKind,
  _ sectionID: FKFilterID?,
  _ item: FKFilterOptionItem,
  _ effectiveSelectionMode: FKFilterSelectionMode
) -> Void

@MainActor
private final class FKFilterRuntimeState<TabID: Hashable> {
  weak var dropdown: FKAnchoredDropdownController<TabID>?
  var onItemSelected: FKFilterItemSelectionHandler?
  private var titleOverrides: [TabID: String] = [:]

  func displayTitle(for id: TabID, fallback: @escaping () -> String) -> String {
    titleOverrides[id] ?? fallback()
  }

  func setTitleOverride(_ title: String, for id: TabID) {
    titleOverrides[id] = title
  }

  func removeTitleOverride(for id: TabID) {
    titleOverrides[id] = nil
  }

  func removeAllTitleOverrides() {
    titleOverrides.removeAll(keepingCapacity: false)
  }

  func dismissIfSingleSelect(mode: FKFilterSelectionMode) {
    guard mode == .single else { return }
    dropdown?.collapsePanel(animated: true)
  }
}

/// Filter strip plus anchored dropdown panels, built from ``FKFilterPanelFactory``.
@MainActor
public final class FKFilterController<TabID: Hashable>: UIViewController {
  public let dropdownController: FKAnchoredDropdownController<TabID>
  public let panelFactory: FKFilterPanelFactory

  private var filterTabs: [FKFilterTab<TabID>]
  private let runtime = FKFilterRuntimeState<TabID>()

  /// Invoked after the panel applies the selection; single-select panels also update the tab title and collapse.
  public var onItemSelected: FKFilterItemSelectionHandler? {
    get { runtime.onItemSelected }
    set { runtime.onItemSelected = newValue }
  }

  public init(
    tabs: [FKFilterTab<TabID>],
    panelFactory: FKFilterPanelFactory,
    configuration: FKAnchoredDropdownConfiguration = .default,
    tabBarHost: (any FKAnchoredDropdownTabBarHost)? = nil,
    events: FKAnchoredDropdownConfiguration.Events<TabID> = .init(),
    onItemSelected: FKFilterItemSelectionHandler? = nil
  ) {
    self.filterTabs = tabs
    self.panelFactory = panelFactory
    runtime.onItemSelected = onItemSelected
    self.dropdownController = FKAnchoredDropdownController(
      tabs: Self.makeAnchoredTabs(tabs: tabs, panelFactory: panelFactory, runtime: runtime),
      tabBarHost: tabBarHost,
      configuration: configuration,
      events: events
    )
    super.init(nibName: nil, bundle: nil)
    runtime.dropdown = dropdownController
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

  /// Replaces tabs, clears title overrides, and reloads the strip.
  public func replaceTabs(_ tabs: [FKFilterTab<TabID>]) {
    filterTabs = tabs
    runtime.removeAllTitleOverrides()
    dropdownController.updateTabs(
      Self.makeAnchoredTabs(tabs: tabs, panelFactory: panelFactory, runtime: runtime)
    )
  }

  public func removeTitleOverride(for tabID: TabID) {
    runtime.removeTitleOverride(for: tabID)
    dropdownController.reloadTabBarItems()
  }

  public func removeAllTitleOverrides() {
    runtime.removeAllTitleOverrides()
    dropdownController.reloadTabBarItems()
  }

  public func invalidateCachedPanelContent(for tab: TabID) {
    dropdownController.invalidateCachedContent(for: tab)
  }

  /// Pins mask and panel layout to `hostView` while the tab bar remains the anchor source.
  public func pinAnchoredPresentationOverlay(to hostView: UIView) {
    dropdownController.setAnchor(source: dropdownController.tabBar, overlayHost: hostView)
  }

  private static func makeAnchoredTabs(
    tabs: [FKFilterTab<TabID>],
    panelFactory: FKFilterPanelFactory,
    runtime: FKFilterRuntimeState<TabID>
  ) -> [FKAnchoredDropdownTab<TabID>] {
    tabs.map { tab in
      let tabID = tab.id
      let baseTitle = tab.title
      let m = tab.stripMetrics
      let titleForBar: () -> String = {
        runtime.displayTitle(for: tabID, fallback: baseTitle)
      }
      return FKAnchoredDropdownTab.chevronTitle(
        id: tab.id,
        title: titleForBar,
        subtitle: tab.subtitle,
        titleFont: UIFont.preferredFont(forTextStyle: m.titleTextStyle),
        subtitleFont: UIFont.preferredFont(forTextStyle: m.subtitleTextStyle),
        chevronSize: m.chevronSize,
        chevronSpacing: m.chevronSpacing,
        titleSubtitleSpacing: m.titleSubtitleSpacing,
        content: .viewController {
          panelFactory.makePanel(
            for: tab.panelKind,
            allowsMultipleSelection: tab.allowsMultipleSelection,
            onSelectItem: { sectionID, item, mode in
              if mode == .single {
                runtime.setTitleOverride(item.title, for: tab.id)
                runtime.dropdown?.reloadTabBarItems()
              }
              runtime.onItemSelected?(tab.panelKind, sectionID, item, mode)
              runtime.dismissIfSingleSelect(mode: mode)
            }
          ) ?? UIViewController()
        }
      )
    }
  }
}
