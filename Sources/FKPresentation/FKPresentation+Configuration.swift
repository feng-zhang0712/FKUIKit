//
// FKPresentation+Configuration.swift
//
// Declarative configuration for an anchored overlay/panel: appearance, layout, mask,
// animations, and repositioning.
//

import UIKit

public extension FKPresentation {
  /// Top-level aggregation; each nested struct provides a `.default`.
  struct Configuration {
    // MARK: Appearance

    /// Controls how the panel content chrome shadow is distributed along the outline
    /// (approximated via `CALayer.shadowPath`; non-rounded-all-edges uses a narrow edge strip).
    public enum ShadowEdgeStyle: Equatable, Sendable {
      /// Follows the vertical anchor: bottom shadow when presented below, top shadow when presented above.
      case followsPresentation
      /// Shadow around the entire rounded rectangle outline (standard card shadow).
      case omnidirectional
      /// Shadow only on specified edges; you can combine edges (e.g. `.top`, `.top.union(.bottom)`).
      case edges(UIRectEdge)
    }

    public struct Shadow: Equatable {
      public var color: UIColor
      public var opacity: Float
      public var offset: CGSize
      public var radius: CGFloat
      /// How the shadow is distributed along edges.
      /// `omnidirectional` matches the full shadow when `shadowPath` is not explicitly configured.
      public var edgeStyle: ShadowEdgeStyle

      public init(
        color: UIColor = .black,
        opacity: Float = 0.18,
        offset: CGSize = CGSize(width: 0, height: 2),
        radius: CGFloat = 4,
        edgeStyle: ShadowEdgeStyle = .followsPresentation
      ) {
        self.color = color
        self.opacity = opacity
        self.offset = offset
        self.radius = radius
        self.edgeStyle = edgeStyle
      }
    }

    /// Appearance for the panel chrome (background, corners, border, and shadow).
    public struct Appearance {
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
          .layerMinXMaxYCorner,
          .layerMaxXMaxYCorner
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

      public nonisolated(unsafe) static let `default` = Appearance()
    }

    // MARK: Content
    /// Constraints related to user content padding and height (relative to chrome).
    public struct Content {
      /// Content padding (applies as the inset inside the presentation content area).
      public var containerInsets: NSDirectionalEdgeInsets

      /// Fallback background when embedding a `UIViewController` whose view has no background color.
      public var fallbackBackgroundColor: UIColor

      /// Explicit height override (higher priority than Auto Layout calculation).
      /// `nil` means computed from intrinsic / preferredSize / fitting.
      public var preferredHeight: CGFloat?

      /// Upper bound for height (used to adapt to visible area). `nil` means no extra limit.
      public var maxHeight: CGFloat?

      public init(
        containerInsets: NSDirectionalEdgeInsets = .init(top: 12, leading: 12, bottom: 12, trailing: 12),
        fallbackBackgroundColor: UIColor = .systemBackground,
        preferredHeight: CGFloat? = nil,
        maxHeight: CGFloat? = nil
      ) {
        self.containerInsets = containerInsets
        self.fallbackBackgroundColor = fallbackBackgroundColor
        self.preferredHeight = preferredHeight
        self.maxHeight = maxHeight
      }

      public nonisolated(unsafe) static let `default` = Content()
    }

    // MARK: Layout/Position
    /// Placement, width, and vertical flip strategy relative to `sourceView` / `sourceRect`.
    public struct Layout {
      public enum HorizontalAlignment {
        case leading
        case center
        case trailing
      }

      public enum WidthMode {
        /// Match the `sourceView` width.
        case matchSourceWidth
        /// Fixed width in points.
        case custom(CGFloat)
        /// Fit to content within available width and clamp.
        case fitWithinContainer
        /// Prefer filling available width within safe area and insets.
        case fullWidth
      }

      /// Vertical spacing from the bottom of `sourceView` to the top of the presentation.
      public var verticalSpacing: CGFloat

      /// Horizontal alignment of the presentation relative to `sourceView`.
      public var horizontalAlignment: HorizontalAlignment

      public var widthMode: WidthMode

      public var widthMin: CGFloat?
      public var widthMax: CGFloat?

      public var maxHeight: CGFloat?
      public var clampToSafeArea: Bool

      /// When `true`, prefer showing below the anchor.
      public var preferBelowSource: Bool
      /// When `true`, flip above the anchor when there isn't enough space below.
      public var allowFlipToAbove: Bool

      public init(
        verticalSpacing: CGFloat = 0,
        horizontalAlignment: HorizontalAlignment = .center,
        widthMode: WidthMode = .fullWidth,
        widthMin: CGFloat? = nil,
        widthMax: CGFloat? = nil,
        maxHeight: CGFloat? = nil,
        clampToSafeArea: Bool = true,
        preferBelowSource: Bool = true,
        allowFlipToAbove: Bool = false
      ) {
        self.verticalSpacing = verticalSpacing
        self.horizontalAlignment = horizontalAlignment
        self.widthMode = widthMode
        self.widthMin = widthMin
        self.widthMax = widthMax
        self.maxHeight = maxHeight
        self.clampToSafeArea = clampToSafeArea
        self.preferBelowSource = preferBelowSource
        self.allowFlipToAbove = allowFlipToAbove
      }

      public nonisolated(unsafe) static let `default` = Layout()
    }

