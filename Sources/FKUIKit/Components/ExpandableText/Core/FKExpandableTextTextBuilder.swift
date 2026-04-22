import UIKit

/// Builds the rendered attributed text for collapsed and expanded presentation states.
@MainActor
enum FKExpandableTextTextBuilder {
  /// Compares the full measured height against the collapsed line budget.
  static func doesTextNeedTruncation(
    _ text: NSAttributedString,
    width: CGFloat,
    lineLimit: Int,
    lineBreakMode: NSLineBreakMode
  ) -> Bool {
    guard lineLimit > 0, width > 0 else { return false }
    let fullHeight = measuredHeight(text, width: width, lineBreakMode: lineBreakMode)
    let lineHeight = estimatedLineHeight(from: text)
    let collapsedHeight = CGFloat(lineLimit) * lineHeight
    return fullHeight - collapsedHeight > 0.5
  }

  /// Produces the collapsed output and appends the configured action text.
  static func buildCollapsedText(
    fullText: NSAttributedString,
    width: CGFloat,
    lineLimit: Int,
    lineBreakMode: NSLineBreakMode,
    token: NSAttributedString,
    actionText: NSAttributedString,
    placement: FKExpandableTextConfiguration.ButtonPlacement
  ) -> NSAttributedString {
    guard width > 0, lineLimit > 0 else { return fullText }

    // Bottom-aligned actions do not need inline truncation fitting logic.
    if placement == .trailingBottom {
      let combined = NSMutableAttributedString(attributedString: fullText)
      combined.append(NSAttributedString(string: "\n"))
      combined.append(actionText)
      return combined
    }

    // Reuse a previous collapsed result when text and layout inputs match.
    let cacheKey = FKExpandableTextLayoutCache.shared.makeKey(
      text: fullText,
      width: width,
      numberOfLines: lineLimit,
      lineBreakMode: lineBreakMode,
      placement: placement,
      actionText: actionText,
      token: token
    )
    if let cached = FKExpandableTextLayoutCache.shared.value(forKey: cacheKey) {
      return cached
    }

    let maxHeight = CGFloat(lineLimit) * estimatedLineHeight(from: fullText)
    let mutable = NSMutableAttributedString(attributedString: fullText)
    let suffix = NSMutableAttributedString(attributedString: token)
    suffix.append(actionText)

    // Binary search the largest prefix that still fits within the line budget.
    var lower = 0
    var upper = fullText.length
    var best = 0
    while lower <= upper {
      let middle = (lower + upper) / 2
      let candidate = NSMutableAttributedString(attributedString: fullText.attributedSubstring(from: NSRange(location: 0, length: middle)))
      candidate.append(suffix)
      if measuredHeight(candidate, width: width, lineBreakMode: lineBreakMode) <= maxHeight {
        best = middle
        lower = middle + 1
      } else {
        upper = middle - 1
      }
    }

    mutable.replaceCharacters(in: NSRange(location: best, length: fullText.length - best), with: "")
    mutable.append(suffix)
    FKExpandableTextLayoutCache.shared.setValue(mutable, forKey: cacheKey)
    return mutable
  }

  /// Adds the action on a new line for expanded or trailing-bottom presentation.
  static func appendTrailingButtonLine(
    to text: NSAttributedString,
    action: NSAttributedString
  ) -> NSAttributedString {
    let result = NSMutableAttributedString(attributedString: text)
    result.append(NSAttributedString(string: "\n"))
    result.append(action)
    return result
  }

  /// Measures attributed text with Text Kit using the provided width and line break mode.
  private static func measuredHeight(
    _ text: NSAttributedString,
    width: CGFloat,
    lineBreakMode: NSLineBreakMode
  ) -> CGFloat {
    let storage = NSTextStorage(attributedString: text)
    let container = NSTextContainer(size: CGSize(width: width, height: .greatestFiniteMagnitude))
    container.lineFragmentPadding = 0
    container.lineBreakMode = lineBreakMode
    let manager = NSLayoutManager()
    manager.addTextContainer(container)
    storage.addLayoutManager(manager)
    manager.glyphRange(for: container)
    return ceil(manager.usedRect(for: container).height)
  }

  /// Falls back to the body text style if no font attribute is present.
  private static func estimatedLineHeight(from text: NSAttributedString) -> CGFloat {
    guard text.length > 0 else {
      return UIFont.preferredFont(forTextStyle: .body).lineHeight
    }
    return text.attribute(.font, at: 0, effectiveRange: nil)
      .flatMap { $0 as? UIFont }?
      .lineHeight ?? UIFont.preferredFont(forTextStyle: .body).lineHeight
  }
}
