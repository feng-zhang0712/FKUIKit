import Foundation

/// Static number formatting and conversion helpers.
public enum FKUtilsNumber {
  /// Formats decimal number with grouping separators.
  public static func formatAmount(_ value: Decimal, minimumFractionDigits: Int = 2, maximumFractionDigits: Int = 2, locale: Locale = .current) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.locale = locale
    formatter.minimumFractionDigits = minimumFractionDigits
    formatter.maximumFractionDigits = maximumFractionDigits
    return formatter.string(from: value as NSDecimalNumber) ?? "\(value)"
  }

  /// Rounds a decimal number with given scale.
  public static func rounded(_ value: Decimal, scale: Int, mode: NSDecimalNumber.RoundingMode = .plain) -> Decimal {
    var source = value
    var result = Decimal()
    NSDecimalRound(&result, &source, scale, mode)
    return result
  }

  /// Truncates a decimal number without rounding.
  public static func truncated(_ value: Decimal, scale: Int) -> Decimal {
    rounded(value, scale: scale, mode: .down)
  }

  /// Converts number to Chinese unit string (`wan`, `yi`).
  public static func formatChineseUnit(_ value: Double, fractionDigits: Int = 2) -> String {
    let absolute = abs(value)
    if absolute >= 100_000_000 {
      return "\(format(value / 100_000_000, digits: fractionDigits))亿"
    }
    if absolute >= 10_000 {
      return "\(format(value / 10_000, digits: fractionDigits))万"
    }
    return format(value, digits: fractionDigits)
  }

  /// Formats decimal to percent style.
  public static func formatPercent(_ value: Double, fractionDigits: Int = 2, locale: Locale = .current) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .percent
    formatter.locale = locale
    formatter.minimumFractionDigits = fractionDigits
    formatter.maximumFractionDigits = fractionDigits
    return formatter.string(from: NSNumber(value: value)) ?? "\(value * 100)%"
  }

  /// Returns random integer in closed range.
  public static func randomInt(in range: ClosedRange<Int>) -> Int {
    Int.random(in: range)
  }

  /// Left pads number with zero.
  public static func zeroPadded(_ value: Int, length: Int) -> String {
    String(format: "%0\(max(0, length))d", value)
  }

  /// Converts integer to compact readable text.
  public static func compact(_ value: Int64, locale: Locale = .current) -> String {
    if #available(iOS 15.0, *) {
      let style: IntegerFormatStyle<Int64> = .number.locale(locale).notation(.compactName)
      return value.formatted(style)
    }
    return fallbackCompact(value)
  }

  /// Formats a double to fixed digits.
  private static func format(_ value: Double, digits: Int) -> String {
    String(format: "%.\(max(0, digits))f", value)
  }

  /// Fallback compact formatter for old systems.
  private static func fallbackCompact(_ value: Int64) -> String {
    let absolute = abs(Double(value))
    if absolute >= 1_000_000_000 { return format(Double(value) / 1_000_000_000, digits: 1) + "B" }
    if absolute >= 1_000_000 { return format(Double(value) / 1_000_000, digits: 1) + "M" }
    if absolute >= 1_000 { return format(Double(value) / 1_000, digits: 1) + "K" }
    return "\(value)"
  }
}
