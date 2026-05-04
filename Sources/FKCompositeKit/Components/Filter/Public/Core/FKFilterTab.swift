import UIKit

/// One filter strip tab and the panel kind it presents.
public struct FKFilterTab<TabID: Hashable> {
  public let id: TabID
  public let panelKind: FKFilterPanelKind
  public let title: () -> String
  public let subtitle: (() -> String?)?
  public let allowsMultipleSelection: Bool
  /// When `nil`, ``FKFilterController`` uses ``FKFilterConfiguration/defaultTabStrip``.
  public let tabStrip: FKFilterTabStripConfiguration?

  public init(
    id: TabID,
    panelKind: FKFilterPanelKind,
    title: @escaping () -> String,
    subtitle: (() -> String?)? = nil,
    allowsMultipleSelection: Bool = false,
    tabStrip: FKFilterTabStripConfiguration? = nil
  ) {
    self.id = id
    self.panelKind = panelKind
    self.title = title
    self.subtitle = subtitle
    self.allowsMultipleSelection = allowsMultipleSelection
    self.tabStrip = tabStrip
  }

  /// Convenience for static title and optional subtitle strings.
  public init(
    id: TabID,
    panelKind: FKFilterPanelKind,
    title: String,
    subtitle: String? = nil,
    allowsMultipleSelection: Bool = false,
    tabStrip: FKFilterTabStripConfiguration? = nil
  ) {
    let titleClosure: () -> String = { title }
    let subtitleClosure: (() -> String?)? = subtitle.map { value in { value } }
    self.init(
      id: id,
      panelKind: panelKind,
      title: titleClosure,
      subtitle: subtitleClosure,
      allowsMultipleSelection: allowsMultipleSelection,
      tabStrip: tabStrip
    )
  }
}
