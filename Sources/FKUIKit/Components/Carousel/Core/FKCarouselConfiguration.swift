//
// FKCarouselConfiguration.swift
//

import UIKit

/// Page control horizontal alignment at the bottom of carousel.
public enum FKCarouselPageControlAlignment: Sendable {
  /// Center aligned.
  case center
  /// Left aligned.
  case left
  /// Right aligned.
  case right
}

/// Dot style for custom page control implementation.
///
/// Configure this type to customize indicator geometry and visual states.
public struct FKCarouselPageControlStyle {
  /// Size of normal dot.
  public var normalDotSize: CGSize
  /// Size of selected dot.
  public var selectedDotSize: CGSize
  /// Tint color of normal dot when `normalDotImage` is nil.
  public var normalColor: UIColor
  /// Tint color of selected dot when `selectedDotImage` is nil.
  public var selectedColor: UIColor
  /// Optional image used by normal dot.
  public var normalDotImage: UIImage?
  /// Optional image used by selected dot.
  public var selectedDotImage: UIImage?
  /// Spacing between dots.
  ///
  /// Default value is `6`.
  public var spacing: CGFloat

  /// Creates dot style.
  ///
  /// - Parameters:
  ///   - normalDotSize: Default is `6x6`.
  ///   - selectedDotSize: Default is `16x6`.
  ///   - normalColor: Dot tint when not selected.
  ///   - selectedColor: Dot tint when selected.
  ///   - normalDotImage: Optional custom image for non-selected state.
  ///   - selectedDotImage: Optional custom image for selected state.
  ///   - spacing: Dot spacing value.
  public init(
    normalDotSize: CGSize = .init(width: 6, height: 6),
    selectedDotSize: CGSize = .init(width: 16, height: 6),
    normalColor: UIColor = .systemGray4,
    selectedColor: UIColor = .white,
    normalDotImage: UIImage? = nil,
    selectedDotImage: UIImage? = nil,
    spacing: CGFloat = 6
  ) {
    self.normalDotSize = normalDotSize
    self.selectedDotSize = selectedDotSize
    self.normalColor = normalColor
    self.selectedColor = selectedColor
    self.normalDotImage = normalDotImage
    self.selectedDotImage = selectedDotImage
    self.spacing = spacing
  }
}

/// Visual style for carousel layer-level appearance.
///
/// Use this style to control corner, border, shadow, and image content rendering behavior.
public struct FKCarouselContainerStyle {
  /// Corner radius of carousel container.
  ///
  /// Default value is `0`.
  public var cornerRadius: CGFloat
  /// Border width of carousel container.
  ///
  /// Default value is `0`.
  public var borderWidth: CGFloat
  /// Border color of carousel container.
  ///
  /// Default value is `.clear`.
  public var borderColor: UIColor
  /// Shadow color of carousel container.
  ///
  /// Default value is `.clear`.
  public var shadowColor: UIColor
  /// Shadow opacity of carousel container.
  ///
  /// Valid range is `0...1`. Default value is `0`.
  public var shadowOpacity: Float
  /// Shadow radius of carousel container.
  ///
  /// Default value is `0`.
  public var shadowRadius: CGFloat
  /// Shadow offset of carousel container.
  ///
  /// Default value is `.zero`.
  public var shadowOffset: CGSize
  /// Shared content mode for image cells.
  ///
  /// Default value is `.scaleAspectFill`.
  public var contentMode: UIView.ContentMode

  /// Creates layer appearance style.
  ///
  /// - Parameters:
  ///   - cornerRadius: Corner radius applied to carousel content container.
  ///   - borderWidth: Border width applied to carousel content container.
  ///   - borderColor: Border color applied to carousel content container.
  ///   - shadowColor: Shadow color applied to outer carousel host.
  ///   - shadowOpacity: Shadow opacity in the range `0...1`.
  ///   - shadowRadius: Shadow blur radius.
  ///   - shadowOffset: Shadow position offset.
  ///   - contentMode: Content mode used by image-based carousel cells.
  public init(
    cornerRadius: CGFloat = 0,
    borderWidth: CGFloat = 0,
    borderColor: UIColor = .clear,
    shadowColor: UIColor = .clear,
    shadowOpacity: Float = 0,
    shadowRadius: CGFloat = 0,
    shadowOffset: CGSize = .zero,
    contentMode: UIView.ContentMode = .scaleAspectFill
  ) {
    self.cornerRadius = cornerRadius
    self.borderWidth = borderWidth
    self.borderColor = borderColor
    self.shadowColor = shadowColor
    self.shadowOpacity = shadowOpacity
    self.shadowRadius = shadowRadius
    self.shadowOffset = shadowOffset
    self.contentMode = contentMode
  }
}

