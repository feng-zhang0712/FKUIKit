//
// FKButton+Elements.swift
//
// 标题、副标题、图片槽、自定义内容等 **值类型** 模型，与 `setTitle` / `setImage` 等状态 API 配合使用。
//

import UIKit

public extension FKButton {
  /// 标题或副标题的展示参数，由内部 `UILabel` 承载；通过 `setTitle(_:for:)` / `setSubtitle(_:for:)` 按状态注册。
  ///
  /// 相对系统 `UIButton`：把字体、段落、阴影、无障碍等收拢在一处，便于与 `content.kind`、`axis` 及状态机一致更新。
  struct Text {
    /// 纯文本；若 `attributedText != nil` 则优先使用富文本。
    public var text: String?
    public var attributedText: NSAttributedString?

    /// 非富文本时的字体与颜色。
    public var font: UIFont
    public var color: UIColor

    public var alignment: NSTextAlignment
    /// `0` 表示不限制行数。
    public var numberOfLines: Int
    public var lineBreakMode: NSLineBreakMode

    /// 字距/tracking，单位 point。
    public var kerning: CGFloat
    /// `0` 表示默认行高。
    public var lineHeight: CGFloat
    public var lineSpacing: CGFloat

    public var adjustsFontSizeToFitWidth: Bool
    public var minimumScaleFactor: CGFloat
    public var allowsDefaultTighteningForTruncation: Bool

    public var shadowColor: UIColor?
    public var shadowOffset: CGSize

    public var uppercased: Bool
    public var lowercased: Bool

    /// `nil` 时可回退为朗读 `text`。
    public var accessibilityLabel: String?
    public var accessibilityHint: String?

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
      accessibilityHint: String? = nil
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
    }

    public nonisolated(unsafe) static let `default` = Text()
  }
  
  /// 图片槽展示参数，内部由 `UIImageView` 承载；通过 `setImage` / `setLeadingImage` / `setTrailingImage` 按状态注册。
  struct Image {
    /// 优先使用 `image`；为 `nil` 时可回退 `systemName`（SF Symbol）。
    public var image: UIImage?
    public var systemName: String?

    public var renderingMode: UIImage.RenderingMode
    public var symbolConfiguration: UIImage.SymbolConfiguration?
    public var flipsForRightToLeftLayoutDirection: Bool

    /// `nil` 时使用控件 `tintColor`。
    public var tintColor: UIColor?
    public var alpha: CGFloat

    public var fixedSize: CGSize?
    public var minimumSize: CGSize?
    public var maximumSize: CGSize?

    public var preserveAspectRatio: Bool
    public var contentMode: UIView.ContentMode

    public var spacingToTitle: CGFloat
    public var contentInsets: NSDirectionalEdgeInsets
    /// 扩大可点区域，单位同 `UIEdgeInsets` 正值语义。
    public var hitTestOutsets: UIEdgeInsets

    public var accessibilityLabel: String?
    public var accessibilityHint: String?
    /// UI 测试等场景的定位标识。
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
  
  /// 将自定义 `UIView` 作为主内容时使用；需将 `content.kind` 设为 `.custom`，并用 `setCustomContent(_:for:)` 按状态注册。
  ///
  /// 不在此重复包装 `view` 上应由调用方设置的属性（如 `alpha`、`backgroundColor`、`tint`、约束、无障碍等），以免覆盖外部配置。尺寸请用 Auto Layout 或 `intrinsicContentSize`。
  struct CustomContent {
    /// `nil` 表示该状态下无自定义内容。
    public var view: UIView?

    /// 与同轴相邻内容的间距，语义对齐 `Image.spacingToTitle`；当前仅单自定义视图布局时通常无视觉效果，预留给图文混排扩展。
    public var spacingToAdjacentContent: CGFloat

    public init(view: UIView? = nil, spacingToAdjacentContent: CGFloat = 6) {
      self.view = view
      self.spacingToAdjacentContent = spacingToAdjacentContent
    }

    public nonisolated(unsafe) static let `default` = CustomContent()
  }

}
