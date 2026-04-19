import UIKit

/// Text & background style for list-like filter items.
///
/// Used by:
/// - `FKFilterSingleListViewController` (single list panel)
/// - `FKFilterTwoColumnListViewController` (left/right tables)
///
/// Naming note:
/// - `FKFilterListCellStyle` is OK because the underlying UI is table/“cell”-like.
/// - If you want a more abstract name, `FKFilterListItemStyle` is a good alternative.
///   (I did NOT rename it to avoid breaking API.)
public struct FKFilterListCellStyle {
  public var font: UIFont
  public var normalTextColor: UIColor
  public var selectedTextColor: UIColor
  public var disabledTextColor: UIColor
  public var textAlignment: NSTextAlignment
  public var rowBackgroundColor: UIColor
  public var selectedRowBackgroundColor: UIColor?

  public init(
    font: UIFont = .preferredFont(forTextStyle: .subheadline),
    normalTextColor: UIColor = .label,
    selectedTextColor: UIColor = .systemRed,
    disabledTextColor: UIColor = .secondaryLabel,
    textAlignment: NSTextAlignment = .natural,
    rowBackgroundColor: UIColor = .systemBackground,
    selectedRowBackgroundColor: UIColor? = nil
  ) {
    self.font = font
    self.normalTextColor = normalTextColor
    self.selectedTextColor = selectedTextColor
    self.disabledTextColor = disabledTextColor
    self.textAlignment = textAlignment
    self.rowBackgroundColor = rowBackgroundColor
    self.selectedRowBackgroundColor = selectedRowBackgroundColor
  }
}