/// Configuration for `FKCarousel`.
///
/// This structure centralizes carousel behavior and styling in a single value object.
public struct FKCarouselConfiguration {
  /// Enables infinite loop if item count > 1.
  ///
  /// Default value is `true`.
  public var isInfiniteEnabled: Bool
  /// Enables automatic paging.
  ///
  /// Default value is `true`.
  public var isAutoScrollEnabled: Bool
  /// Auto scroll interval in seconds.
  ///
  /// Values lower than `0.5` are clamped to `0.5` to avoid overly aggressive timer firing.
  public var autoScrollInterval: TimeInterval
  /// Scroll direction.
  ///
  /// Default value is `.horizontal`.
  public var direction: FKCarouselDirection
  /// Shows custom page control.
  ///
  /// Default value is `true`.
  public var showsPageControl: Bool
  /// Page control alignment.
  ///
  /// Default value is `.center`.
  public var pageControlAlignment: FKCarouselPageControlAlignment
  /// Page control insets from carousel bounds.
  ///
  /// Default value is `UIEdgeInsets(top: 0, left: 12, bottom: 8, right: 12)`.
  public var pageControlInsets: UIEdgeInsets
  /// Dot style.
  ///
  /// Default value is `FKCarouselPageControlStyle()`.
  public var pageControlStyle: FKCarouselPageControlStyle
  /// Placeholder image for remote image loading.
  ///
  /// Default value is `nil`.
  public var placeholderImage: UIImage?
  /// Fallback image when remote loading fails.
  ///
  /// Default value is `nil`.
  public var failureImage: UIImage?
  /// Style applied to carousel container and image rendering.
  ///
  /// Default value is `FKCarouselContainerStyle()`.
  public var containerStyle: FKCarouselContainerStyle

  /// Creates carousel configuration.
  ///
  /// - Parameters:
  ///   - isInfiniteEnabled: Enables virtual-index infinite loop behavior.
  ///   - isAutoScrollEnabled: Enables timer-driven automatic paging.
  ///   - autoScrollInterval: Timer interval in seconds.
  ///   - direction: Scroll direction used by collection view layout.
  ///   - showsPageControl: Controls page control visibility.
  ///   - pageControlAlignment: Horizontal alignment of page control.
  ///   - pageControlInsets: Insets used to place page control near bottom edge.
  ///   - pageControlStyle: Dot style for page control rendering.
  ///   - placeholderImage: Placeholder image for pending network loading.
  ///   - failureImage: Fallback image for failed network loading.
  ///   - containerStyle: Layer-level visual style for carousel host and images.
  public init(
    isInfiniteEnabled: Bool = true,
    isAutoScrollEnabled: Bool = true,
    autoScrollInterval: TimeInterval = 3,
    direction: FKCarouselDirection = .horizontal,
    showsPageControl: Bool = true,
    pageControlAlignment: FKCarouselPageControlAlignment = .center,
    pageControlInsets: UIEdgeInsets = .init(top: 0, left: 12, bottom: 8, right: 12),
    pageControlStyle: FKCarouselPageControlStyle = .init(),
    placeholderImage: UIImage? = nil,
    failureImage: UIImage? = nil,
    containerStyle: FKCarouselContainerStyle = .init()
  ) {
    self.isInfiniteEnabled = isInfiniteEnabled
    self.isAutoScrollEnabled = isAutoScrollEnabled
    self.autoScrollInterval = max(0.5, autoScrollInterval)
    self.direction = direction
    self.showsPageControl = showsPageControl
    self.pageControlAlignment = pageControlAlignment
    self.pageControlInsets = pageControlInsets
    self.pageControlStyle = pageControlStyle
    self.placeholderImage = placeholderImage
    self.failureImage = failureImage
    self.containerStyle = containerStyle
  }
}
