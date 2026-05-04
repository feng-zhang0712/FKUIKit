import UIKit

/// One filter strip tab and the panel kind it presents.
public struct FKFilterTab<TabID: Hashable> {
  public let id: TabID
  public let panelKind: FKFilterPanelKind
  public let title: () -> String
  public let subtitle: (() -> String?)?
  public let allowsMultipleSelection: Bool
  public let stripMetrics: FKFilterStripMetrics

  public init(
    id: TabID,
    panelKind: FKFilterPanelKind,
    title: @escaping () -> String,
    subtitle: (() -> String?)? = nil,
    allowsMultipleSelection: Bool = false,
    stripMetrics: FKFilterStripMetrics = FKFilterStripMetrics()
  ) {
    self.id = id
    self.panelKind = panelKind
    self.title = title
    self.subtitle = subtitle
    self.allowsMultipleSelection = allowsMultipleSelection
    self.stripMetrics = stripMetrics
  }

  /// Convenience for static title and optional subtitle strings.
  public init(
    id: TabID,
    panelKind: FKFilterPanelKind,
    title: String,
    subtitle: String? = nil,
    allowsMultipleSelection: Bool = false,
    stripMetrics: FKFilterStripMetrics = FKFilterStripMetrics()
  ) {
    let titleClosure: () -> String = { title }
    let subtitleClosure: (() -> String?)? = subtitle.map { value in { value } }
    self.init(
      id: id,
      panelKind: panelKind,
      title: titleClosure,
      subtitle: subtitleClosure,
      allowsMultipleSelection: allowsMultipleSelection,
      stripMetrics: stripMetrics
    )
  }
}
