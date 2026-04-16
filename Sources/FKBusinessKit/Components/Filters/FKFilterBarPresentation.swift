import UIKit
import FKUIKit

public protocol FKFilterBarPresentationDelegate: AnyObject {
  func filterBarPresentation(
    _ bar: FKFilterBarPresentation,
    didSelect item: FKFilterOptionItem,
    in panel: FKFilterBarPresentation.PanelKind,
    sectionID: FKFilterID?
  )
}

public extension FKFilterBarPresentationDelegate {
  func filterBarPresentation(
    _ bar: FKFilterBarPresentation,
    didSelect item: FKFilterOptionItem,
    in panel: FKFilterBarPresentation.PanelKind,
    sectionID: FKFilterID?
  ) {}
}

/// A reusable filter bar built on `FKBarPresentation`.
public final class FKFilterBarPresentation: UIView {
  public enum PanelKind: Hashable, Sendable {
    case twoColumn
    case courseTwoColumn
    case fileTypeChips
    case platformChips
    case tagsChips
    case sortList
  }

  public struct BarItemModel: Hashable, Sendable {
    public let id: FKFilterID
    public var title: String
    public var panelKind: PanelKind
    /// Per-item gate for multi-select. Default `false`: single-select only (one tap finishes and dismisses).
    /// Panel content still uses `FKFilterSection.selectionMode`; both must allow multiple for true multi-select.
    public var allowsMultipleSelection: Bool

    public init(id: FKFilterID, title: String, panelKind: PanelKind, allowsMultipleSelection: Bool = false) {
      self.id = id
      self.title = title
      self.panelKind = panelKind
      self.allowsMultipleSelection = allowsMultipleSelection
    }
  }

  private let barPresentation = FKBarPresentation()
  private var barModels: [BarItemModel] = []

  public var makePanelViewController: ((PanelKind) -> UIViewController?)?
  public weak var delegate: FKFilterBarPresentationDelegate?
  public var onSelectItem: ((PanelKind, FKFilterOptionItem, FKFilterID?) -> Void)?

  /// Called when the user selects a bar segment (tab). Index matches ``setItems(_:)`` order.
  /// Panel presentation still follows `FKBarPresentation`; use this for analytics or syncing external UI.
  public var onBarTabSelected: ((Int, BarItemModel) -> Void)?

  private let barTabDelegateSink = BarTabDelegateSink()

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
    barPresentation.translatesAutoresizingMaskIntoConstraints = false
    addSubview(barPresentation)
    NSLayoutConstraint.activate([
      barPresentation.topAnchor.constraint(equalTo: topAnchor),
      barPresentation.bottomAnchor.constraint(equalTo: bottomAnchor),
      barPresentation.leadingAnchor.constraint(equalTo: leadingAnchor),
      barPresentation.trailingAnchor.constraint(equalTo: trailingAnchor),
    ])

    applyDefaultConfiguration()

    barTabDelegateSink.owner = self
    barPresentation.barDelegate = barTabDelegateSink

