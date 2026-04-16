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
        self.duration = max(0, duration)
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
        self.opacity = max(0, min(1, opacity))
        self.offset = offset
        self.radius = max(0, radius)
      }
    }

    public struct CornerStyle: Sendable {
      public var radius: CGFloat
      public var curve: CALayerCornerCurve
      public var maskedCorners: CACornerMask

      public init(
        radius: CGFloat = 0,
        curve: CALayerCornerCurve = .continuous,
        maskedCorners: CACornerMask = [
          .layerMinXMinYCorner,
          .layerMaxXMinYCorner,
          .layerMinXMaxYCorner,
          .layerMaxXMaxYCorner,
        ]
      ) {
        self.radius = max(0, radius)
        self.curve = curve
        self.maskedCorners = maskedCorners
      }
    }

    public struct Border: Sendable {
      public var width: CGFloat
      public var color: UIColor

      public init(width: CGFloat = 0, color: UIColor = .clear) {
        self.width = max(0, width)
        self.color = color
      }
    }

    public enum ShadowPathStrategy: Sendable {
      case automatic
      case none
    }

    /// Background, corner radius, border, and shadow for the bar root view.
    public struct Appearance: Sendable {
      public var backgroundColor: UIColor
      public var alpha: CGFloat

      public var cornerStyle: CornerStyle

      public var border: Border

      /// Shadow configuration; `nil` disables shadow.
      public var shadow: Shadow?
      /// Whether to keep `layer.shadowPath` in sync with current bounds/corners.
      public var shadowPathStrategy: ShadowPathStrategy

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
        shadowPathStrategy: ShadowPathStrategy = .automatic,
        clipsToBounds: Bool? = nil
      ) {
        self.backgroundColor = backgroundColor
        self.alpha = max(0, min(1, alpha))
        self.cornerStyle = CornerStyle(radius: cornerRadius, curve: cornerCurve, maskedCorners: maskedCorners)
        self.border = Border(width: borderWidth, color: borderColor)
        self.shadow = shadow
        self.shadowPathStrategy = shadowPathStrategy
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

    /// How the **row of bar items** is arranged along the horizontal axis relative to the visible width
    /// (scroll vs. centered group vs. space-between, etc.).
    ///
    /// This is orthogonal to cross-axis ``Configuration/alignment``. Spacing between items is
    /// ``itemSpacing``. Along-axis stacking uses ``Configuration/distribution`` when `FKBar` applies your
    /// setting; some ``Arrangement`` modes temporarily override it while the row fits the visible width.
    ///
    /// - **`leading`**: uses ``Configuration/distribution`` for the internal `UIStackView`.
    /// - **`center` / `trailing`**: when the row **fits** the bar, distribution is `.fill`; when **overflowing**,
    ///   falls back to scrollable layout using ``Configuration/distribution``.
    /// - **`between` / `around` / `evenlyDistributed`**: when the row **fits**, distribution is
    ///   `.equalSpacing`, `.equalCentering`, or `.fillEqually` respectively; when **overflowing**,
    ///   ``Configuration/distribution``.
    public enum Arrangement: Sendable, Equatable {
      case leading
      case center
      case trailing
      case between
      case around
      case evenlyDistributed
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

    /// How the item row is arranged horizontally vs. the visible bar (see ``Arrangement``).
    public var arrangement: Arrangement

    /// Whether to apply built-in fallback visuals for selected/disabled states (background/foreground/alpha).
    public var usesDefaultSelectionAppearance: Bool

    /// Cross-axis (vertical) alignment of bar items in the horizontal `UIStackView`
    /// (e.g. `.top` / `.center` / `.bottom`, or baseline modes when subviews expose baselines).
    /// Always mapped directly to the stack; never overridden by ``arrangement``.
    public var alignment: UIStackView.Alignment

    /// Along-axis `UIStackView.distribution` from configuration when `FKBar` uses your value:
    /// - ``Arrangement/leading``: always ``distribution``.
    /// - Any other ``Arrangement``: when the row **overflows** (scrollable fallback), always ``distribution``.
    ///
    /// When the row **fits** the visible width, `FKBar` may ignore this property and set `.fill`
    /// (``Arrangement/center``, ``Arrangement/trailing``) or `.equalSpacing` / `.equalCentering` /
    /// `.fillEqually` (``Arrangement/between``, ``Arrangement/around``, ``Arrangement/evenlyDistributed``)—see ``Arrangement``.
    public var distribution: UIStackView.Distribution

    public init(
      itemSpacing: CGFloat = 10,
      contentInsets: NSDirectionalEdgeInsets = .zero,
      alwaysBounceHorizontal: Bool = false,
      showsHorizontalScrollIndicator: Bool = false,
      isScrollEnabled: Bool = true,
      enablesSelectionWhileScrollingDisabled: Bool = true,
      appearance: Appearance = .init(),
      selectionScroll: SelectionScroll = .init(),
      arrangement: Arrangement = .leading,
      usesDefaultSelectionAppearance: Bool = false,
      alignment: UIStackView.Alignment = .center,
      distribution: UIStackView.Distribution = .fill
    ) {
      self.itemSpacing = max(0, itemSpacing)
      self.contentInsets = contentInsets
      self.alwaysBounceHorizontal = alwaysBounceHorizontal
      self.showsHorizontalScrollIndicator = showsHorizontalScrollIndicator
      self.isScrollEnabled = isScrollEnabled
      self.enablesSelectionWhileScrollingDisabled = enablesSelectionWhileScrollingDisabled
      self.appearance = appearance
      self.selectionScroll = selectionScroll
      self.arrangement = arrangement
      self.usesDefaultSelectionAppearance = usesDefaultSelectionAppearance
      self.alignment = alignment
      self.distribution = distribution
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
      setStoredConfiguration(newValue)
      applyBarConfiguration(animated: false, completion: nil)
    }
  }

  internal func setStoredConfiguration(_ configuration: Configuration) {
    objc_setAssociatedObject(
      self,
      &FKBarConfigurationAssociatedKeys.configuration,
      configuration,
      .OBJC_ASSOCIATION_RETAIN_NONATOMIC
    )
  }

  /// Applies `configuration` to the bar root view and internal `UIScrollView` / `UIStackView`.
  func applyBarConfiguration(animated: Bool = false, completion: (() -> Void)? = nil) {
    let cfg = configuration

    let apply = {
      // MARK: - Appearance (bar layer)
      self.backgroundColor = cfg.appearance.backgroundColor
      self.alpha = cfg.appearance.alpha

      let layer = self.layer
      layer.cornerRadius = cfg.appearance.cornerStyle.radius
      layer.cornerCurve = cfg.appearance.cornerStyle.curve
      layer.maskedCorners = cfg.appearance.cornerStyle.maskedCorners
      layer.borderWidth = cfg.appearance.border.width
      layer.borderColor = cfg.appearance.border.color.cgColor

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
        self.updateBarShadowPathIfNeeded()
      } else {
        layer.shadowOpacity = 0
        layer.shadowColor = nil
        layer.shadowRadius = 0
        layer.shadowOffset = .zero
        layer.shadowPath = nil
      }

      // MARK: - Scroll view & stack view (descendants)
      let scrollView = self._configurationScrollView
      scrollView.alwaysBounceHorizontal = cfg.alwaysBounceHorizontal
      scrollView.showsHorizontalScrollIndicator = cfg.showsHorizontalScrollIndicator
      scrollView.isScrollEnabled = cfg.isScrollEnabled

      let insets = self.resolvedDirectionalInsets(cfg.contentInsets)

      scrollView.contentInset = insets
      scrollView.scrollIndicatorInsets = insets

      let stackView = self._configurationStackView
      stackView.spacing = cfg.itemSpacing
      stackView.alignment = cfg.alignment
      self.applyArrangementFromConfiguration()
    }

    if animated {
      UIView.animate(withDuration: 0.25, animations: apply, completion: { _ in completion?() })
    } else {
      apply()
      completion?()
    }
  }

  // MARK: - Private helpers
  internal func updateBarShadowPathIfNeeded() {
    let appearance = configuration.appearance
    guard appearance.shadow != nil, appearance.shadowPathStrategy == .automatic else {
      layer.shadowPath = nil
      return
    }
    layer.shadowPath = UIBezierPath(
      roundedRect: bounds,
      byRoundingCorners: appearance.cornerStyle.maskedCorners.uiRectCorner,
      cornerRadii: CGSize(width: appearance.cornerStyle.radius, height: appearance.cornerStyle.radius)
    ).cgPath
  }

  private func resolvedDirectionalInsets(_ insets: NSDirectionalEdgeInsets) -> UIEdgeInsets {
    let isRTL = UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .rightToLeft
    let left = isRTL ? insets.trailing : insets.leading
    let right = isRTL ? insets.leading : insets.trailing
    return UIEdgeInsets(top: insets.top, left: left, bottom: insets.bottom, right: right)
  }
}

private extension CACornerMask {
  var uiRectCorner: UIRectCorner {
    var corners: UIRectCorner = []
    if contains(.layerMinXMinYCorner) { corners.insert(.topLeft) }
    if contains(.layerMaxXMinYCorner) { corners.insert(.topRight) }
    if contains(.layerMinXMaxYCorner) { corners.insert(.bottomLeft) }
    if contains(.layerMaxXMaxYCorner) { corners.insert(.bottomRight) }
    return corners
  }
}
