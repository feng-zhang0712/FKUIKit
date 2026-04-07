//
// FKButton+Elements.swift
//
// Value-type models for titles, subtitles, image slots, and custom content.
//

import UIKit

public extension FKButton {
  /// Title/subtitle display parameters rendered by an internal `UILabel`.
  /// Register per state via `setTitle(_:for:)` / `setSubtitle(_:for:)`.
  ///
  /// Compared to `UIButton`: keep font, paragraph styling, shadow, and accessibility in one place.
  struct Text {
    /// Plain text. When `attributedText != nil`, rich text takes precedence.
    public var text: String?
    public var attributedText: NSAttributedString?

    /// Font and color used for non-attributed text.
    public var font: UIFont
    public var color: UIColor

    public var alignment: NSTextAlignment
    /// `0` means no line limit.
    public var numberOfLines: Int
    public var lineBreakMode: NSLineBreakMode

    /// Tracking (kerning), in points.
    public var kerning: CGFloat
    /// `0` means default line height.
    public var lineHeight: CGFloat
    public var lineSpacing: CGFloat

    public var adjustsFontSizeToFitWidth: Bool
    public var minimumScaleFactor: CGFloat
    public var allowsDefaultTighteningForTruncation: Bool

    public var shadowColor: UIColor?
    public var shadowOffset: CGSize

    public var uppercased: Bool
    public var lowercased: Bool

    /// Used for accessibility; falls back to `text` when `nil`.
    public var accessibilityLabel: String?
    public var accessibilityHint: String?

    /// Directional insets for the title/subtitle inside its container.
    public var contentInsets: NSDirectionalEdgeInsets

    public init(
      text: String? = nil,
      attributedText: NSAttributedString? = nil,
      font: UIFont = .preferredFont(forTextStyle: .body),
      color: UIColor = .label,
      alignment: NSTextAlignment = .center,
      numberOfLines: Int = 0,
      lineBreakMode: NSLineBreakMode = .byTruncatingTail,
      kerning: CGFloat = 0,
      lineHeight: CGFloat = 0,
      lineSpacing: CGFloat = 0,
      adjustsFontSizeToFitWidth: Bool = false,
      minimumScaleFactor: CGFloat = 0.75,
      allowsDefaultTighteningForTruncation: Bool = false,
      shadowColor: UIColor? = nil,
      shadowOffset: CGSize = .zero,
      uppercased: Bool = false,
      lowercased: Bool = false,
      accessibilityLabel: String? = nil,
      accessibilityHint: String? = nil,
      contentInsets: NSDirectionalEdgeInsets = .zero
    ) {
      self.text = text
      self.attributedText = attributedText
      self.font = font
      self.color = color
      self.alignment = alignment
      self.numberOfLines = numberOfLines
      self.lineBreakMode = lineBreakMode
      self.kerning = kerning
      self.lineHeight = lineHeight
      self.lineSpacing = lineSpacing
      self.adjustsFontSizeToFitWidth = adjustsFontSizeToFitWidth
      self.minimumScaleFactor = minimumScaleFactor
      self.allowsDefaultTighteningForTruncation = allowsDefaultTighteningForTruncation
      self.shadowColor = shadowColor
      self.shadowOffset = shadowOffset
      self.uppercased = uppercased
      self.lowercased = lowercased
      self.accessibilityLabel = accessibilityLabel
      self.accessibilityHint = accessibilityHint
      self.contentInsets = contentInsets
    }

    public nonisolated(unsafe) static let `default` = Text()
  }
  
  /// Display parameters for an image slot (hosted by `UIImageView`).
  /// Register per state via `setImage` / `setLeadingImage` / `setTrailingImage`.
  struct Image {
    /// Prefer `image`. When `image` is nil, fall back to `systemName` (SF Symbol).
    public var image: UIImage?
    public var systemName: String?

    public var renderingMode: UIImage.RenderingMode
    public var symbolConfiguration: UIImage.SymbolConfiguration?
    public var flipsForRightToLeftLayoutDirection: Bool

    /// When nil, uses the control's `tintColor`.
    public var tintColor: UIColor?
    public var alpha: CGFloat

    public var fixedSize: CGSize?
    public var minimumSize: CGSize?
    public var maximumSize: CGSize?

    public var preserveAspectRatio: Bool
    public var contentMode: UIView.ContentMode

    public var spacingToTitle: CGFloat
    public var contentInsets: NSDirectionalEdgeInsets
    /// Expands tappable area (same sign semantics as `UIEdgeInsets`).
    public var hitTestOutsets: UIEdgeInsets

    public var accessibilityLabel: String?
    public var accessibilityHint: String?
    /// Accessibility/testing identifier.
    public var accessibilityIdentifier: String?

    public init(
      image: UIImage? = nil,
      systemName: String? = nil,
      renderingMode: UIImage.RenderingMode = .alwaysTemplate,
      symbolConfiguration: UIImage.SymbolConfiguration? = nil,
      flipsForRightToLeftLayoutDirection: Bool = true,
      tintColor: UIColor? = nil,
      alpha: CGFloat = 1.0,
      fixedSize: CGSize? = nil,
      minimumSize: CGSize? = nil,
      maximumSize: CGSize? = nil,
      preserveAspectRatio: Bool = true,
      contentMode: UIView.ContentMode = .scaleAspectFit,
      spacingToTitle: CGFloat = 6,
      contentInsets: NSDirectionalEdgeInsets = .zero,
      hitTestOutsets: UIEdgeInsets = .zero,
      accessibilityLabel: String? = nil,
      accessibilityHint: String? = nil,
      accessibilityIdentifier: String? = nil
    ) {
      self.image = image
      self.systemName = systemName
      self.renderingMode = renderingMode
      self.symbolConfiguration = symbolConfiguration
      self.flipsForRightToLeftLayoutDirection = flipsForRightToLeftLayoutDirection
      self.tintColor = tintColor
      self.alpha = alpha
      self.fixedSize = fixedSize
      self.minimumSize = minimumSize
      self.maximumSize = maximumSize
      self.preserveAspectRatio = preserveAspectRatio
      self.contentMode = contentMode
      self.spacingToTitle = spacingToTitle
      self.contentInsets = contentInsets
      self.hitTestOutsets = hitTestOutsets
      self.accessibilityLabel = accessibilityLabel
      self.accessibilityHint = accessibilityHint
      self.accessibilityIdentifier = accessibilityIdentifier
    }

    public nonisolated(unsafe) static let `default` = Image()
  }
  
  /// Use when providing a custom `UIView` as the main content.
  /// Set `content.kind` to `.custom` and register via `setCustomContent(_:for:)`.
  ///
  /// This does not wrap properties that should be set by the caller (e.g. alpha, backgroundColor, tint, constraints).
  /// Size should be handled via Auto Layout or `intrinsicContentSize`.
  struct CustomContent {
    /// `nil` means no custom content for this state.
    public var view: UIView?

    /// Spacing to adjacent content (semantic alignment with `Image.spacingToTitle`).
    public var spacingToAdjacentContent: CGFloat

    public init(view: UIView? = nil, spacingToAdjacentContent: CGFloat = 6) {
      self.view = view
      self.spacingToAdjacentContent = spacingToAdjacentContent
    }

    public nonisolated(unsafe) static let `default` = CustomContent()
  }

}
