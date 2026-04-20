import Foundation

/// Default implementation of ``FKBusinessNumberFormatting``.
public final class FKBusinessNumberFormatter: FKBusinessNumberFormatting, @unchecked Sendable {
  /// Returns current language code used for compact unit style.
  private let languageCodeProvider: () -> String

  /// Creates number formatter helper.
  ///
  /// - Parameter languageCodeProvider: Closure providing current language code.
  public init(languageCodeProvider: @escaping () -> String) {
    self.languageCodeProvider = languageCodeProvider
  }

  /// Formats decimal amount with grouped separators.
  ///
  /// - Parameters:
  ///   - value: Decimal amount.
  ///   - fractionDigits: Fixed number of fraction digits.
  /// - Returns: Formatted amount text.
  public func formatAmount(_ value: Decimal, fractionDigits: Int = 2) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = max(0, fractionDigits)
    formatter.maximumFractionDigits = max(0, fractionDigits)
    return formatter.string(from: value as NSDecimalNumber) ?? "\(value)"
  }

  /// Formats value into compact unit text according to language preference.
  ///
  /// - Parameters:
  ///   - value: Input numeric value.
  ///   - fractionDigits: Maximum fraction digits in compact result.
  /// - Returns: Compact unit text.
  public func formatCompact(_ value: Double, fractionDigits: Int = 1) -> String {
    let absValue = abs(value)
    let isZH = languageCodeProvider().lowercased().hasPrefix("zh")

    if isZH {
      if absValue >= 1e8 {
        return formatScaled(value, divisor: 1e8, suffix: "亿", fractionDigits: fractionDigits)
      }
      if absValue >= 1e4 {
        return formatScaled(value, divisor: 1e4, suffix: "万", fractionDigits: fractionDigits)
      }
      return formatPlain(value, fractionDigits: fractionDigits)
    } else {
      if absValue >= 1e9 {
        return formatScaled(value, divisor: 1e9, suffix: "B", fractionDigits: fractionDigits)
      }
      if absValue >= 1e6 {
        return formatScaled(value, divisor: 1e6, suffix: "M", fractionDigits: fractionDigits)
      }
      if absValue >= 1e3 {
        return formatScaled(value, divisor: 1e3, suffix: "K", fractionDigits: fractionDigits)
      }
      return formatPlain(value, fractionDigits: fractionDigits)
    }
  }

  /// Formats a scaled value and appends compact suffix.
  ///
  /// - Parameters:
  ///   - value: Original value.
  ///   - divisor: Divisor for scaling.
  ///   - suffix: Unit suffix.
  ///   - fractionDigits: Fraction precision.
  /// - Returns: Compact number text.
  private func formatScaled(_ value: Double, divisor: Double, suffix: String, fractionDigits: Int) -> String {
    let scaled = value / divisor
    return "\(formatPlain(scaled, fractionDigits: fractionDigits))\(suffix)"
  }

  /// Formats a plain number with grouped separators.
  ///
  /// - Parameters:
  ///   - value: Numeric value.
  ///   - fractionDigits: Maximum fraction precision.
  /// - Returns: Formatted number text.
  private func formatPlain(_ value: Double, fractionDigits: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = max(0, fractionDigits)
    return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
  }
}

