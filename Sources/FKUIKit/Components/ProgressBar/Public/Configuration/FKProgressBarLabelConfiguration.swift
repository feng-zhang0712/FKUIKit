import UIKit

/// Text, placement, typography, logical value range, and optional ``NumberFormatter`` for the progress value label.
///
/// - Note: Marked `@unchecked Sendable` because `UIFont` / `NumberFormatter` are not `Sendable`.
public struct FKProgressBarLabelConfiguration: @unchecked Sendable {
  /// How label text is chosen when ``placement`` is not ``FKProgressBarLabelPlacement/none``.
  public var contentMode: FKProgressBarLabelContentMode
  /// Title line for ``FKProgressBarLabelContentMode/customTitleOnly``, ``customTitleWhenIdle``, or the first line of ``customTitleWithProgressSubtitle``.
  public var customTitle: String

  public var placement: FKProgressBarLabelPlacement
  public var format: FKProgressBarLabelFormat
  public var fractionDigits: Int
  public var font: UIFont
  /// Color for the label when ``usesSemanticTextColor`` is `false`.
  public var textColor: UIColor
  public var padding: CGFloat
  /// When `true`, ignores ``textColor`` and uses ``UIColor/label`` (adapts in Dark Mode).
  public var usesSemanticTextColor: Bool

  /// Logical value at progress `0`.
  public var logicalMinimum: Double
  /// Logical value at progress `1`.
  public var logicalMaximum: Double
  /// Prepended to formatted value text (e.g. a space or currency symbol).
  public var valuePrefix: String
  /// Appended after formatted value text (e.g. `" MB"`).
  public var valueSuffix: String

  /// Used for ``FKProgressBarLabelFormat/logicalRangeValue`` and optional locale/grouping overrides.
  public var numberFormatter: NumberFormatter?

  public init(
    contentMode: FKProgressBarLabelContentMode = .formattedProgress,
    customTitle: String = "",
    placement: FKProgressBarLabelPlacement = .none,
    format: FKProgressBarLabelFormat = .percentInteger,
    fractionDigits: Int = 1,
    font: UIFont = .preferredFont(forTextStyle: .footnote),
    textColor: UIColor = .secondaryLabel,
    padding: CGFloat = 4,
    usesSemanticTextColor: Bool = false,
    logicalMinimum: Double = 0,
    logicalMaximum: Double = 1,
    valuePrefix: String = "",
    valueSuffix: String = "",
    numberFormatter: NumberFormatter? = nil
  ) {
    self.contentMode = contentMode
    self.customTitle = customTitle
    self.placement = placement
    self.format = format
    self.fractionDigits = max(0, min(6, fractionDigits))
    self.font = font
    self.textColor = textColor
    self.padding = max(0, padding)
    self.usesSemanticTextColor = usesSemanticTextColor
    self.logicalMinimum = logicalMinimum
    self.logicalMaximum = logicalMaximum
    self.valuePrefix = valuePrefix
    self.valueSuffix = valueSuffix
    self.numberFormatter = numberFormatter
  }
}
