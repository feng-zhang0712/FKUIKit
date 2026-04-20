//
// FKExpandableTextTextBuilder.swift
//
// Attributed text builder and measurement helpers.
//

import UIKit

/// Utility namespace for text styling and TextKit-based measurement.
///
/// This helper centralizes attributed text normalization and deterministic text
/// measurement used by both live rendering and pre-calculation APIs.
enum FKExpandableTextTextBuilder {
  /// Builds a styled attributed string from either plain or attributed source text.
  ///
  /// The method always applies component-level style to ensure consistent rendering
  /// and measurement behavior.
  ///
  /// - Parameters:
  ///   - plainText: Fallback plain text source.
  ///   - attributedText: Optional rich text source.
  ///   - style: Target text style to apply.
  /// - Returns: A styled attributed string used for layout and rendering.
  static func styledAttributedText(
    plainText: String?,
    attributedText: NSAttributedString?,
    style: FKExpandableTextTextStyle
  ) -> NSAttributedString {
    // Use attributed source when provided; otherwise create from plain text.
    let source: NSAttributedString
    if let attributedText {
      source = attributedText
    } else {
      source = NSAttributedString(string: plainText ?? "")
    }

    // Normalize visual attributes to keep runtime and pre-measurement consistent.
    let mutable = NSMutableAttributedString(attributedString: source)
    let range = NSRange(location: 0, length: mutable.length)
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = style.alignment
    paragraph.lineSpacing = style.lineSpacing
    paragraph.lineBreakMode = style.lineBreakMode

    mutable.addAttributes(
      [
        .font: style.font,
        .foregroundColor: style.color,
        .paragraphStyle: paragraph,
        .kern: style.kern
      ],
      range: range
    )
    return mutable
  }

  /// Computes line count by using TextKit layout container.
  ///
  /// This method lays out text in an unconstrained line container, then iterates
  /// glyph line fragments to get exact rendered line count.
  ///
  /// - Parameters:
  ///   - attributedText: Fully styled attributed text.
  ///   - width: Available text width.
  /// - Returns: Rendered line count under current width.
  static func lineCount(
    for attributedText: NSAttributedString,
    width: CGFloat
  ) -> Int {
    guard width > 0, attributedText.length > 0 else {
      return 0
    }

    // Build a TextKit pipeline: storage -> layout manager -> text container.
    let storage = NSTextStorage(attributedString: attributedText)
    let layoutManager = NSLayoutManager()
    let textContainer = NSTextContainer(size: CGSize(width: width, height: .greatestFiniteMagnitude))
    textContainer.lineFragmentPadding = 0
    textContainer.maximumNumberOfLines = 0
    textContainer.lineBreakMode = .byWordWrapping
    layoutManager.addTextContainer(textContainer)
    storage.addLayoutManager(layoutManager)

    // Force layout before reading line fragments.
    _ = layoutManager.glyphRange(for: textContainer)
    var lineCount = 0
    var index = 0
    var lineRange = NSRange(location: 0, length: 0)
    // Count one visible line per line fragment range.
    while index < layoutManager.numberOfGlyphs {
      layoutManager.lineFragmentRect(forGlyphAt: index, effectiveRange: &lineRange)
      index = NSMaxRange(lineRange)
      lineCount += 1
    }
    return lineCount
  }

  /// Measures text height under a maximum line limit.
  ///
  /// - Parameters:
  ///   - attributedText: Fully styled attributed text.
  ///   - width: Available text width.
  ///   - maximumNumberOfLines: Maximum rendered lines. Use `0` for unlimited lines.
  /// - Returns: Ceiled height that can be used for Auto Layout and manual sizing.
  static func measuredHeight(
    for attributedText: NSAttributedString,
    width: CGFloat,
    maximumNumberOfLines: Int
  ) -> CGFloat {
    guard width > 0, attributedText.length > 0 else {
      return 0
    }

    // Build a TextKit pipeline and constrain by line limit when collapsed.
    let storage = NSTextStorage(attributedString: attributedText)
    let layoutManager = NSLayoutManager()
    let textContainer = NSTextContainer(size: CGSize(width: width, height: .greatestFiniteMagnitude))
    textContainer.lineFragmentPadding = 0
    textContainer.maximumNumberOfLines = max(0, maximumNumberOfLines)
    textContainer.lineBreakMode = .byTruncatingTail
    layoutManager.addTextContainer(textContainer)
    storage.addLayoutManager(layoutManager)

    // Force layout and read used rect as final rendered height.
    _ = layoutManager.glyphRange(for: textContainer)
    let usedRect = layoutManager.usedRect(for: textContainer)
    return ceil(usedRect.height)
  }
}
