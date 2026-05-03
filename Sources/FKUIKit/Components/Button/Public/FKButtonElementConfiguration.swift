import UIKit

// MARK: - Label

/// Typography and accessibility metadata for title or subtitle lines.
public struct FKButtonLabelConfiguration {
  /// Plain-string case transformation rule.
  public enum TextTransform: Equatable, Sendable {
    case none
    case uppercase
    case lowercase
  }

  public var text: String?
  public var attributedText: NSAttributedString?
  public var font: UIFont
  public var color: UIColor
  public var alignment: NSTextAlignment
  public var numberOfLines: Int
  public var lineBreakMode: NSLineBreakMode
  public var kerning: CGFloat
  public var lineHeight: CGFloat
  public var lineSpacing: CGFloat
  /// When `true`, the label automatically reacts to Dynamic Type changes.
  public var adjustsFontForContentSizeCategory: Bool
  /// Optional text style used to scale `font` via `UIFontMetrics` when Dynamic Type is enabled.
  public var textStyle: UIFont.TextStyle?
  public var adjustsFontSizeToFitWidth: Bool
  public var minimumScaleFactor: CGFloat
  public var allowsDefaultTighteningForTruncation: Bool
  public var shadowColor: UIColor?
  public var shadowOffset: CGSize
  public var textTransform: TextTransform
  public var accessibilityLabel: String?
  public var accessibilityHint: String?
  public var contentInsets: NSDirectionalEdgeInsets

  /// Creates a text configuration for `FKButton`.
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
    adjustsFontForContentSizeCategory: Bool = true,
    textStyle: UIFont.TextStyle? = nil,
    adjustsFontSizeToFitWidth: Bool = false,
    minimumScaleFactor: CGFloat = 0.75,
    allowsDefaultTighteningForTruncation: Bool = false,
    shadowColor: UIColor? = nil,
    shadowOffset: CGSize = .zero,
    textTransform: TextTransform = .none,
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
    self.adjustsFontForContentSizeCategory = adjustsFontForContentSizeCategory
    self.textStyle = textStyle
    self.adjustsFontSizeToFitWidth = adjustsFontSizeToFitWidth
    self.minimumScaleFactor = max(0, min(1, minimumScaleFactor))
    self.allowsDefaultTighteningForTruncation = allowsDefaultTighteningForTruncation
    self.shadowColor = shadowColor
    self.shadowOffset = shadowOffset
    self.textTransform = textTransform
    self.accessibilityLabel = accessibilityLabel
    self.accessibilityHint = accessibilityHint
    self.contentInsets = contentInsets
  }

  /// Baseline configuration.
  public nonisolated(unsafe) static let `default` = FKButtonLabelConfiguration()
}

// MARK: - Image

/// Image slot payload (SF Symbols, tint, sizing, RTL, hit-test outsets).
public struct FKButtonImageConfiguration {
  public var image: UIImage?
  public var systemName: String?
  public var renderingMode: UIImage.RenderingMode
  public var symbolConfiguration: UIImage.SymbolConfiguration?
  public var flipsForRightToLeftLayoutDirection: Bool
  public var tintColor: UIColor?
  public var alpha: CGFloat
  public var fixedSize: CGSize?
  public var minimumSize: CGSize?
  public var maximumSize: CGSize?
  public var preserveAspectRatio: Bool
  public var contentMode: UIView.ContentMode
  public var spacingToTitle: CGFloat
  public var contentInsets: NSDirectionalEdgeInsets
  public var hitTestOutsets: UIEdgeInsets
  public var accessibilityLabel: String?
  public var accessibilityHint: String?
  public var accessibilityIdentifier: String?

  /// Creates an image configuration for `FKButton`.
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
    self.alpha = max(0, min(1, alpha))
    self.fixedSize = fixedSize
    self.minimumSize = minimumSize
    self.maximumSize = maximumSize
    self.preserveAspectRatio = preserveAspectRatio
    self.contentMode = contentMode
    self.spacingToTitle = max(0, spacingToTitle)
    self.contentInsets = contentInsets
    self.hitTestOutsets = hitTestOutsets
    self.accessibilityLabel = accessibilityLabel
    self.accessibilityHint = accessibilityHint
    self.accessibilityIdentifier = accessibilityIdentifier
  }

  /// Baseline configuration.
  public nonisolated(unsafe) static let `default` = FKButtonImageConfiguration()
}

// MARK: - Custom

/// Hosts an arbitrary `UIView` when `FKButton.Content.kind == .custom`.
public struct FKButtonCustomContentConfiguration {
  public var view: UIView?
  public var spacingToAdjacentContent: CGFloat

  /// Creates a custom content configuration.
  public init(view: UIView? = nil, spacingToAdjacentContent: CGFloat = 6) {
    self.view = view
    self.spacingToAdjacentContent = max(0, spacingToAdjacentContent)
  }

  /// Baseline configuration.
  public nonisolated(unsafe) static let `default` = FKButtonCustomContentConfiguration()
}
