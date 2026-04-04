//
// FKBar+Configuration.swift
//
// `FKBar` 的声明式配置（间距、滚动、外观等），通过关联对象挂在实例上。
//

import UIKit

import ObjectiveC.runtime

private enum FKBarConfigurationAssociatedKeys {
  nonisolated(unsafe) static var configuration: UInt8 = 0
}

public extension FKBar {
  /// 横向滚动条与内部 `UIStackView` 的布局与视觉参数。
  struct Configuration: Sendable {
    /// 选中条目后自动滚动时的对齐方式。
    public enum SelectionScrollAlignment: Sendable {
      case leading
      case center
      case trailing
    }

    /// 选中触发滚动时的动画时长等。
    public struct ScrollAnimation: Sendable {
      public var duration: TimeInterval

      public init(duration: TimeInterval = 0.25) {
        self.duration = duration
      }
    }

    /// Bar 容器 layer 的阴影；与 `Appearance.shadow` 一致语义。
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

    /// Bar 根视图背景、圆角、边框与阴影。
    public struct Appearance: Sendable {
      public var backgroundColor: UIColor
      public var alpha: CGFloat

      public var cornerRadius: CGFloat
      public var cornerCurve: CALayerCornerCurve
      public var maskedCorners: CACornerMask

      public var borderWidth: CGFloat
      public var borderColor: UIColor

      /// 阴影配置；`nil` 表示不显示阴影。
      public var shadow: Shadow?

      /// 是否裁剪子视图；`nil` 时会自动策略：
      /// - 存在阴影：不裁剪
      /// - 不存在阴影：裁剪
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
      /// 选中条目时是否自动滚动到对应位置。
      public var isEnabled: Bool

      /// 条目滚动对齐策略；条目自身如果也带有对齐字段，可在 `FKBar` 内部实现“条目优先”逻辑。
      public var alignment: SelectionScrollAlignment

      /// 当需要滚动时的动画参数。
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

    /// 相邻条目之间的间距（映射到内部 `UIStackView.spacing`）。
    public var itemSpacing: CGFloat

    /// 条目整体内容的方向性 inset（会映射到内部 `UIScrollView.contentInset` 或其它布局容器）。
    public var contentInsets: NSDirectionalEdgeInsets

    /// 是否允许在水平方向回弹（适配 iOS 系统滚动体验）。
    public var alwaysBounceHorizontal: Bool

    /// 是否显示水平滚动指示器。
    public var showsHorizontalScrollIndicator: Bool

    /// 是否允许滚动（禁用后 bar 变成静态布局）。
    public var isScrollEnabled: Bool

    /// 当滚动被禁用时，条目是否仍需要响应点击（通常需要）。
    public var enablesSelectionWhileScrollingDisabled: Bool

    /// bar 外观配置（圆角/边框/阴影等）。
    public var appearance: Appearance

    /// 选中后滚动策略。
    public var selectionScroll: SelectionScroll

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
      self.stackViewAlignment = stackViewAlignment
      self.stackViewDistribution = stackViewDistribution
    }

    public static let `default` = Configuration()
  }

  /// 通过关联对象持久化；赋值后会触发 `applyBarConfiguration`。
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

  /// 将 `configuration` 应用到 bar 根视图及子树中的 `UIScrollView` / `UIStackView`（通过遍历查找，便于扩展文件复用）。
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
        // `shadowPath` 随布局变化；外部布局结束可再次调用本方法刷新。
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

      // NSDirectionalEdgeInsets -> UIEdgeInsets (按当前语义方向转换)
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
