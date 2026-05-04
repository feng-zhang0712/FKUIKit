import Foundation
import UIKit

/// Describes one filter column in the bar and which panel content to show when it expands.
///
/// Each tab maps to a ``FKFilterPanelKind`` entry in ``FKFilterPanelFactory/sources``.
public struct FKFilterTab<TabID: Hashable> {
  public let id: TabID
  public let panelKind: FKFilterPanelKind
  public let title: () -> String
  public let subtitle: (() -> String?)?
  public let allowsMultipleSelection: Bool
  /// Typography for the primary title in the chevron tab item (see ``FKAnchoredDropdownTab/chevronTitle``).
  public let titleTextStyle: UIFont.TextStyle
  /// Typography for the optional subtitle line.
  public let subtitleTextStyle: UIFont.TextStyle
  public let chevronSize: CGSize
  public let chevronSpacing: CGFloat
  public let titleSubtitleSpacing: CGFloat

  public init(
    id: TabID,
    panelKind: FKFilterPanelKind,
    title: @escaping () -> String,
    subtitle: (() -> String?)? = nil,
    allowsMultipleSelection: Bool = false,
    titleTextStyle: UIFont.TextStyle = .subheadline,
    subtitleTextStyle: UIFont.TextStyle = .caption2,
    chevronSize: CGSize = CGSize(width: 14, height: 14),
    chevronSpacing: CGFloat = 4,
    titleSubtitleSpacing: CGFloat = 2
  ) {
    self.id = id
    self.panelKind = panelKind
    self.title = title
    self.subtitle = subtitle
    self.allowsMultipleSelection = allowsMultipleSelection
    self.titleTextStyle = titleTextStyle
    self.subtitleTextStyle = subtitleTextStyle
    self.chevronSize = chevronSize
    self.chevronSpacing = chevronSpacing
    self.titleSubtitleSpacing = titleSubtitleSpacing
  }

  /// Convenience for static title / subtitle copy.
  public init(
    id: TabID,
    panelKind: FKFilterPanelKind,
    title: String,
    subtitle: String? = nil,
    allowsMultipleSelection: Bool = false,
    titleTextStyle: UIFont.TextStyle = .subheadline,
    subtitleTextStyle: UIFont.TextStyle = .caption2,
    chevronSize: CGSize = CGSize(width: 14, height: 14),
    chevronSpacing: CGFloat = 4,
    titleSubtitleSpacing: CGFloat = 2
  ) {
    let titleClosure: () -> String = { title }
    let subtitleClosure: (() -> String?)? = subtitle.map { sub in { sub as String? } }
    self.init(
      id: id,
      panelKind: panelKind,
      title: titleClosure,
      subtitle: subtitleClosure,
      allowsMultipleSelection: allowsMultipleSelection,
      titleTextStyle: titleTextStyle,
      subtitleTextStyle: subtitleTextStyle,
      chevronSize: chevronSize,
      chevronSpacing: chevronSpacing,
      titleSubtitleSpacing: titleSubtitleSpacing
    )
  }
}
