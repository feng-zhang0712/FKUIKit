//
//  FKButton+Content.swift
//
//  `FKButton` 主内容形态（纯文、纯图、图文、自定义视图）及图文相对位置。
//

public extension FKButton {
  /// 主内容布局策略；与 `axis`、各 `set*` 状态 API 共同决定最终界面。
  struct Content {

    /// 控制 `FKButton` 主内容的类型。
    ///
    /// - `textOnly`：只显示标题（subtitle 也是标题区域的一部分）。
    /// - `imageOnly`：只显示图片，不显示标题/subtitle。
    /// - `textAndImage`：标题与图片同时显示；图片与标题的相对位置由 `ImagePlacement` 决定，并受 `FKButton.axis` 影响。
    /// - `custom`：主内容完全由 `CustomContent.view` 提供（不使用内置标题/图片槽位）。
    public enum Kind: Equatable {
      case textOnly
      case imageOnly
      case textAndImage(ImagePlacement)
      case custom
    }
    
    /// 仅用于 `.textAndImage` 的图片相对位置语义。
    ///
    /// - `leading`：图片位于标题的“前置”一侧。
    /// - `trailing`：图片位于标题的“后置”一侧。
    /// - `bothSides`：同时在前置与后置放置图片（左右两侧，或上下两端，取决于 `axis`）。
    public enum ImagePlacement {
      case leading
      case trailing
      case bothSides
    }
    
    public let kind: Kind

    public init(kind: Kind = .textOnly) {
      self.kind = kind
    }
    
    public nonisolated(unsafe) static let `default` = Content()
  }
}
