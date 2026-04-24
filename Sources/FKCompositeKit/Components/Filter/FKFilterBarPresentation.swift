import UIKit
import FKUIKit

/// Local dismissal reasons aligned with the legacy `FKBarPresentation` contract.
public enum FKFilterBarPresentationDismissReason: Equatable, Sendable {
  case maskTap
  case programmatic
  case selectionChanged
  case selectionCleared
}

public protocol FKFilterBarPresentationDelegate: AnyObject {
  func filterBarPresentation(_ bar: FKFilterBarPresentation, willPresentPanel panel: FKFilterBarPresentation.PanelKind)
  func filterBarPresentation(_ bar: FKFilterBarPresentation, didPresentPanel panel: FKFilterBarPresentation.PanelKind)
  func filterBarPresentation(_ bar: FKFilterBarPresentation, didDismissPanel panel: FKFilterBarPresentation.PanelKind?)
  /// Return `false` to prevent the panel from being presented.
  func filterBarPresentation(
    _ bar: FKFilterBarPresentation,
    shouldPresentPanel panel: FKFilterBarPresentation.PanelKind,
    for barItem: FKFilterBarPresentation.BarItemModel,
    at index: Int
  ) -> Bool

  /// Called when the panel is about to be dismissed (mask tap, selection change, programmatic dismiss, etc.).
  func filterBarPresentation(
    _ bar: FKFilterBarPresentation,
    willDismissPanel panel: FKFilterBarPresentation.PanelKind?,
    reason: FKFilterBarPresentationDismissReason
  )
  func filterBarPresentation(
    _ bar: FKFilterBarPresentation,
    didSelectBarItem item: FKFilterBarPresentation.BarItemModel,
    at index: Int
  )
  func filterBarPresentation(
    _ bar: FKFilterBarPresentation,
    didSelect item: FKFilterOptionItem,
    in panel: FKFilterBarPresentation.PanelKind,
    sectionID: FKFilterID?
  )
}

public extension FKFilterBarPresentationDelegate {
  func filterBarPresentation(_ bar: FKFilterBarPresentation, willPresentPanel panel: FKFilterBarPresentation.PanelKind) {}
  func filterBarPresentation(_ bar: FKFilterBarPresentation, didPresentPanel panel: FKFilterBarPresentation.PanelKind) {}
  func filterBarPresentation(_ bar: FKFilterBarPresentation, didDismissPanel panel: FKFilterBarPresentation.PanelKind?) {}
  func filterBarPresentation(
    _ bar: FKFilterBarPresentation,
    shouldPresentPanel panel: FKFilterBarPresentation.PanelKind,
    for barItem: FKFilterBarPresentation.BarItemModel,
    at index: Int
  ) -> Bool { true }

  func filterBarPresentation(
    _ bar: FKFilterBarPresentation,
    willDismissPanel panel: FKFilterBarPresentation.PanelKind?,
    reason: FKFilterBarPresentationDismissReason
  ) {}
  func filterBarPresentation(
    _ bar: FKFilterBarPresentation,
    didSelectBarItem item: FKFilterBarPresentation.BarItemModel,
    at index: Int
  ) {}
  func filterBarPresentation(
    _ bar: FKFilterBarPresentation,
    didSelect item: FKFilterOptionItem,
    in panel: FKFilterBarPresentation.PanelKind,
    sectionID: FKFilterID?
  ) {}
}

