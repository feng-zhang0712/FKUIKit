//
// FKBar+Item.swift
//
// 横向条中的单个条目：展示模式（`FKButton` / 系统按钮 / 自定义视图）、选中行为与布局声明。
//

import UIKit
import FKButton

public extension FKBar {
  struct Item: Identifiable, Equatable, Hashable {
    /// 点击回调：bar 触发后把“被点击的条目值”（包含 `id`/`mode`/当前 `isSelected` 等）回传。
    public typealias ActionHandler = (FKBar.Item) -> Void

    /// 选中后滚动条使目标条目对齐的方式；具体滚动由 `FKBar` 与 `Configuration.selectionScroll` 实现。
    public enum ScrollAlignment {
      case leading
      case center
      case trailing
    }

    /// 再次点击已选中条目时的选中态变化策略。
    public enum SelectionBehavior {
      /// 已选中则取消选中，否则选中。
      case toggle
      /// 始终维持选中，不因再次点击取消。
      case alwaysSelect
      /// 不改变 `isSelected`，仍触发 `actionHandler` / delegate。
      case none
    }

    /// `mode == .customView` 时常用；也可由 `FKBarDelegate` 自行绘制而忽略。
    public struct CustomViewWrapperStyle {
      public var cornerRadius: CGFloat?
      public var cornerCurve: CALayerCornerCurve?
      public var clipsToBounds: Bool?

      public var normalAlpha: CGFloat
      public var selectedAlpha: CGFloat

      public var normalBackgroundColor: UIColor?
      public var selectedBackgroundColor: UIColor?

      public init(
        cornerRadius: CGFloat? = nil,
        cornerCurve: CALayerCornerCurve? = nil,
        clipsToBounds: Bool? = nil,
        normalAlpha: CGFloat = 1.0,
        selectedAlpha: CGFloat = 1.0,
        normalBackgroundColor: UIColor? = nil,
        selectedBackgroundColor: UIColor? = nil
      ) {
        self.cornerRadius = cornerRadius
        self.cornerCurve = cornerCurve
        self.clipsToBounds = clipsToBounds
        self.normalAlpha = normalAlpha
        self.selectedAlpha = selectedAlpha
        self.normalBackgroundColor = normalBackgroundColor
        self.selectedBackgroundColor = selectedBackgroundColor
      }
    }

    /// 条目外层尺寸、边距与命中区等的声明式配置，由 `FKBar` 映射到内部 wrapper 约束。
    public struct Layout {
      /// 固定宽度；`nil` 表示使用内容的 intrinsicContentSize / 系统布局计算。
      public var fixedWidth: CGFloat?
      /// 固定高度；`nil` 表示使用内容的 intrinsicContentSize / 系统布局计算。
      public var fixedHeight: CGFloat?

      public var minWidth: CGFloat?
      public var maxWidth: CGFloat?
      public var minHeight: CGFloat?
      public var maxHeight: CGFloat?

      /// 条目外层的补偿/边距（由 bar 映射到 wrapper 约束或额外容器）。
      public var wrapperInsets: NSDirectionalEdgeInsets

      /// 扩大点击命中区域（由 bar 映射到 wrapper 事件/手势/命中测试）。
      public var hitTestInsets: UIEdgeInsets

      /// 条目滚动对齐的默认配置。
      public var scrollAlignment: ScrollAlignment

      public init(
        fixedWidth: CGFloat? = nil,
        fixedHeight: CGFloat? = nil,
        minWidth: CGFloat? = nil,
        maxWidth: CGFloat? = nil,
        minHeight: CGFloat? = nil,
        maxHeight: CGFloat? = nil,
        wrapperInsets: NSDirectionalEdgeInsets = .zero,
        hitTestInsets: UIEdgeInsets = .zero,
        scrollAlignment: ScrollAlignment = .center
      ) {
        self.fixedWidth = fixedWidth
        self.fixedHeight = fixedHeight
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.wrapperInsets = wrapperInsets
        self.hitTestInsets = hitTestInsets
        self.scrollAlignment = scrollAlignment
      }
    }

    /// 基于 `FKButton` 的条目：`reloadItems` 时由 `FKBar` 将字典中的状态配置应用到新建的按钮上。
    public struct FKButtonSpec {
      public var content: FKButton.Content
      public var axis: FKButton.Axis

      public typealias StateKey = UIControl.State.RawValue

      public var appearanceByState: [StateKey: FKButton.Appearance]
      public var titleByState: [StateKey: FKButton.Text]
      public var subtitleByState: [StateKey: FKButton.Text]
      public var customContentByState: [StateKey: FKButton.CustomContent]

      /// 按 `ImageSlot` 分槽存储各状态下的 `Image`。
      public var imageBySlotAndState: [FKButton.ImageSlot: [StateKey: FKButton.Image]]

