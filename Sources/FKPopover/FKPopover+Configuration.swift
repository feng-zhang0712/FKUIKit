//
// FKPopover+Configuration.swift
//
// `FKPopover` 顶层配置：`FKBar`、浮层 `FKPresentation`、交互策略与挂载容器。
// 类型与属性说明见 `FKPopover.swift`；条与浮层的细项字段仍以 `FKBar.Configuration`、`FKPresentation.Configuration` 为准。
//

import UIKit
import FKBar
import FKPresentation

// MARK: - FKPopover.Configuration（顶层）

public extension FKPopover {
  /// 组合件的全局配置：条外观与滚动、`FKPresentation` 的浮层参数、以及 Bar↔浮层 的衔接行为。
  struct Configuration {
    // MARK: 子配置（与 `FKBar.Configuration`、`FKPresentation.Configuration` 对齐）

    /// 横向条目条：间距、滚动、圆角与阴影等。
    public var bar: FKBar.Configuration

    /// 自条上锚点向下（或翻转后向上）弹出的浮层：遮罩、动画、内容边距、宽度策略等。
    public var presentation: FKPresentation.Configuration

    /// Bar 选中/取消与浮层展示/消失的交互策略。
    public var behavior: Behavior

    /// 浮层挂载到哪个父视图；默认在展示时取 `FKPopover.superview`。
    public var presentationHost: PresentationHost

    public init(
      bar: FKBar.Configuration = .default,
      presentation: FKPresentation.Configuration = .default,
      behavior: Behavior = .init(),
      presentationHost: PresentationHost = .automatic
    ) {
      self.bar = bar
      self.presentation = presentation
      self.behavior = behavior
      self.presentationHost = presentationHost
    }

    public nonisolated(unsafe) static let `default` = Configuration()
  }
}

// MARK: - 浮层挂载策略

public extension FKPopover.Configuration {
  /// 决定 `FKPresentation.show(..., in:)` 的容器视图。
  enum PresentationHost {
    /// 展示时使用 `popover.superview`；若为 `nil` 则退回 `popover.window`。
    case automatic
    /// 强制使用 `superview`（为 `nil` 时不展示并可在调试中发现布局问题）。
    case superview
    /// 使用 `popover.window`，适合尚未加入窗口层级时的临时场景。
    case window
    /// 指定任意容器（例如某全屏 `UIView`）。
    case explicit(WeakUIViewBox)

    public static func explicit(_ view: UIView) -> PresentationHost {
      .explicit(WeakUIViewBox(view))
    }
  }
}

/// 弱引用包装，供 `PresentationHost.explicit` 持有 `UIView`。
public final class WeakUIViewBox {
  public weak var view: UIView?
  public init(_ view: UIView) {
    self.view = view
  }
}

// MARK: - 行为策略

public extension FKPopover.Configuration {
  /// Bar 与浮层之间的默认衔接逻辑；可通过 `FKPopoverDelegate` 再收紧或扩展。
  struct Behavior {
    /// 当某条目变为选中时，是否尝试展示浮层（仍受内容与 `shouldPresent` 影响）。
    public var presentsOnSelection: Bool

    /// 当所有条目都未选中时，是否关闭浮层（例如 `SelectionBehavior.toggle` 再次点选取消选中）。
    public var dismissesWhenSelectionCleared: Bool

    /// 从条目 A 改选到 B 时，是否在展示 B 的内容前先关掉当前浮层（无动画更易衔接）。
    public var dismissBeforeChangingSelection: Bool

    /// 若当前已为同一索引展示浮层，再次收到 `didSelect`（如 `alwaysSelect` 重复点击）时是否忽略。
    public var ignoresRepeatedSelectWhilePresented: Bool

    public init(
      presentsOnSelection: Bool = true,
      dismissesWhenSelectionCleared: Bool = true,
      dismissBeforeChangingSelection: Bool = true,
      ignoresRepeatedSelectWhilePresented: Bool = true
    ) {
      self.presentsOnSelection = presentsOnSelection
      self.dismissesWhenSelectionCleared = dismissesWhenSelectionCleared
      self.dismissBeforeChangingSelection = dismissBeforeChangingSelection
      self.ignoresRepeatedSelectWhilePresented = ignoresRepeatedSelectWhilePresented
    }
  }
}

// MARK: - 浮层关闭原因（Delegate）

public extension FKPopover {
  /// `popover(_:didDismissPresentation:)` 中说明关闭来源。
  enum PresentationDismissReason: Equatable, Sendable {
    case maskTap
    case programmatic
    /// 选中态清空（例如 toggle 取消）。
    case selectionCleared
    /// 改选其他条目前先关闭。
    case selectionChanged
  }
}