/// A reusable filter bar built on `FKTabBar` + `FKPresentation`.
public final class FKFilterBarPresentation: UIView {
  /// Extensible panel identifier. Use predefined static values or custom string literals.
  public struct PanelKind: Hashable, Sendable, RawRepresentable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.rawValue = value }

    // Generic presets.
    public static let hierarchy: PanelKind = "hierarchy"
    public static let dualHierarchy: PanelKind = "dualHierarchy"
    public static let gridPrimary: PanelKind = "gridPrimary"
    public static let gridSecondary: PanelKind = "gridSecondary"
    public static let tags: PanelKind = "tags"
    public static let singleList: PanelKind = "singleList"
  }

  public struct BarItemModel: Hashable, Sendable {
    public let id: FKFilterID
    public var title: String
    public var subtitle: String?
    /// Rich text title used when present; plain `title` acts as fallback.
    public var attributedTitle: AttributedString?
    /// Rich text subtitle used when present; plain `subtitle` acts as fallback.
    public var attributedSubtitle: AttributedString?
    public var panelKind: PanelKind
    /// Per-item gate for multi-select. Default `false`: single-select only (one tap finishes and dismisses).
    /// Panel content still uses `FKFilterSection.selectionMode`; both must allow multiple for true multi-select.
    public var allowsMultipleSelection: Bool

    public init(
      id: FKFilterID,
      title: String,
      subtitle: String? = nil,
      attributedTitle: AttributedString? = nil,
      attributedSubtitle: AttributedString? = nil,
      panelKind: PanelKind,
      allowsMultipleSelection: Bool = false
    ) {
      self.id = id
      self.title = title
      self.subtitle = subtitle
      self.attributedTitle = attributedTitle
      self.attributedSubtitle = attributedSubtitle
      self.panelKind = panelKind
      self.allowsMultipleSelection = allowsMultipleSelection
    }
  }

  public var makePanelViewController: ((PanelKind) -> UIViewController?)?
  public weak var delegate: FKFilterBarPresentationDelegate?
  public var onSelectItem: ((PanelKind, FKFilterOptionItem, FKFilterID?) -> Void)?
  /// Called right before the panel is presented (after selection and `shouldPresentPanel`).
  public var onWillPresentPanel: ((PanelKind) -> Void)?
  /// Called after the panel is presented.
  public var onDidPresentPanel: ((PanelKind) -> Void)?
  /// Called after the panel is dismissed. `nil` means the panel kind couldn't be resolved.
  public var onDidDismissPanel: ((PanelKind?) -> Void)?
  public var configuration: Configuration = .default {
    didSet {
      applyConfiguration()
      reloadTabItems(keepSelectedIndex: tabBar.selectedIndex)
    }
  }

  /// Called when the user selects a bar segment (tab). Index matches ``setItems(_:)`` order.
  /// Panel presentation follows this component; use this for analytics or syncing external UI.
  public var onBarTabSelected: ((Int, BarItemModel) -> Void)?
  
  private let tabBar: FKTabBar = {
    let t = FKTabBar(items: [], selectedIndex: 0)
    t.translatesAutoresizingMaskIntoConstraints = false
    return t
  }()
  private let panel: FKPresentation = {
    let p = FKPresentation()
    return p
  }()
  private var barModels: [BarItemModel] = []
  fileprivate var panelKind: PanelKind?
  private var passthroughViews: [UIView] = []
  fileprivate var scheduledDismissReason: FKFilterBarPresentationDismissReason?
  private let panelDelegateSink = PanelDelegateSink()

  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  private func commonInit() {
    backgroundColor = .systemBackground
    addSubview(tabBar)
    NSLayoutConstraint.activate([
      tabBar.topAnchor.constraint(equalTo: topAnchor),
      tabBar.bottomAnchor.constraint(equalTo: bottomAnchor),
      tabBar.leadingAnchor.constraint(equalTo: leadingAnchor),
      tabBar.trailingAnchor.constraint(equalTo: trailingAnchor),
    ])

    applyConfiguration()
    panelDelegateSink.owner = self
    panel.delegate = panelDelegateSink
    tabBar.onSelectionChanged = { [weak self] item, index, reason in
      guard let self else { return }
      guard let model = self.barModels.first(where: { $0.id.rawValue == item.id }) ?? self.barModels[safe: index] else { return }

      // If the same panel is already presented for the same tab, ignore repeated selection.
      if self.panel.isPresented, self.panelKind == model.panelKind {
        return
      }

      // Switching selection while a panel is shown is treated as a selection-change dismissal.
      if self.panel.isPresented {
        self.scheduledDismissReason = .selectionChanged
        self.panel.dismiss(animated: false, completion: nil)
      }

      self.panelKind = model.panelKind
      self.onBarTabSelected?(index, model)
      self.delegate?.filterBarPresentation(self, didSelectBarItem: model, at: index)

      if self.delegate?.filterBarPresentation(self, shouldPresentPanel: model.panelKind, for: model, at: index) == false {
        return
      }
      self.presentPanel(for: model, at: index, reason: reason)
    }
  }

  public func setItems(_ items: [BarItemModel]) {
    barModels = items
    reloadTabItems(keepSelectedIndex: tabBar.selectedIndex)
  }

  fileprivate func barItemModel(at index: Int) -> BarItemModel? {
    barModels[safe: index]
  }

  public func dismiss(animated: Bool = true) {
    scheduledDismissReason = .programmatic
    panel.dismiss(animated: animated, completion: nil)
  }

  /// Central entry for panel item selection.
  /// - Updates bar title
  /// - Optionally dismisses the panel (single-select by default)
  /// - Notifies delegate / closure
  public func handlePanelSelection(
    panelKind: PanelKind,
    sectionID: FKFilterID?,
    item: FKFilterOptionItem,
    selectionMode: FKFilterSelectionMode
  ) {
    let effectiveMode: FKFilterSelectionMode = {
      guard allowsMultipleSelection(for: panelKind) else { return .single }
      return selectionMode
    }()

    updateBarTitle(for: panelKind, from: item, selectionMode: effectiveMode)
    delegate?.filterBarPresentation(self, didSelect: item, in: panelKind, sectionID: sectionID)
    onSelectItem?(panelKind, item, sectionID)

    if effectiveMode == .single {
      dismiss(animated: true)
    }
  }

  private func allowsMultipleSelection(for panelKind: PanelKind) -> Bool {
    barModels.first(where: { $0.panelKind == panelKind })?.allowsMultipleSelection ?? false
  }

  /// Whether the bar item for `panelKind` allows multi-select in the panel (default `false`).
  public func isMultipleSelectionEnabled(for panelKind: PanelKind) -> Bool {
    allowsMultipleSelection(for: panelKind)
  }

  public func updateBarTitle(_ title: String, for panelKind: PanelKind) {
    guard let idx = barModels.firstIndex(where: { $0.panelKind == panelKind }) else { return }
    barModels[idx].title = title
    barModels[idx].attributedTitle = nil
    reloadTabItems(keepSelectedIndex: tabBar.selectedIndex)
  }

  private func reloadTabItems(keepSelectedIndex: Int?) {
    let models = barModels
    let items: [FKTabBarItem] = models.enumerated().map { idx, m in
      FKTabBarItem(
        id: m.id.rawValue,
        title: FKTabBarTextConfiguration(
          normal: .init(text: m.title)
        ),
        subtitle: m.subtitle.map { FKTabBarTextConfiguration(normal: .init(text: $0)) }
      )
    }
    tabBar.reload(items: items, updatePolicy: .preserveSelection)
    if let keepSelectedIndex, keepSelectedIndex >= 0, keepSelectedIndex < items.count {
      tabBar.setSelectedIndex(keepSelectedIndex, animated: false, notify: false, reason: .programmatic)
    }
  }

  private func updateBarTitle(for panelKind: PanelKind, from item: FKFilterOptionItem, selectionMode: FKFilterSelectionMode) {
    switch selectionMode {
    case .single:
      updateBarTitle(item.title, for: panelKind)
    case .multiple:
      // For multi-select, we can't infer full selected set from a single tapped item here.
      // Keep a stable title; callers may choose to call `updateBarTitle(_:for:)` with "标签(3)" etc.
      break
    }
  }

  private func applyConfiguration() {
    tabBar.appearance = configuration.tabBarAppearance
    tabBar.layoutConfiguration = configuration.tabBarLayout
    panel.configuration = configuration.presentationConfiguration

    tabBar.itemButtonConfigurator = { [weak self] button, item, isSelected in
      guard let self else { return }
      // Title/subtitle colors follow configuration.barItemAppearance to keep existing look.
      let a = self.configuration.barItemAppearance
      let titleText = item.title.resolved(isSelected: isSelected, isEnabled: item.isEnabled).text ?? ""
      let title = FKButton.LabelAttributes(
        text: titleText,
        font: a.titleFont,
        color: isSelected ? a.selectedTitleColor : a.normalTitleColor,
        alignment: a.titleAlignment
      )
      button.setTitle(title, for: .normal)
      button.setTitle(title, for: .selected)
      if let subtitle = item.subtitle?.resolved(isSelected: isSelected, isEnabled: item.isEnabled).text, !subtitle.isEmpty {
        let sub = FKButton.LabelAttributes(
          text: subtitle,
          font: a.subtitleFont,
          color: isSelected ? a.selectedSubtitleColor : a.normalSubtitleColor,
          alignment: a.subtitleAlignment,
          contentInsets: .init(top: a.titleSubtitleSpacing, leading: 0, bottom: 0, trailing: 0)
        )
        button.setSubtitle(sub, for: .normal)
        button.setSubtitle(sub, for: .selected)
      }

      // Chevron: use trailing image, swap up/down by selection.
      button.content = FKButton.Content(kind: .textAndImage(.trailing))
      let sym = UIImage.SymbolConfiguration(pointSize: a.chevronPointSize, weight: .semibold)
      let image = FKButton.ImageAttributes(
        systemName: isSelected ? "chevron.up" : "chevron.down",
        symbolConfiguration: sym,
        tintColor: isSelected ? a.selectedChevronColor : a.normalChevronColor,
        fixedSize: CGSize(width: 14, height: 14),
        spacingToTitle: a.chevronSpacing
      )
      button.setTrailingImage(image, for: .normal)
      button.setTrailingImage(image, for: .selected)
    }
  }
  
  public override func didMoveToSuperview() {
    super.didMoveToSuperview()
    // Presentation host is the current superview if available; fall back to window.
    passthroughViews = [tabBar]
  }
}

