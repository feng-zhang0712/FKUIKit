//
// FKPresentation+Configuration.swift
//
// 锚点弹出层的外观、布局、遮罩、动画与重定位等声明式配置。
//

import UIKit

public extension FKPresentation {
  /// 顶层聚合；各子 struct 均有 `.default`。
  struct Configuration {
    // MARK: Appearance

    /// 控制 Presentation 内容壳层阴影在轮廓上的分布（通过 `CALayer.shadowPath` 近似；非四周模式时为沿边的窄条路径）。
    public enum ShadowEdgeStyle: Equatable, Sendable {
      /// 随垂直锚点：在源视图下方弹出时阴影集中在底边，在上方弹出时集中在顶边。
      case followsPresentation
      /// 沿整块圆角矩形外轮廓四周（常规卡片阴影）。
      case omnidirectional
      /// 仅在指定边上集中阴影；可组合多条边，例如 `.top`、`.top.union(.bottom)`。
      case edges(UIRectEdge)
    }

    public struct Shadow: Equatable {
      public var color: UIColor
      public var opacity: Float
      public var offset: CGSize
      public var radius: CGFloat
      /// 阴影在边缘上的分布方式；`omnidirectional` 与未配置 `shadowPath` 时的整块阴影一致。
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

    /// 浮层容器（chrome）背景、圆角、边框与阴影。
    public struct Appearance {
      public var backgroundColor: UIColor
      public var alpha: CGFloat

      public var cornerRadius: CGFloat
      public var cornerCurve: CALayerCornerCurve
      public var maskedCorners: CACornerMask

      public var borderWidth: CGFloat
      public var borderColor: UIColor

      /// 阴影配置；`nil` 表示不显示阴影。
      public var shadow: Shadow?

      /// 是否裁剪子视图；`nil` 时采用策略：
      /// - 有阴影：不裁剪
      /// - 无阴影：裁剪
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
    /// 用户内容相对 chrome 的内边距与高度相关约束。
    public struct Content {
      /// 内容的内边距（用户内容相对 presentation 内容区域的 padding）。
      public var containerInsets: NSDirectionalEdgeInsets

      /// 当用户传入 UIViewController，但其 view 没有背景色时，这里给一个兜底背景。
      public var fallbackBackgroundColor: UIColor

      /// 若想显式指定高度（优先级高于 AutoLayout 计算）。
      /// `nil` 表示由 intrinsic / preferredSize / fitting 计算。
      public var preferredHeight: CGFloat?

      /// 高度的上限（用于适配可视区域；`nil` 表示不额外限制，使用可用区域计算兜底）。
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
    /// 相对 `sourceView` / `sourceRect` 的摆放、宽度与垂直翻转策略。
    public struct Layout {
      public enum HorizontalAlignment {
        case leading
        case center
        case trailing
      }

      public enum WidthMode {
        /// 与 `sourceView` 宽度一致。
        case matchSourceWidth
        /// 固定宽度（point）。
        case custom(CGFloat)
        /// 在可用宽度内按内容 fitting 并 clamp。
        case fitWithinContainer
        /// 在 safe area 与 inset 内尽量铺满可用宽度。
        case fullWidth
      }

      /// sourceView 下方到 presentation 顶部的间距。
      public var verticalSpacing: CGFloat

      /// presentation 在水平方向相对 sourceView 的对齐方式。
      public var horizontalAlignment: HorizontalAlignment

      public var widthMode: WidthMode

      public var widthMin: CGFloat?
      public var widthMax: CGFloat?

      public var maxHeight: CGFloat?
      public var clampToSafeArea: Bool

      /// `true` 时优先在锚点下方展示。
      public var preferBelowSource: Bool
      /// `true` 时当下方空间不足可翻转到锚点上方。
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
    /// 全屏或半屏遮罩及其点击关闭行为。
    public struct Mask {
      public var enabled: Bool
      public var backgroundColor: UIColor
      public var alpha: CGFloat

      public var tapToDismissEnabled: Bool
      public var passthroughViews: [UIView]

      /// 视觉覆盖策略：仅覆盖 sourceView 下方区域。
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

    /// 展示/消失过程中与用户交互、旋转重定位相关的策略。
    public struct Interaction {
      /// 重定位（例如旋转）过程中是否允许通过遮罩 dismiss。
      public var allowDismissingDuringReposition: Bool
      /// 动画时是否允许用户交互（默认允许以保持系统体验；但如需更严格可以关）。
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
    /// 展示与消失的分段动画参数；遵守 Reduce Motion。
    public struct Animation {
      public struct Phase {
        public var duration: TimeInterval
        public var delay: TimeInterval
        public var alphaFrom: CGFloat
        public var alphaTo: CGFloat

        /// 位移（仅 transform；不改高度）
        public var translation: CGVector
        /// 缩放（仅 transform；不改高度）
        public var scale: CGFloat

        /// 是否使用 spring 动画（高阶效果；Reduce Motion 会降级）。
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
        /// 直接去掉 transform，使用极短时长 alpha。
        case immediateNoTransform
        /// 缩短时长并尽量保留 alpha。
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
    /// 屏幕旋转、`traitCollection` 变化时是否自动重算 frame。
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
