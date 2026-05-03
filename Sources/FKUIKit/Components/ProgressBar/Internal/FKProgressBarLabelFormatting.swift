import UIKit

/// Builds the optional visible label and `accessibilityValue` text from configuration and normalized progress.
enum FKProgressBarLabelFormatting {
  static func displayString(progress: CGFloat, configuration: FKProgressBarConfiguration) -> String {
    let t = min(max(progress, 0), 1)
    let prefix = configuration.label.valuePrefix
    let suffix = configuration.label.valueSuffix
    let digits = configuration.label.fractionDigits
    switch configuration.label.format {
    case .percentInteger:
      let p = Int((t * 100).rounded(.toNearestOrAwayFromZero))
      return "\(prefix)\(p)%\(suffix)"
    case .percentFractional:
      let fmt = NumberFormatter()
      fmt.numberStyle = .decimal
      fmt.minimumFractionDigits = digits
      fmt.maximumFractionDigits = digits
      fmt.locale = configuration.label.numberFormatter?.locale ?? .current
      let v = t * 100
      let s = fmt.string(from: NSNumber(value: v)) ?? "\(v)"
      return "\(prefix)\(s)%\(suffix)"
    case .normalizedValue:
      let fmt = NumberFormatter()
      fmt.numberStyle = .decimal
      fmt.minimumFractionDigits = digits
      fmt.maximumFractionDigits = digits
      fmt.locale = configuration.label.numberFormatter?.locale ?? .current
      let s = fmt.string(from: NSNumber(value: t)) ?? "\(t)"
      return "\(prefix)\(s)\(suffix)"
    case .logicalRangeValue:
      let lo = configuration.label.logicalMinimum
      let hi = configuration.label.logicalMaximum
      let logical = lo + Double(t) * (hi - lo)
      if let nf = configuration.label.numberFormatter {
        let copy = nf.copy() as! NumberFormatter
        let s = copy.string(from: NSNumber(value: logical)) ?? "\(logical)"
        return "\(prefix)\(s)\(suffix)"
      }
      let fmt = NumberFormatter()
      fmt.numberStyle = .decimal
      fmt.minimumFractionDigits = digits
      fmt.maximumFractionDigits = digits
      let s = fmt.string(from: NSNumber(value: logical)) ?? "\(logical)"
      return "\(prefix)\(s)\(suffix)"
    }
  }

  static func accessibilityValue(progress: CGFloat, buffer: CGFloat, configuration: FKProgressBarConfiguration, isIndeterminate: Bool) -> String {
    if isIndeterminate {
      return NSLocalizedString("In progress", comment: "FKProgressBar indeterminate accessibility")
    }
    let t = min(max(progress, 0), 1)
    let lo = configuration.label.logicalMinimum
    let hi = configuration.label.logicalMaximum
    let logical = lo + Double(t) * (hi - lo)
    let nf = configuration.label.numberFormatter ?? {
      let f = NumberFormatter()
      f.numberStyle = .decimal
      f.maximumFractionDigits = 2
      return f
    }()
    let main = nf.string(from: NSNumber(value: logical)) ?? "\(logical)"
    if configuration.appearance.showsBuffer {
      let bt = min(max(buffer, 0), 1)
      let blogical = lo + Double(bt) * (hi - lo)
      let bstr = nf.string(from: NSNumber(value: blogical)) ?? "\(blogical)"
      return String.localizedStringWithFormat(
        NSLocalizedString(
          "fk_progress_bar_a11y_buffer",
          tableName: nil,
          bundle: .main,
          value: "%1$@ progress, %2$@ buffered",
          comment: "Accessibility: primary value, buffer value"
        ),
        main,
        bstr
      )
    }
    let pct = Int((t * 100).rounded(.toNearestOrAwayFromZero))
    return String.localizedStringWithFormat(
      NSLocalizedString(
        "fk_progress_bar_a11y_percent",
        tableName: nil,
        bundle: .main,
        value: "%lld percent",
        comment: "Accessibility: percent complete"
      ),
      Int64(pct)
    )
  }
}
