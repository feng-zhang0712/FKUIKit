import UIKit

/// Builds filter panels from model providers so screens only hold state and callbacks.
@MainActor
public final class FKFilterPanelFactory {
  /// How a ``FKFilterPanelKind`` is constructed and persisted.
  public enum PanelSource {
    case twoColumnList(
      model: () -> FKFilterTwoColumnModel?,
      onChange: (FKFilterTwoColumnModel) -> Void,
      configuration: FKFilterTwoColumnListViewController.Configuration = .init()
    )
    case twoColumnGrid(
      model: () -> FKFilterTwoColumnModel?,
      onChange: (FKFilterTwoColumnModel) -> Void,
      configuration: FKFilterTwoColumnGridViewController.Configuration = .init()
    )
    case chips(
      sections: () -> [FKFilterSection],
      onChange: ([FKFilterSection]) -> Void,
      configuration: FKFilterChipsViewController.Configuration = .init()
    )
    case singleList(
      section: () -> FKFilterSection?,
      onChange: (FKFilterSection) -> Void,
      configuration: FKFilterSingleListViewController.Configuration = .init()
    )
  }

  public var sourcesByPanelKind: [FKFilterPanelKind: PanelSource]
  public var loadingTitle: String
  /// When true, panel controllers are wrapped with a one-pixel top hairline under the tab strip.
  public var wrapsPanelWithTopHairline: Bool

  public init(
    sourcesByPanelKind: [FKFilterPanelKind: PanelSource],
    loadingTitle: String = "Loading...",
    wrapsPanelWithTopHairline: Bool = true
  ) {
    self.sourcesByPanelKind = sourcesByPanelKind
    self.loadingTitle = loadingTitle
    self.wrapsPanelWithTopHairline = wrapsPanelWithTopHairline
  }

  /// Builds the panel for `kind` and forwards taps to `onSelection`.
  ///
  /// `allowsMultipleSelection` is combined with each section’s ``FKFilterSection/selectionMode`` (single wins unless both allow multiple).
  public func makePanel(
    for kind: FKFilterPanelKind,
    allowsMultipleSelection: Bool,
    onSelection: @escaping (FKFilterPanelSelection) -> Void
  ) -> UIViewController? {
    guard let source = sourcesByPanelKind[kind] else { return nil }
    let panel: UIViewController
    switch source {
    case let .twoColumnList(model, onChange, configuration):
      guard let model = model() else { return loadingPanel() }
      panel = FKFilterTwoColumnListViewController(
        model: model,
        configuration: configuration,
        onChange: onChange,
        onSelection: { selection in
          onSelection(selection)
        },
        allowsMultipleSelection: allowsMultipleSelection
      )
    case let .twoColumnGrid(model, onChange, configuration):
      guard let model = model() else { return loadingPanel() }
      panel = FKFilterTwoColumnGridViewController(
        model: model,
        configuration: configuration,
        onChange: onChange,
        onSelection: { selection in
          onSelection(selection)
        },
        allowsMultipleSelection: allowsMultipleSelection
      )
    case let .chips(sections, onChange, configuration):
      let sections = sections()
      guard sections.isEmpty == false else { return loadingPanel() }
      panel = FKFilterChipsViewController(
        sections: sections,
        configuration: configuration,
        onChange: onChange,
        onSelection: { selection in
          onSelection(selection)
        },
        allowsMultipleSelection: allowsMultipleSelection
      )
    case let .singleList(section, onChange, configuration):
      guard let section = section() else { return loadingPanel() }
      panel = FKFilterSingleListViewController(
        section: section,
        configuration: configuration,
        onChange: onChange,
        onSelection: { selection in
          onSelection(selection)
        },
        allowsMultipleSelection: allowsMultipleSelection
      )
    }
    return wrapsPanelWithTopHairline
      ? FKFilterTopHairlineWrapperViewController(contentVC: panel)
      : panel
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
    return wrapsPanelWithTopHairline
      ? FKFilterTopHairlineWrapperViewController(contentVC: vc)
      : vc
  }
}
