//
// FKBar+Configuration.swift
//
// Declarative `FKBar` configuration (spacing, scrolling, appearance, etc.) stored via associated objects.
//

import UIKit

import ObjectiveC.runtime

private enum FKBarConfigurationAssociatedKeys {
  nonisolated(unsafe) static var configuration: UInt8 = 0
}

public extension FKBar {
  /// Layout and visual parameters for the horizontal bar and its internal `UIStackView`.
  struct Configuration: Sendable {
    /// Alignment strategy when auto-scrolling to the selected item.
    public enum SelectionScrollAlignment: Sendable {
      case leading
      case center
      case trailing
    }

    /// Scroll animation parameters when a selection triggers scrolling.
    public struct ScrollAnimation: Sendable {
      public var duration: TimeInterval

      public init(duration: TimeInterval = 0.25) {
        self.duration = duration
      }
    }

    /// Shadow on the bar container layer (semantics aligned with `Appearance.shadow`).
    public struct Shadow: Sendable {
      public var color: UIColor
      public var opacity: Float
      public var offset: CGSize
      public var radius: CGFloat

      public init(
        color: UIColor = .black,
        opacity: Float = 0.18,
        offset: CGSize = CGSize(width: 0, height: 2),
        radius: CGFloat = 4
      ) {
        self.color = color
        self.opacity = opacity
        self.offset = offset
        self.radius = radius
      }
    }

    /// Background, corner radius, border, and shadow for the bar root view.
    public struct Appearance: Sendable {
      public var backgroundColor: UIColor
      public var alpha: CGFloat

      public var cornerRadius: CGFloat
      public var cornerCurve: CALayerCornerCurve
      public var maskedCorners: CACornerMask

      public var borderWidth: CGFloat
      public var borderColor: UIColor

      /// Shadow configuration; `nil` disables shadow.
      public var shadow: Shadow?

      /// Whether to clip subviews. When `nil`, uses:
      /// - Has shadow: do not clip
      /// - No shadow: clip
      public var clipsToBounds: Bool?

      public init(
        backgroundColor: UIColor = .clear,
        alpha: CGFloat = 1.0,
        cornerRadius: CGFloat = 0,
        cornerCurve: CALayerCornerCurve = .continuous,
        maskedCorners: CACornerMask = [
          .layerMinXMinYCorner,
          .layerMaxXMinYCorner,
          .layerMinXMaxYCorner,
          .layerMaxXMaxYCorner,
        ],
        borderWidth: CGFloat = 0,
        borderColor: UIColor = .clear,
        shadow: Shadow? = nil,
        clipsToBounds: Bool? = nil
      ) {
        self.backgroundColor = backgroundColor
        self.alpha = alpha
        self.cornerRadius = cornerRadius
        self.cornerCurve = cornerCurve
        self.maskedCorners = maskedCorners
        self.borderWidth = borderWidth
        self.borderColor = borderColor
        self.shadow = shadow
        self.clipsToBounds = clipsToBounds
      }
    }

    public struct SelectionScroll: Sendable {
    /// Whether to auto-scroll to the corresponding position when an item is selected.
      public var isEnabled: Bool

    /// Alignment strategy when scrolling to an item.
    /// If the item itself also has an alignment field, `FKBar` may apply item-first logic.
      public var alignment: SelectionScrollAlignment

    /// Animation parameters when scrolling is needed.
      public var animation: ScrollAnimation

      public init(
        isEnabled: Bool = true,
        alignment: SelectionScrollAlignment = .center,
        animation: ScrollAnimation = .init()
      ) {
        self.isEnabled = isEnabled
        self.alignment = alignment
        self.animation = animation
      }
    }

    /// Spacing between adjacent items (mapped to `UIStackView.spacing`).
    public var itemSpacing: CGFloat

    /// Directional content insets for the items (mapped to `UIScrollView.contentInset` or other containers).
    public var contentInsets: NSDirectionalEdgeInsets

    /// Whether horizontal bounce is allowed.
    public var alwaysBounceHorizontal: Bool

    /// Whether to show the horizontal scroll indicator.
    public var showsHorizontalScrollIndicator: Bool

    /// Whether scrolling is enabled (disabling makes the bar a static layout).
    public var isScrollEnabled: Bool

    /// When scrolling is disabled, whether items should still respond to taps/clicks.
    public var enablesSelectionWhileScrollingDisabled: Bool

    /// Bar appearance configuration (corners, borders, shadow, etc.).
    public var appearance: Appearance

    /// Scrolling strategy after selection.
    public var selectionScroll: SelectionScroll

    /// Whether to apply built-in fallback visuals for selected/disabled states (background/foreground/alpha).
    public var usesDefaultSelectionAppearance: Bool

    public var stackViewAlignment: UIStackView.Alignment
    public var stackViewDistribution: UIStackView.Distribution