    barPresentation.presentationViewController = { [weak self] _, index, _ in
      guard let self else { return nil }
      guard let model = self.barModels[safe: index] else { return nil }
      return self.makePanelViewController?(model.panelKind)
    }
  }

  public func setItems(_ items: [BarItemModel]) {
    barModels = items
    barPresentation.reloadBarItems(items.map(makeBarItem(_:)), animated: false)
  }

  fileprivate func barItemModel(at index: Int) -> BarItemModel? {
    barModels[safe: index]
  }

  public func dismiss(animated: Bool = true) {
    barPresentation.dismissPresentation(animated: animated, completion: nil)
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
    reloadBarTitles(keepSelectedIndex: barPresentation.bar.selectedIndex)
  }

  private func makeBarItem(_ model: BarItemModel) -> FKBar.Item {
    let bodyFont = UIFont.preferredFont(forTextStyle: .callout)

    var spec = FKBar.Item.FKButtonSpec()
    spec.content = FKButton.Content(kind: .textAndImage(.trailing))
    spec.axis = .horizontal

    spec.setTitle(
      FKButton.Text(text: model.title, font: bodyFont, color: .label),
      for: .normal
    )
    spec.setTitle(
      FKButton.Text(text: model.title, font: bodyFont, color: .systemRed),
      for: .selected
    )

    let downConfig = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
    let down = FKButton.Image(
      systemName: "chevron.down",
      symbolConfiguration: downConfig,
      tintColor: .secondaryLabel,
      fixedSize: CGSize(width: 14, height: 14),
      spacingToTitle: 4
    )
    let up = FKButton.Image(
      systemName: "chevron.up",
      symbolConfiguration: downConfig,
      tintColor: .systemRed,
      fixedSize: CGSize(width: 14, height: 14),
      spacingToTitle: 4
    )
    spec.setImage(down, for: .normal, slot: .trailing)
    spec.setImage(up, for: .selected, slot: .trailing)

    spec.setAppearance(
      FKButton.Appearance(cornerStyle: .init(corner: .none), backgroundColor: .clear),
      for: .normal
    )
    spec.setAppearance(
      FKButton.Appearance(cornerStyle: .init(corner: .none), backgroundColor: .clear),
      for: .selected
    )

    return FKBar.Item(
      id: model.id.rawValue,
      mode: .fkButton(spec),
      isSelected: false,
      selectionBehavior: .toggle
    )
  }

  private func reloadBarTitles(keepSelectedIndex: Int?) {
    // Rebuild items to refresh titles. Keep current selection so the arrow stays "up" while panel is visible.
    let items: [FKBar.Item] = barModels.enumerated().map { idx, m in
      var item = makeBarItem(m)
      item.isSelected = (keepSelectedIndex == idx)
      return item
    }
    barPresentation.reloadBarItems(items, animated: false)
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

  private func applyDefaultConfiguration() {
    var barCfg = FKBar.Configuration.default
    barCfg.itemSpacing = 0
    barCfg.arrangement = .around
    barCfg.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
    barCfg.appearance.backgroundColor = .systemBackground
    barCfg.selectionScroll.isEnabled = false
    barCfg.usesDefaultSelectionAppearance = false

    var pres = FKPresentation.Configuration.default
    pres.layout.widthMode = .fullWidth
    pres.layout.horizontalAlignment = .center
    pres.layout.verticalSpacing = 0
    pres.layout.preferBelowSource = true
    pres.layout.allowFlipToAbove = false
    pres.layout.clampToSafeArea = false

    pres.mask.enabled = true
    pres.mask.tapToDismissEnabled = true
    pres.mask.alpha = 0.25

    pres.appearance.backgroundColor = .systemBackground
    pres.appearance.alpha = 1
    // Bottom corners only (panel attaches flush to the bar on top).
    pres.appearance.cornerRadius = 10
    pres.appearance.cornerCurve = .continuous
    pres.appearance.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    pres.appearance.shadow = nil

    pres.content.containerInsets = .zero
    pres.content.fallbackBackgroundColor = .systemBackground

    barPresentation.configuration = FKBarPresentation.Configuration(
      bar: barCfg,
      presentation: pres,
      behavior: .init()
    )
  }
  
  public override func didMoveToSuperview() {
    super.didMoveToSuperview()
    guard let host = superview else { return }
    barPresentation.configuration.presentationHost = .explicit(host)
  }
}

private final class BarTabDelegateSink: NSObject, FKBarDelegate {
  weak var owner: FKFilterBarPresentation?

  func bar(_ bar: FKBar, didSelect sender: UIView, for item: FKBar.Item, at index: Int) {
    guard let owner, let model = owner.barItemModel(at: index) else { return }
    owner.onBarTabSelected?(index, model)
  }
}

private extension Array {
  subscript(safe index: Int) -> Element? {
    guard indices.contains(index) else { return nil }
    return self[index]
  }
}

