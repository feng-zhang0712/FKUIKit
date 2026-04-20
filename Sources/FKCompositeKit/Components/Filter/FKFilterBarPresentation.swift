import UIKit
import FKUIKit

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
    reason: FKBarPresentation.PresentationDismissReason
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
    reason: FKBarPresentation.PresentationDismissReason
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

/// A reusable filter bar built on `FKBarPresentation`.
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
      reloadBarTitles(keepSelectedIndex: barPresentation.bar.selectedIndex)
    }
  }

  /// Called when the user selects a bar segment (tab). Index matches ``setItems(_:)`` order.
  /// Panel presentation still follows `FKBarPresentation`; use this for analytics or syncing external UI.
  public var onBarTabSelected: ((Int, BarItemModel) -> Void)?
  
  private let barPresentation = FKBarPresentation()
  private var barModels: [BarItemModel] = []
  fileprivate var panelKind: PanelKind?
  private let presentationDelegateSink = PresentationDelegateSink()

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

    applyConfiguration()

    barTabDelegateSink.owner = self
    barPresentation.barDelegate = barTabDelegateSink
    presentationDelegateSink.owner = self
    barPresentation.delegate = presentationDelegateSink

    barPresentation.presentationViewController = { [weak self] _, index, _ in
      guard let self else { return nil }
      guard let model = self.barModels[safe: index] else { return nil }
      self.panelKind = model.panelKind
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
    barModels[idx].attributedTitle = nil
    reloadBarTitles(keepSelectedIndex: barPresentation.bar.selectedIndex)
  }

  private func makeBarItem(_ model: BarItemModel) -> FKBar.Item {
    let appearance = configuration.barItemAppearance

    var spec = FKBar.Item.FKButtonSpec()
    spec.content = FKButton.Content(kind: .textAndImage(.trailing))
    spec.axis = .horizontal

    spec.setTitle(
      FKButton.LabelAttributes(
        text: model.title,
        attributedText: model.attributedTitle.map(NSAttributedString.init),
        font: appearance.titleFont,
        color: appearance.normalTitleColor,
        alignment: appearance.titleAlignment
      ),
      for: .normal
    )
    spec.setTitle(
      FKButton.LabelAttributes(
        text: model.title,
        attributedText: model.attributedTitle.map(NSAttributedString.init),
        font: appearance.titleFont,
        color: appearance.selectedTitleColor,
        alignment: appearance.titleAlignment
      ),
      for: .selected
    )
    if model.subtitle != nil || model.attributedSubtitle != nil {
      spec.setSubtitle(
        FKButton.LabelAttributes(
          text: model.subtitle,
          attributedText: model.attributedSubtitle.map(NSAttributedString.init),
          font: appearance.subtitleFont,
          color: appearance.normalSubtitleColor,
          alignment: appearance.subtitleAlignment,
          contentInsets: .init(
            top: appearance.titleSubtitleSpacing,
            leading: 0,
            bottom: 0,
            trailing: 0
          )
        ),
        for: .normal
      )
      spec.setSubtitle(
        FKButton.LabelAttributes(
          text: model.subtitle,
          attributedText: model.attributedSubtitle.map(NSAttributedString.init),
          font: appearance.subtitleFont,
          color: appearance.selectedSubtitleColor,
          alignment: appearance.subtitleAlignment,
          contentInsets: .init(
            top: appearance.titleSubtitleSpacing,
            leading: 0,
            bottom: 0,
            trailing: 0
          )
        ),
        for: .selected
      )
    }

    let downConfig = UIImage.SymbolConfiguration(pointSize: appearance.chevronPointSize, weight: .semibold)
    let down = FKButton.ImageAttributes(
      systemName: "chevron.down",
      symbolConfiguration: downConfig,
      tintColor: appearance.normalChevronColor,
      fixedSize: CGSize(width: 14, height: 14),
      spacingToTitle: appearance.chevronSpacing
    )
    let up = FKButton.ImageAttributes(
      systemName: "chevron.up",
      symbolConfiguration: downConfig,
      tintColor: appearance.selectedChevronColor,
      fixedSize: CGSize(width: 14, height: 14),
      spacingToTitle: appearance.chevronSpacing
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

  private func applyConfiguration() {
    barPresentation.configuration = FKBarPresentation.Configuration(
      bar: configuration.barConfiguration,
      presentation: configuration.presentationConfiguration,
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
    owner.delegate?.filterBarPresentation(owner, didSelectBarItem: model, at: index)
    owner.onBarTabSelected?(index, model)
  }
}

private final class PresentationDelegateSink: NSObject, FKBarPresentationDelegate {
  weak var owner: FKFilterBarPresentation?

  func barPresentation(_ barPresentation: FKBarPresentation, shouldPresentFor item: FKBar.Item, at index: Int) -> Bool {
    guard let owner, let model = owner.barItemModel(at: index) else { return true }
    return owner.delegate?.filterBarPresentation(owner, shouldPresentPanel: model.panelKind, for: model, at: index) ?? true
  }

  func barPresentation(_ barPresentation: FKBarPresentation, willPresentFor item: FKBar.Item, at index: Int) {
    guard let owner, let model = owner.barItemModel(at: index) else { return }
    owner.delegate?.filterBarPresentation(owner, willPresentPanel: model.panelKind)
    owner.onWillPresentPanel?(model.panelKind)
  }

  func barPresentation(_ barPresentation: FKBarPresentation, didPresentFor item: FKBar.Item, at index: Int) {
    guard let owner, let panel = owner.panelKind else { return }
    owner.delegate?.filterBarPresentation(owner, didPresentPanel: panel)
    owner.onDidPresentPanel?(panel)
  }

  func barPresentation(_ barPresentation: FKBarPresentation, willDismissPresentation reason: FKBarPresentation.PresentationDismissReason) {
    guard let owner else { return }
    owner.delegate?.filterBarPresentation(owner, willDismissPanel: owner.panelKind, reason: reason)
  }

  func barPresentation(_ barPresentation: FKBarPresentation, didDismissPresentation reason: FKBarPresentation.PresentationDismissReason) {
    guard let owner else { return }
    owner.delegate?.filterBarPresentation(owner, didDismissPanel: owner.panelKind)
    owner.onDidDismissPanel?(owner.panelKind)
    owner.panelKind = nil
  }
}
