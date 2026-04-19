import UIKit

/// Builds common filter panels from lightweight data providers, so callers only maintain model state.
///
/// Design goals:
/// - Keep app code minimal: pass in closures for current model and update callbacks.
/// - Centralize panel construction and selection wiring to `FKFilterBarPresentation`.
@MainActor
public final class FKFilterPanelFactory {
  /// Describes how a panel is built and how its state is persisted.
  public enum Source {
    /// Two-column panel: left list + right list (`UITableView`).
    case twoColumnList(
      model: () -> FKFilterTwoColumnModel?,
      onChange: (FKFilterTwoColumnModel) -> Void,
      configuration: FKFilterTwoColumnListViewController.Configuration = .init()
    )
    /// Two-column panel: left list + right grid (`UICollectionView`).
    case twoColumnGrid(
      model: () -> FKFilterTwoColumnModel?,
      onChange: (FKFilterTwoColumnModel) -> Void,
      configuration: FKFilterTwoColumnGridViewController.Configuration = .init()
    )
    /// Grid-like chips panel (`UICollectionView`).
    case chips(
      sections: () -> [FKFilterSection],
      onChange: ([FKFilterSection]) -> Void,
      configuration: FKFilterChipsViewController.Configuration = .init()
    )
    /// Single list panel (`UITableView`).
    case singleList(
      section: () -> FKFilterSection?,
      onChange: (FKFilterSection) -> Void,
      configuration: FKFilterSingleListViewController.Configuration = .init()
    )
  }

  public var sources: [FKFilterBarPresentation.PanelKind: Source]
  public var loadingTitle: String
  public var wrapsTopHairline: Bool

  public init(
    sources: [FKFilterBarPresentation.PanelKind: Source],
    loadingTitle: String = "Loading...",
    wrapsTopHairline: Bool = true
  ) {
    self.sources = sources
    self.loadingTitle = loadingTitle
    self.wrapsTopHairline = wrapsTopHairline
  }

  public func makePanel(
    for kind: FKFilterBarPresentation.PanelKind,
    using bar: FKFilterBarPresentation
  ) -> UIViewController? {
    guard let source = sources[kind] else { return nil }
    let panel: UIViewController
    switch source {
    case let .twoColumnList(model, onChange, configuration):
      guard let model = model() else { return loadingPanel() }
      panel = FKFilterTwoColumnListViewController(
        model: model,
        configuration: configuration,
        onChange: onChange,
        onSelectItem: { sectionID, item, mode in
          bar.handlePanelSelection(panelKind: kind, sectionID: sectionID, item: item, selectionMode: mode)
        },
        allowsMultipleSelection: bar.isMultipleSelectionEnabled(for: kind)
      )
    case let .twoColumnGrid(model, onChange, configuration):
      guard let model = model() else { return loadingPanel() }
      panel = FKFilterTwoColumnGridViewController(
        model: model,
        configuration: configuration,
        onChange: onChange,
        onSelectItem: { sectionID, item, mode in
          bar.handlePanelSelection(panelKind: kind, sectionID: sectionID, item: item, selectionMode: mode)
        },
        allowsMultipleSelection: bar.isMultipleSelectionEnabled(for: kind)
      )
    case let .chips(sections, onChange, configuration):
      let sections = sections()
      guard sections.isEmpty == false else { return loadingPanel() }
      panel = FKFilterChipsViewController(
        sections: sections,
        configuration: configuration,
        onChange: onChange,
        onSelectItem: { sectionID, item, mode in
          bar.handlePanelSelection(panelKind: kind, sectionID: sectionID, item: item, selectionMode: mode)
        },
        allowsMultipleSelection: bar.isMultipleSelectionEnabled(for: kind)
      )
    case let .singleList(section, onChange, configuration):
      guard let section = section() else { return loadingPanel() }
      panel = FKFilterSingleListViewController(
        section: section,
        configuration: configuration,
        onChange: onChange,
        onSelectItem: { sectionID, item, mode in
          bar.handlePanelSelection(panelKind: kind, sectionID: sectionID, item: item, selectionMode: mode)
        },
        allowsMultipleSelection: bar.isMultipleSelectionEnabled(for: kind)
      )
    }
    return wrapsTopHairline ? FKFilterTopHairlineWrapperViewController(contentVC: panel) : panel
  }

  private func loadingPanel() -> UIViewController {
    let vc = UIViewController()
    vc.preferredContentSize = CGSize(width: 0, height: 72)
    vc.view.backgroundColor = .systemBackground
    let label = UILabel()
    label.text = loadingTitle
    label.textColor = .secondaryLabel
    label.font = .preferredFont(forTextStyle: .body)
    label.translatesAutoresizingMaskIntoConstraints = false
    vc.view.addSubview(label)
    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: vc.view.topAnchor, constant: 20),
      label.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
      label.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor, constant: -20),
    ])
    return wrapsTopHairline ? FKFilterTopHairlineWrapperViewController(contentVC: vc) : vc
  }
}
