import Foundation

/// Collapsed or expanded presentation of expandable text.
///
/// Use this value from ``FKExpandableTextLabelController`` / ``FKExpandableTextLinkedTextViewController``
/// and from ``onExpansionChange`` callbacks.
public enum FKExpandableTextState: Sendable, Equatable {
  /// Body is shown with truncation rules for the collapsed rule.
  case collapsed
  /// Full body (and optional trailing collapse action) is shown.
  case expanded
}