      public init(
        content: FKButton.Content = .default,
        axis: FKButton.Axis = .horizontal,
        appearanceByState: [StateKey: FKButton.Appearance] = [:],
        titleByState: [StateKey: FKButton.Text] = [:],
        subtitleByState: [StateKey: FKButton.Text] = [:],
        customContentByState: [StateKey: FKButton.CustomContent] = [:],
        imageBySlotAndState: [FKButton.ImageSlot: [StateKey: FKButton.Image]] = [:]
      ) {
        self.content = content
        self.axis = axis
        self.appearanceByState = appearanceByState
        self.titleByState = titleByState
        self.subtitleByState = subtitleByState
        self.customContentByState = customContentByState
        self.imageBySlotAndState = imageBySlotAndState
      }

      /// 写入外观配置（支持 `.normal / .selected / .highlighted / .disabled` 等）。
      public mutating func setAppearance(_ appearance: FKButton.Appearance, for state: UIControl.State) {
        appearanceByState[state.rawValue] = appearance
      }

      public mutating func setTitle(_ title: FKButton.Text?, for state: UIControl.State) {
        guard let title else {
          titleByState.removeValue(forKey: state.rawValue)
          return
        }
        titleByState[state.rawValue] = title
      }

      public mutating func setSubtitle(_ subtitle: FKButton.Text?, for state: UIControl.State) {
        guard let subtitle else {
          subtitleByState.removeValue(forKey: state.rawValue)
          return
        }
        subtitleByState[state.rawValue] = subtitle
      }

      public mutating func setCustomContent(_ content: FKButton.CustomContent?, for state: UIControl.State) {
        guard let content else {
          customContentByState.removeValue(forKey: state.rawValue)
          return
        }
        customContentByState[state.rawValue] = content
      }

      public mutating func setImage(
        _ image: FKButton.Image?,
        for state: UIControl.State,
        slot: FKButton.ImageSlot
      ) {
        var map = imageBySlotAndState[slot] ?? [:]
        guard let image else {
          map.removeValue(forKey: state.rawValue)
          imageBySlotAndState[slot] = map
          return
        }
        map[state.rawValue] = image
        imageBySlotAndState[slot] = map
      }

      /// 将当前 spec 写入已有 `FKButton`（供外部或测试复用；常规路径由 `FKBar` 在创建条目时调用）。
      @MainActor
      public func apply(to button: FKButton) {
        button.content = content
        button.axis = axis

        appearanceByState.forEach { key, appearance in
          button.setAppearance(appearance, for: UIControl.State(rawValue: key))
        }
        titleByState.forEach { key, title in
          button.setTitle(title, for: UIControl.State(rawValue: key))
        }
        subtitleByState.forEach { key, subtitle in
          button.setSubtitle(subtitle, for: UIControl.State(rawValue: key))
        }
        customContentByState.forEach { key, content in
          button.setCustomContent(content, for: UIControl.State(rawValue: key))
        }
        for (slot, byState) in imageBySlotAndState {
          for (key, image) in byState {
            let state = UIControl.State(rawValue: key)
            switch slot {
            case .center:
              button.setImage(image, for: state)
            case .leading:
              button.setLeadingImage(image, for: state)
            case .trailing:
              button.setTrailingImage(image, for: state)
            }
          }
        }
      }
    }

    /// 条目的视图实现方式。
    public enum Mode {
      case fkButton(FKButtonSpec)
      /// 使用 `UIButton.Configuration` 构建系统按钮。
      case button(UIButton.Configuration)
      /// 完全自定义视图；`FKBar` 用 wrapper 包装并处理选中/点击。
      case customView(UIView)
    }

    public var id: String
    public var mode: Mode

    public var isSelected: Bool
    public var isEnabled: Bool

    public var selectionBehavior: SelectionBehavior

    public var actionHandler: ActionHandler?

    /// 预留：多组互斥或分组选中策略等扩展场景。
    public var selectionGroupID: String?

    public var customViewWrapperStyle: CustomViewWrapperStyle?

    public var layout: Layout

    /// 写入对应 wrapper / 按钮的无障碍属性。
    public var accessibilityLabel: String?
    public var accessibilityHint: String?
    public var accessibilityIdentifier: String?

    public init(
      id: String = UUID().uuidString,
      mode: Mode,
      isSelected: Bool = false,
      isEnabled: Bool = true,
      selectionBehavior: SelectionBehavior = .toggle,
      actionHandler: ActionHandler? = nil,
      selectionGroupID: String? = nil,
      customViewWrapperStyle: CustomViewWrapperStyle? = nil,
      layout: Layout = .init(),
      accessibilityLabel: String? = nil,
      accessibilityHint: String? = nil,
      accessibilityIdentifier: String? = nil
    ) {
      self.id = id
      self.mode = mode
      self.isSelected = isSelected
      self.isEnabled = isEnabled
      self.selectionBehavior = selectionBehavior
      self.actionHandler = actionHandler
      self.selectionGroupID = selectionGroupID
      self.customViewWrapperStyle = customViewWrapperStyle
      self.layout = layout
      self.accessibilityLabel = accessibilityLabel
      self.accessibilityHint = accessibilityHint
      self.accessibilityIdentifier = accessibilityIdentifier
    }

    public static func == (lhs: Item, rhs: Item) -> Bool {
      lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(id)
    }
  }
}
