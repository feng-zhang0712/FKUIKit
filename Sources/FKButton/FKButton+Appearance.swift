//
//  FKButton+Appearance.swift
//
//  `FKButton` 按 `UIControl.State` 应用的外观模型：圆角、阴影、边框、背景与内容边距等。
//

import UIKit

public extension FKButton {
  /// 某一状态下按钮容器（layer）与内容边距的外观。
  struct Appearance {
    /// 圆角策略（无圆角/固定圆角/胶囊）。
    public let corner: Corner
    /// 圆角曲线风格（`.continuous` 更接近系统卡片观感）。
    public let cornerCurve: CALayerCornerCurve
    /// 指定生效的圆角角位；默认全部角。
    public let maskedCorners: CACornerMask

    /// 阴影配置；为 `nil` 表示不显示阴影。
    public let shadow: Shadow?
    
    /// 边框宽度。
    public let borderWidth: CGFloat
    /// 边框颜色。
    public let borderColor: UIColor
    
    /// 背景色。
    public let backgroundColor: UIColor
    /// 整体透明度（0...1）。
    public let alpha: CGFloat
    
    /// 内容内边距（用于 title/image 所在 stack）。
    public let contentInsets: NSDirectionalEdgeInsets
    /// 是否裁剪子视图。`nil` 时自动策略：有阴影则不裁剪，无阴影则裁剪。
    public let clipsToBounds: Bool?

    public init(
      corner: Corner = .none,
      cornerCurve: CALayerCornerCurve = .continuous,
      maskedCorners: CACornerMask = [
        .layerMinXMinYCorner,
        .layerMaxXMinYCorner,
        .layerMinXMaxYCorner,
        .layerMaxXMaxYCorner,
      ],
      shadow: Shadow? = nil,
      borderWidth: CGFloat = 0,
      borderColor: UIColor = .clear,
      backgroundColor: UIColor = .clear,
      alpha: CGFloat = 1.0,
      contentInsets: NSDirectionalEdgeInsets = .init(top: 7, leading: 12, bottom: 7, trailing: 12),
      clipsToBounds: Bool? = nil
    ) {
      self.corner = corner
      self.cornerCurve = cornerCurve
      self.maskedCorners = maskedCorners
      self.shadow = shadow
      self.borderWidth = borderWidth
      self.borderColor = borderColor
      self.backgroundColor = backgroundColor
      self.alpha = alpha
      self.contentInsets = contentInsets
      self.clipsToBounds = clipsToBounds
    }
    
    public nonisolated(unsafe) static let `default` = Appearance()
  }
  
  /// 与 `Appearance` 配套的 layer 阴影参数。
  struct Shadow: Equatable, Sendable {
    public let color: UIColor
    public let opacity: Float
    public let offset: CGSize
    public let radius: CGFloat
    
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

  /// 圆角策略，映射到 `FKButton.layer.cornerRadius` / `maskedCorners`。
  ///
  /// - `none`：不显示圆角。
  /// - `fixed(CGFloat)`：固定圆角半径（point）。
  /// - `capsule`：胶囊圆角：根据当前 `bounds` 计算为 `min(width, height) / 2`。
  enum Corner: Equatable, Sendable {
    case none
    case fixed(CGFloat)
    case capsule
  }
}
