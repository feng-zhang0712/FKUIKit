#if canImport(UIKit)
import UIKit

public extension UILabel {
  /// Approximate number of lines needed for the current `text` or `attributedText` within the available width.
  ///
  /// - Note: For multi-line labels, ensure `preferredMaxLayoutWidth` is set when using Auto Layout.
  func fk_numberOfLinesThatFit() -> Int {
    let width = bounds.width > 0 ? bounds.width : preferredMaxLayoutWidth
    guard width > 0 else { return 0 }

    let bounding: CGRect
    let lineHeight: CGFloat

    if let attributed = attributedText, attributed.length > 0 {
      bounding = attributed.boundingRect(
        with: CGSize(width: width, height: .greatestFiniteMagnitude),
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        context: nil
      )
      if let f = attributed.attribute(.font, at: 0, effectiveRange: nil) as? UIFont {
        lineHeight = f.lineHeight
      } else if let f = font {
        lineHeight = f.lineHeight
      } else {
        return 0
      }
    } else if let text, let font {
      bounding = (text as NSString).boundingRect(
        with: CGSize(width: width, height: .greatestFiniteMagnitude),
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        attributes: [.font: font],
        context: nil
      )
      lineHeight = font.lineHeight
    } else {
      return 0
    }

    guard lineHeight > 0 else { return 0 }
    return Int(ceil(bounding.height / lineHeight))
  }
}

#endif