private extension FKFilterBarPresentation {
  func resolvePresentationHost() -> UIView? {
    superview ?? window
  }

  func presentPanel(for model: BarItemModel, at index: Int, reason: FKTabBar.SelectionReason) {
    guard let host = resolvePresentationHost(), host.bounds.width > 0 else { return }
    let anchor: UIView = tabBar.visibleItemButton(at: index) ?? tabBar
    guard let vc = makePanelViewController?(model.panelKind) else { return }

    delegate?.filterBarPresentation(self, willPresentPanel: model.panelKind)
    onWillPresentPanel?(model.panelKind)

    panel.show(from: anchor, sourceRect: nil, content: vc, in: host, animated: true, completion: { [weak self] in
      guard let self else { return }
      self.delegate?.filterBarPresentation(self, didPresentPanel: model.panelKind)
      self.onDidPresentPanel?(model.panelKind)
    })
  }
}

private final class PanelDelegateSink: FKPresentationDelegate {
  weak var owner: FKFilterBarPresentation?

  func presentationWillDismiss(_ presentation: FKPresentation) {
    guard let owner else { return }
    let reason = owner.scheduledDismissReason ?? .maskTap
    owner.delegate?.filterBarPresentation(owner, willDismissPanel: owner.panelKind, reason: reason)
  }

  func presentationDidDismiss(_ presentation: FKPresentation) {
    guard let owner else { return }
    owner.delegate?.filterBarPresentation(owner, didDismissPanel: owner.panelKind)
    owner.onDidDismissPanel?(owner.panelKind)
    owner.panelKind = nil
    owner.scheduledDismissReason = nil
  }
}
