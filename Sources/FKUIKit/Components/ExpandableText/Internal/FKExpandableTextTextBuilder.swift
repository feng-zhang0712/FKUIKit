import UIKit

/// Text Kit helpers that assemble collapsed and expanded `NSAttributedString` outputs.
@MainActor
enum FKExpandableTextTextBuilder {
  /// `UILabel` defaults to tail truncation; line-budget checks must use wrapping or height/line counts are wrong.
  private static func measurementLineBreakMode(_ mode: NSLineBreakMode) -> NSLineBreakMode {
    switch mode {
    case .byWordWrapping, .byCharWrapping:
      return mode
    default:
      return .byWordWrapping
    }
  }

  static func doesTextNeedTruncation(
    _ text: NSAttributedString,
    width: CGFloat,
    lineLimit: Int,
    lineBreakMode: NSLineBreakMode
  ) -> Bool {
    guard lineLimit > 0, width > 0, text.length > 0 else { return false }
    let wrapMode = measurementLineBreakMode(lineBreakMode)
    let storage = NSTextStorage(attributedString: text)
    let container = NSTextContainer(size: CGSize(width: width, height: .greatestFiniteMagnitude))
    container.lineFragmentPadding = 0
    container.maximumNumberOfLines = lineLimit
    container.lineBreakMode = wrapMode
    let manager = NSLayoutManager()
    manager.addTextContainer(container)
    storage.addLayoutManager(manager)
    let glyphRange = manager.glyphRange(for: container)
    let characterRange = manager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
    return NSMaxRange(characterRange) < text.length
  }

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
    let wrapMode = measurementLineBreakMode(lineBreakMode)

    if placement == .trailingBottom {
      let cacheKey = FKExpandableTextLayoutCache.shared.makeKey(
        text: fullText,
        width: width,
        numberOfLines: lineLimit,
        lineBreakMode: wrapMode,
        placement: placement,
        actionText: actionText,
        token: token
      )
      if let cached = FKExpandableTextLayoutCache.shared.value(forKey: cacheKey) {
        return cached
      }

      // Reserve one visual line for the action under the body so total height stays near `lineLimit`
      // (inline tail fits body + token + action within the same line budget).
      let bodyLineBudget = max(1, lineLimit - 1)

      var lower = 0
      var upper = fullText.length
      var best = 0
      while lower <= upper {
        let middle = (lower + upper) / 2
        let body = NSMutableAttributedString(attributedString: fullText.attributedSubstring(from: NSRange(location: 0, length: middle)))
        body.append(token)
        if usedLineCount(body, width: width, lineBreakMode: wrapMode) <= bodyLineBudget {
          best = middle
          lower = middle + 1
        } else {
          upper = middle - 1
        }
      }

      let result = NSMutableAttributedString(attributedString: fullText.attributedSubstring(from: NSRange(location: 0, length: best)))
      result.append(token)
      result.append(NSAttributedString(string: "\n"))
      result.append(actionText)
      FKExpandableTextLayoutCache.shared.setValue(result, forKey: cacheKey)
      return result
    }

    let cacheKey = FKExpandableTextLayoutCache.shared.makeKey(
      text: fullText,
      width: width,
      numberOfLines: lineLimit,
      lineBreakMode: wrapMode,
      placement: placement,
      actionText: actionText,
      token: token
    )
    if let cached = FKExpandableTextLayoutCache.shared.value(forKey: cacheKey) {
      return cached
    }

    let maxHeight = measuredHeightWithLineLimit(
      fullText,
      width: width,
      lineLimit: lineLimit,
      lineBreakMode: wrapMode
    )
    let mutable = NSMutableAttributedString(attributedString: fullText)
    let suffix = NSMutableAttributedString(attributedString: token)
    suffix.append(actionText)

    var lower = 0
    var upper = fullText.length
    var best = 0
    while lower <= upper {
      let middle = (lower + upper) / 2
      let candidate = NSMutableAttributedString(attributedString: fullText.attributedSubstring(from: NSRange(location: 0, length: middle)))
      candidate.append(suffix)
      if measuredHeight(candidate, width: width, lineBreakMode: wrapMode) <= maxHeight {
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

  static func appendTrailingButtonLine(
    to text: NSAttributedString,
    action: NSAttributedString
  ) -> NSAttributedString {
    let result = NSMutableAttributedString(attributedString: text)
    result.append(NSAttributedString(string: "\n"))
    result.append(action)
    return result
  }

  private static func measuredHeightWithLineLimit(
    _ text: NSAttributedString,
    width: CGFloat,
    lineLimit: Int,
    lineBreakMode: NSLineBreakMode
  ) -> CGFloat {
    guard text.length > 0, lineLimit > 0, width > 0 else { return 0 }
    let wrapMode = measurementLineBreakMode(lineBreakMode)
    let storage = NSTextStorage(attributedString: text)
    let container = NSTextContainer(size: CGSize(width: width, height: .greatestFiniteMagnitude))
    container.lineFragmentPadding = 0
    container.maximumNumberOfLines = lineLimit
    container.lineBreakMode = wrapMode
    let manager = NSLayoutManager()
    manager.addTextContainer(container)
    storage.addLayoutManager(manager)
    manager.glyphRange(for: container)
    return ceil(manager.usedRect(for: container).height)
  }

  /// Line fragments produced by laying out `text` at `width` (unlimited vertical growth).
  private static func usedLineCount(
    _ text: NSAttributedString,
    width: CGFloat,
    lineBreakMode: NSLineBreakMode
  ) -> Int {
    guard text.length > 0, width > 0 else { return 0 }
    let wrapMode = measurementLineBreakMode(lineBreakMode)
    let storage = NSTextStorage(attributedString: text)
    let container = NSTextContainer(size: CGSize(width: width, height: .greatestFiniteMagnitude))
    container.lineFragmentPadding = 0
    container.lineBreakMode = wrapMode
    let manager = NSLayoutManager()
    manager.addTextContainer(container)
    storage.addLayoutManager(manager)
    let glyphRange = manager.glyphRange(for: container)
    var lines = 0
    manager.enumerateLineFragments(forGlyphRange: glyphRange) { _, _, _, _, _ in
      lines += 1
    }
    return lines
  }

  private static func measuredHeight(
    _ text: NSAttributedString,
    width: CGFloat,
    lineBreakMode: NSLineBreakMode
  ) -> CGFloat {
    let wrapMode = measurementLineBreakMode(lineBreakMode)
    let storage = NSTextStorage(attributedString: text)
    let container = NSTextContainer(size: CGSize(width: width, height: .greatestFiniteMagnitude))
    container.lineFragmentPadding = 0
    container.lineBreakMode = wrapMode
    let manager = NSLayoutManager()
    manager.addTextContainer(container)
    storage.addLayoutManager(manager)
    manager.glyphRange(for: container)
    return ceil(manager.usedRect(for: container).height)
  }
}
