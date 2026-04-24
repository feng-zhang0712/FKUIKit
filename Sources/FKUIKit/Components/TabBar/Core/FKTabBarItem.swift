import UIKit

/// Shared text style used by title/subtitle configuration.
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

/// Stateful text configuration for normal/selected/disabled rendering.
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
  /// Vertical spacing between title and subtitle labels.
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


/// Image source model for tab content.
public enum FKTabBarImageSource: Equatable {
  /// Direct image object.
  case image(UIImage)
  /// SF Symbols name.
  case systemSymbol(name: String)
  /// Local asset name from bundle.
  case asset(name: String, in: Bundle? = nil)
  /// Remote URL mapped by host app with an optional placeholder.
  ///
  /// `FKTabBar` does not perform networking. Apps can resolve this value in
  /// `FKTabBar.itemViewProvider` or pre-map to `.image`.
  case remote(urlString: String, placeholder: UIImage? = nil)
}

/// Image rendering style.
public struct FKTabBarImageStyle: Equatable {
  public var tintColor: UIColor?
  public var fixedSize: CGSize
  public var spacingToTitle: CGFloat

  public init(tintColor: UIColor? = nil, fixedSize: CGSize = .init(width: 22, height: 22), spacingToTitle: CGFloat = 6) {
    self.tintColor = tintColor
    self.fixedSize = fixedSize
    self.spacingToTitle = spacingToTitle
  }
}

/// Stateful image configuration for normal/selected/disabled rendering.
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

/// A single tab descriptor used by `FKTabBar`.
///
/// Keep `id` stable across dynamic updates to preserve selection and animation continuity.
public struct FKTabBarItem: Equatable {
  /// Stable identifier for diffing and selection retention.
  public let id: String

  /// Primary title text configuration.
  ///
  /// Priority: item-level configuration > `FKTabBarConfiguration.appearance` defaults > internal fallback.
  public var title: FKTabBarTextConfiguration
  /// Optional subtitle text configuration.
  public var subtitle: FKTabBarTextConfiguration?
  /// Optional image configuration.
  public var image: FKTabBarImageConfiguration?
  /// Optional custom content identifier.
  ///
  /// When non-`nil`, `FKTabBar.itemViewProvider` is used to resolve custom view content.
  public var customContentIdentifier: String?

  /// Whether this tab can be selected.
  public var isEnabled: Bool

  /// Whether this tab is visible in the header.
  ///
  /// Hidden tabs are excluded from layout and interaction.
  public var isHidden: Bool

  /// Badge configuration.
  public var badge: FKTabBarBadgeConfiguration

  /// Optional accessibility label override.
  ///
  /// When `nil`, title text from `title.normal.text` or `id` is used as fallback.
  public var accessibilityLabel: String?

  /// Optional accessibility hint override.
  public var accessibilityHint: String?

  /// Creates a tab item.
  ///
  /// - Parameters:
  ///   - id: Stable identifier.
  ///   - title: Primary title configuration.
  ///   - subtitle: Optional subtitle configuration.
  ///   - image: Optional image configuration.
  ///   - customContentIdentifier: Optional custom content key consumed by `itemViewProvider`.
  ///   - isEnabled: Enabled state.
  ///   - isHidden: Hidden state in header layout.
  ///   - badge: Badge configuration.
  ///   - accessibilityLabel: Optional accessibility label.
  ///   - accessibilityHint: Optional accessibility hint.
  public init(
    id: String,
    title: FKTabBarTextConfiguration = .init(),
    subtitle: FKTabBarTextConfiguration? = nil,
    image: FKTabBarImageConfiguration? = nil,
    customContentIdentifier: String? = nil,
    isEnabled: Bool = true,
    isHidden: Bool = false,
    badge: FKTabBarBadgeConfiguration = .init(),
    accessibilityLabel: String? = nil,
    accessibilityHint: String? = nil
  ) {
    self.id = id
    self.title = title
    self.subtitle = subtitle
    self.image = image
    self.customContentIdentifier = customContentIdentifier
    self.isEnabled = isEnabled
    self.isHidden = isHidden
    self.badge = badge
    self.accessibilityLabel = accessibilityLabel
    self.accessibilityHint = accessibilityHint
  }
}

public extension FKTabBarItem {
  /// Convenience accessor for primary title text.
  var titleText: String? { title.normal.text }
  /// Convenience accessor for primary subtitle text.
  var subtitleText: String? { subtitle?.normal.text }
}

