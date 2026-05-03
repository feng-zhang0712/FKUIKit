import UIKit

// MARK: - Text

/// Typography and styling for tab titles and subtitles.
public struct FKTabBarTextStyle: Equatable {
  public var font: UIFont
  public var color: UIColor
  public var numberOfLines: Int
  public var alignment: NSTextAlignment
  public var lineBreakMode: NSLineBreakMode
  public var adjustsForContentSizeCategory: Bool
  public var adjustsFontSizeToFitWidth: Bool
  public var minimumScaleFactor: CGFloat
  public var contentInsets: NSDirectionalEdgeInsets

  public init(
    font: UIFont = .systemFont(ofSize: 14, weight: .regular),
    color: UIColor = .label,
    numberOfLines: Int = 1,
    alignment: NSTextAlignment = .center,
    lineBreakMode: NSLineBreakMode = .byTruncatingTail,
    adjustsForContentSizeCategory: Bool = true,
    adjustsFontSizeToFitWidth: Bool = false,
    minimumScaleFactor: CGFloat = 1,
    contentInsets: NSDirectionalEdgeInsets = .zero
  ) {
    self.font = font
    self.color = color
    self.numberOfLines = max(1, numberOfLines)
    self.alignment = alignment
    self.lineBreakMode = lineBreakMode
    self.adjustsForContentSizeCategory = adjustsForContentSizeCategory
    self.adjustsFontSizeToFitWidth = adjustsFontSizeToFitWidth
    self.minimumScaleFactor = max(0.5, min(1, minimumScaleFactor))
    self.contentInsets = contentInsets
  }
}

/// Title or subtitle text with optional per-state overrides (`normal` / `selected` / `disabled`).
public struct FKTabBarTextConfiguration: Equatable {
  public struct State: Equatable {
    public var text: String?
    public var style: FKTabBarTextStyle

    public init(text: String? = nil, style: FKTabBarTextStyle = .init()) {
      self.text = text
      self.style = style
    }
  }

  public var normal: State
  public var selected: State?
  public var disabled: State?
  /// Vertical spacing between title and subtitle when both are shown.
  public var spacingToNextText: CGFloat

  public init(
    normal: State = .init(),
    selected: State? = nil,
    disabled: State? = nil,
    spacingToNextText: CGFloat = 2
  ) {
    self.normal = normal
    self.selected = selected
    self.disabled = disabled
    self.spacingToNextText = max(0, spacingToNextText)
  }

  public func resolved(isSelected: Bool, isEnabled: Bool) -> State {
    if !isEnabled {
      return disabled ?? normal
    }
    if isSelected {
      return selected ?? normal
    }
    return normal
  }
}

// MARK: - Image

/// Resolved image input for a tab (local asset, symbol, remote placeholder, etc.).
public enum FKTabBarImageSource: Equatable {
  case image(UIImage)
  case systemSymbol(name: String)
  case asset(name: String, in: Bundle? = nil)
  /// Remote URL for host-side loading. `FKTabBar` does not fetch network data; resolve in `itemViewProvider` or map to `.image`.
  case remote(urlString: String, placeholder: UIImage? = nil)
}

/// Layout and tint for tab images.
public struct FKTabBarImageStyle: Equatable {
  public enum Position: Equatable {
    case leading
    case trailing
  }

  public var tintColor: UIColor?
  public var fixedSize: CGSize
  public var spacingToTitle: CGFloat
  public var position: Position

  public init(
    tintColor: UIColor? = nil,
    fixedSize: CGSize = .init(width: 22, height: 22),
    spacingToTitle: CGFloat = 6,
    position: Position = .leading
  ) {
    self.tintColor = tintColor
    self.fixedSize = fixedSize
    self.spacingToTitle = spacingToTitle
    self.position = position
  }
}

/// Image with optional per-state overrides (`normal` / `selected` / `disabled`).
public struct FKTabBarImageConfiguration: Equatable {
  public struct State: Equatable {
    public var source: FKTabBarImageSource?
    public var style: FKTabBarImageStyle

    public init(source: FKTabBarImageSource? = nil, style: FKTabBarImageStyle = .init()) {
      self.source = source
      self.style = style
    }
  }

  public var normal: State
  public var selected: State?
  public var disabled: State?

  public init(
    normal: State = .init(),
    selected: State? = nil,
    disabled: State? = nil
  ) {
    self.normal = normal
    self.selected = selected
    self.disabled = disabled
  }

  public func resolved(isSelected: Bool, isEnabled: Bool) -> State {
    if !isEnabled {
      return disabled ?? normal
    }
    if isSelected {
      return selected ?? normal
    }
    return normal
  }
}