    public init(
      itemSpacing: CGFloat = 10,
      contentInsets: NSDirectionalEdgeInsets = .zero,
      alwaysBounceHorizontal: Bool = false,
      showsHorizontalScrollIndicator: Bool = false,
      isScrollEnabled: Bool = true,
      enablesSelectionWhileScrollingDisabled: Bool = true,
      appearance: Appearance = .init(),
      selectionScroll: SelectionScroll = .init(),
      usesDefaultSelectionAppearance: Bool = false,
      stackViewAlignment: UIStackView.Alignment = .center,
      stackViewDistribution: UIStackView.Distribution = .fill
    ) {
      self.itemSpacing = itemSpacing
      self.contentInsets = contentInsets
      self.alwaysBounceHorizontal = alwaysBounceHorizontal
      self.showsHorizontalScrollIndicator = showsHorizontalScrollIndicator
      self.isScrollEnabled = isScrollEnabled
      self.enablesSelectionWhileScrollingDisabled = enablesSelectionWhileScrollingDisabled
      self.appearance = appearance
      self.selectionScroll = selectionScroll
      self.usesDefaultSelectionAppearance = usesDefaultSelectionAppearance
      self.stackViewAlignment = stackViewAlignment
      self.stackViewDistribution = stackViewDistribution
    }

    public static let `default` = Configuration()
  }

  /// Stored via an associated object; assignment triggers `applyBarConfiguration`.
  var configuration: Configuration {
    get {
      (objc_getAssociatedObject(self, &FKBarConfigurationAssociatedKeys.configuration) as? Configuration)
        ?? .default
    }
    set {
      objc_setAssociatedObject(
        self,
        &FKBarConfigurationAssociatedKeys.configuration,
        newValue,
        .OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
      applyBarConfiguration(animated: false, completion: nil)
    }
  }

  /// Applies `configuration` to the bar root view and descendant `UIScrollView` / `UIStackView`
  /// (found via traversal to keep this file reusable for extensions).
  func applyBarConfiguration(animated: Bool = false, completion: (() -> Void)? = nil) {
    let cfg = configuration

    let apply = {
      // MARK: - Appearance (bar layer)
      self.backgroundColor = cfg.appearance.backgroundColor
      self.alpha = cfg.appearance.alpha

      let layer = self.layer
      layer.cornerRadius = cfg.appearance.cornerRadius
      layer.cornerCurve = cfg.appearance.cornerCurve
      layer.maskedCorners = cfg.appearance.maskedCorners
      layer.borderWidth = cfg.appearance.borderWidth
      layer.borderColor = cfg.appearance.borderColor.cgColor

      let shouldClip: Bool
      if let clipsToBounds = cfg.appearance.clipsToBounds {
        shouldClip = clipsToBounds
      } else {
        shouldClip = (cfg.appearance.shadow == nil)
      }
      self.clipsToBounds = shouldClip

      if let shadow = cfg.appearance.shadow {
        layer.shadowColor = shadow.color.cgColor
        layer.shadowOpacity = shadow.opacity
        layer.shadowRadius = shadow.radius
        layer.shadowOffset = shadow.offset
        // `shadowPath` changes with layout. Re-call this method after external layout completes to refresh.
        layer.shadowPath = nil
      } else {
        layer.shadowOpacity = 0
        layer.shadowColor = nil
        layer.shadowRadius = 0
        layer.shadowOffset = .zero
        layer.shadowPath = nil
      }

      // MARK: - Scroll view & stack view (descendants)
      guard let scrollView = self.firstDescendant(of: UIScrollView.self) else { return }
      scrollView.alwaysBounceHorizontal = cfg.alwaysBounceHorizontal
      scrollView.showsHorizontalScrollIndicator = cfg.showsHorizontalScrollIndicator
      scrollView.isScrollEnabled = cfg.isScrollEnabled

      // NSDirectionalEdgeInsets -> UIEdgeInsets (converted by current semantic direction)
      let isRTL = (UIView.userInterfaceLayoutDirection(for: self.semanticContentAttribute) == .rightToLeft)
      let left = isRTL ? cfg.contentInsets.trailing : cfg.contentInsets.leading
      let right = isRTL ? cfg.contentInsets.leading : cfg.contentInsets.trailing
      let insets = UIEdgeInsets(top: cfg.contentInsets.top, left: left, bottom: cfg.contentInsets.bottom, right: right)

      scrollView.contentInset = insets
      scrollView.scrollIndicatorInsets = insets

      if let stackView = self.firstDescendant(of: UIStackView.self) {
        stackView.spacing = cfg.itemSpacing
        stackView.alignment = cfg.stackViewAlignment
        stackView.distribution = cfg.stackViewDistribution
      }
    }

    if animated {
      UIView.animate(withDuration: 0.25, animations: apply, completion: { _ in completion?() })
    } else {
      apply()
      completion?()
    }
  }

  // MARK: - Private helpers

  private func firstDescendant<T: UIView>(of type: T.Type) -> T? {
    func search(from root: UIView) -> T? {
      for view in root.subviews {
        if let typed = view as? T { return typed }
        if let found = search(from: view) { return found }
      }
      return nil
    }
    if let hit = self as? T { return hit }
    return search(from: self)
  }
}