    // MARK: Mask/Interaction
    /// Full-screen or half-screen mask and its tap-to-dismiss behavior.
    public struct Mask {
      public var enabled: Bool
      public var backgroundColor: UIColor
      public var alpha: CGFloat

      public var tapToDismissEnabled: Bool
      public var passthroughViews: [UIView]

      /// Mask coverage strategy: cover only the region below `sourceView`.
      public var coveragePolicy: CoveragePolicy

      public enum CoveragePolicy {
        case belowSourceViewOnly
      }

      public init(
        enabled: Bool = true,
        backgroundColor: UIColor = .black,
        alpha: CGFloat = 0.25,
        tapToDismissEnabled: Bool = true,
        passthroughViews: [UIView] = [],
        coveragePolicy: CoveragePolicy = .belowSourceViewOnly
      ) {
        self.enabled = enabled
        self.backgroundColor = backgroundColor
        self.alpha = alpha
        self.tapToDismissEnabled = tapToDismissEnabled
        self.passthroughViews = passthroughViews
        self.coveragePolicy = coveragePolicy
      }

      public nonisolated(unsafe) static let `default` = Mask()
    }

    /// Strategies related to user interaction and repositioning during show/dismiss.
    public struct Interaction {
      /// Whether dismissing via the mask is allowed during repositioning (e.g. rotation).
      public var allowDismissingDuringReposition: Bool
      /// Whether user interaction is allowed during animation.
      /// Default is enabled to preserve a system-like experience.
      public var isUserInteractionEnabledDuringAnimation: Bool

      public init(
        allowDismissingDuringReposition: Bool = true,
        isUserInteractionEnabledDuringAnimation: Bool = true
      ) {
        self.allowDismissingDuringReposition = allowDismissingDuringReposition
        self.isUserInteractionEnabledDuringAnimation = isUserInteractionEnabledDuringAnimation
      }

      public nonisolated(unsafe) static let `default` = Interaction()
    }

    // MARK: Animation
    /// Phase-based animation parameters for show and dismiss. Respects Reduce Motion.
    public struct Animation {
      public struct Phase {
        public var duration: TimeInterval
        public var delay: TimeInterval
        public var alphaFrom: CGFloat
        public var alphaTo: CGFloat

        /// Translation (transform only; does not change height).
        public var translation: CGVector
        /// Scale (transform only; does not change height).
        public var scale: CGFloat

        /// Whether to use spring animations (advanced effect; Reduce Motion downgrades it).
        public var useSpring: Bool

        public init(
          duration: TimeInterval,
          delay: TimeInterval = 0,
          alphaFrom: CGFloat = 0,
          alphaTo: CGFloat = 1,
          translation: CGVector = .init(dx: 0, dy: 12),
          scale: CGFloat = 1.0,
          useSpring: Bool = false
        ) {
          self.duration = duration
          self.delay = delay
          self.alphaFrom = alphaFrom
          self.alphaTo = alphaTo
          self.translation = translation
          self.scale = scale
          self.useSpring = useSpring
        }
      }

      public enum ReduceMotionBehavior {
        /// Remove transform entirely and use a very short alpha-only transition.
        case immediateNoTransform
        /// Shorten the duration while trying to keep alpha transition.
        case shortDuration
      }

      public var show: Phase
      public var dismiss: Phase
      public var reduceMotionBehavior: ReduceMotionBehavior

      public init(
        show: Phase = .init(duration: 0.25, delay: 0, alphaFrom: 0, alphaTo: 1, translation: .init(dx: 0, dy: 10), scale: 1.0, useSpring: false),
        dismiss: Phase = .init(duration: 0.18, delay: 0, alphaFrom: 1, alphaTo: 0, translation: .init(dx: 0, dy: 10), scale: 1.0, useSpring: false),
        reduceMotionBehavior: ReduceMotionBehavior = .immediateNoTransform
      ) {
        self.show = show
        self.dismiss = dismiss
        self.reduceMotionBehavior = reduceMotionBehavior
      }

      public nonisolated(unsafe) static let `default` = Animation()
    }

    // MARK: Reposition
    /// Whether to automatically recompute the frame when the device rotates or `traitCollection` changes.
    public struct Reposition {
      public var enabled: Bool
      public var animationDuration: TimeInterval
      public var listenOrientationChanges: Bool
      public var listenTraitCollectionChanges: Bool

      public init(
        enabled: Bool = true,
        animationDuration: TimeInterval = 0.0,
        listenOrientationChanges: Bool = true,
        listenTraitCollectionChanges: Bool = true
      ) {
        self.enabled = enabled
        self.animationDuration = animationDuration
        self.listenOrientationChanges = listenOrientationChanges
        self.listenTraitCollectionChanges = listenTraitCollectionChanges
      }

      public nonisolated(unsafe) static let `default` = Reposition()
    }

    // MARK: Top-level configuration
    public var appearance: Appearance
    public var content: Content
    public var layout: Layout
    public var mask: Mask
    public var interaction: Interaction
    public var animation: Animation
    public var reposition: Reposition

    public init(
      appearance: Appearance = .default,
      content: Content = .default,
      layout: Layout = .default,
      mask: Mask = .default,
      interaction: Interaction = .default,
      animation: Animation = .default,
      reposition: Reposition = .default
    ) {
      self.appearance = appearance
      self.content = content
      self.layout = layout
      self.mask = mask
      self.interaction = interaction
      self.animation = animation
      self.reposition = reposition
    }

    public nonisolated(unsafe) static let `default` = Configuration()
  }
}
