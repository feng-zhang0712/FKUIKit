//
// FKBar+Item.swift
//
// A single item inside a horizontal bar: mode (`FKButton` / `UIButton` / custom view),
// selection behavior, and layout declarations.
//

import UIKit

public extension FKBar {
  struct Item: Identifiable, Equatable, Hashable {
    /// Tap callback: returns the tapped item value (including `id` / `mode` / current `isSelected`, etc.).
    public typealias ActionHandler = (FKBar.Item) -> Void

    /// Scrolling alignment when an item is selected.
    /// Actual scrolling is implemented by `FKBar` and `Configuration.selectionScroll`.
    public enum ScrollAlignment: Equatable, Sendable {
      case leading
      case center
      case trailing
    }

    /// Selection-state change strategy when tapping an already-selected item.
    public enum SelectionBehavior: Equatable, Sendable {
      /// Toggle selected state.
      case toggle
      /// Always keep selected.
      case alwaysSelect
      /// Do not change `isSelected`; still triggers `actionHandler` / delegate.
      case none
    }

    /// Commonly used for `mode == .customView`; may be ignored if `FKBarDelegate` draws custom appearance.
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
        self.cornerRadius = cornerRadius.map { max(0, $0) }
        self.cornerCurve = cornerCurve
        self.clipsToBounds = clipsToBounds
        self.normalAlpha = max(0, min(1, normalAlpha))
        self.selectedAlpha = max(0, min(1, selectedAlpha))
        self.normalBackgroundColor = normalBackgroundColor
        self.selectedBackgroundColor = selectedBackgroundColor
      }
    }

    /// Declarative configuration for item outer size, insets, and hit-test insets, mapped to internal wrapper constraints by `FKBar`.
    public struct Layout {
      /// Fixed width. `nil` uses intrinsicContentSize / system layout calculation.
      public var fixedWidth: CGFloat?
      /// Fixed height. `nil` uses intrinsicContentSize / system layout calculation.
      public var fixedHeight: CGFloat?

      public var minWidth: CGFloat?
      public var maxWidth: CGFloat?
      public var minHeight: CGFloat?
      public var maxHeight: CGFloat?

      /// Outer wrapper insets for the item (mapped by `FKBar` into wrapper constraints or extra containers).
      public var wrapperInsets: NSDirectionalEdgeInsets

      /// Hit-test expansion insets (mapped by `FKBar` into wrapper hit-testing/gestures).
      public var hitTestInsets: UIEdgeInsets

      /// Default scrolling alignment.
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
        self.fixedWidth = fixedWidth.map { max(0, $0) }
        self.fixedHeight = fixedHeight.map { max(0, $0) }
        self.minWidth = minWidth.map { max(0, $0) }
        self.maxWidth = maxWidth.map { max(0, $0) }
        self.minHeight = minHeight.map { max(0, $0) }
        self.maxHeight = maxHeight.map { max(0, $0) }
        self.wrapperInsets = wrapperInsets
        self.hitTestInsets = hitTestInsets
        self.scrollAlignment = scrollAlignment
        normalizeMinMaxDimensions()
      }

      private mutating func normalizeMinMaxDimensions() {
        if let minWidth, let maxWidth, minWidth > maxWidth {
          self.minWidth = maxWidth
          self.maxWidth = minWidth
        }
        if let minHeight, let maxHeight, minHeight > maxHeight {
          self.minHeight = maxHeight
          self.maxHeight = minHeight
        }
      }
    }

    /// An item based on `FKButton`: when `reloadItems` runs, `FKBar` applies per-state appearance/content into newly created buttons.
    public struct FKButtonSpec {
      public var content: FKButton.Content
      public var axis: FKButton.Axis

      public typealias StateKey = UIControl.State.RawValue

      public var appearanceByState: [StateKey: FKButton.Appearance]
      public var titleByState: [StateKey: FKButton.Text]
      public var subtitleByState: [StateKey: FKButton.Text]
      public var customContentByState: [StateKey: FKButton.CustomContent]

    /// Stores images per `ImageSlot` and per state.
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

      /// Writes appearance configuration (supports `.normal / .selected / .highlighted / .disabled`, etc.).
      public mutating func setAppearance(_ appearance: FKButton.Appearance, for state: UIControl.State) {
        appearanceByState[state.rawValue] = appearance
      }

      /// Writes normal/selected/highlighted/disabled appearances in one call.
      public mutating func setAppearances(_ appearances: FKButton.StateAppearances) {
        appearanceByState[UIControl.State.normal.rawValue] = appearances.normal
        appearanceByState[UIControl.State.selected.rawValue] = appearances.selected
        appearanceByState[UIControl.State.highlighted.rawValue] = appearances.highlighted
        appearanceByState[UIControl.State.disabled.rawValue] = appearances.disabled
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
          if map.isEmpty {
            imageBySlotAndState.removeValue(forKey: slot)
          } else {
            imageBySlotAndState[slot] = map
          }
          return
        }
        map[state.rawValue] = image
        imageBySlotAndState[slot] = map
      }

      /// Applies this spec to an existing `FKButton` (for reuse/testing; the normal path is called by `FKBar` when creating items).
      @MainActor
      public func apply(to button: FKButton) {
        button.performBatchUpdates {
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
    }

    /// How this item is rendered.
    public enum Mode {
      case fkButton(FKButtonSpec)
      /// Build a system button using `UIButton.Configuration`.
      case button(UIButton.Configuration)
      /// Fully custom view; `FKBar` wraps it and handles selection/taps.
      case customView(UIView)
    }

    public var id: String
    public var mode: Mode

    public var isSelected: Bool
    public var isEnabled: Bool

    public var selectionBehavior: SelectionBehavior

    public var actionHandler: ActionHandler?

    /// Reserved for extension scenarios (e.g. multiple mutually-exclusive groups).
    public var selectionGroupID: String?

    public var customViewWrapperStyle: CustomViewWrapperStyle?

    public var layout: Layout

    /// Writes accessibility attributes to the underlying wrapper/button.
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
