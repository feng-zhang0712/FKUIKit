//
// FKMultiPickerConfiguration.swift
//
// Configuration model for FKMultiPicker.
//

import Foundation
import UIKit

/// Full configuration for one `FKMultiPicker` instance.
public struct FKMultiPickerConfiguration: Hashable {
  /// Number of visible linked components.
  ///
  /// For common cases use 1...5. This value is technically unbounded for custom scenarios.
  public var componentCount: Int
  /// Bottom sheet presentation style.
  public var presentationStyle: FKMultiPickerPresentationStyle
  /// Picker body height excluding toolbar.
  public var pickerHeight: CGFloat
  /// Toolbar height.
  public var toolbarHeight: CGFloat
  /// Present and dismiss animation duration.
  public var animationDuration: TimeInterval
  /// Whether tapping mask dismisses picker.
  public var dismissOnMaskTap: Bool
  /// Toolbar appearance.
  public var toolbarStyle: FKMultiPickerToolbarStyle
  /// Row appearance.
  public var rowStyle: FKMultiPickerRowStyle
  /// Container appearance.
  public var containerStyle: FKMultiPickerContainerStyle
  /// Default selected identifiers or titles in level order.
  public var defaultSelectionKeys: [String]

  /// Creates a picker configuration.
  ///
  /// - Parameters:
  ///   - componentCount: Number of visible linkage columns.
  ///   - presentationStyle: Bottom sheet presentation mode.
  ///   - pickerHeight: Height of picker content area.
  ///   - toolbarHeight: Height of toolbar area.
  ///   - animationDuration: Present/dismiss animation duration.
  ///   - dismissOnMaskTap: Whether tapping dimming area dismisses the picker.
  ///   - toolbarStyle: Toolbar visual style.
  ///   - rowStyle: Picker row visual style.
  ///   - containerStyle: Sheet container visual style.
  ///   - defaultSelectionKeys: Default selected node keys matched by id/title per level.
  public init(
    componentCount: Int = 4,
    presentationStyle: FKMultiPickerPresentationStyle = .halfScreen,
    pickerHeight: CGFloat = 216,
    toolbarHeight: CGFloat = 52,
    animationDuration: TimeInterval = 0.28,
    dismissOnMaskTap: Bool = true,
    toolbarStyle: FKMultiPickerToolbarStyle = FKMultiPickerToolbarStyle(),
    rowStyle: FKMultiPickerRowStyle = FKMultiPickerRowStyle(),
    containerStyle: FKMultiPickerContainerStyle = FKMultiPickerContainerStyle(),
    defaultSelectionKeys: [String] = []
  ) {
    self.componentCount = max(1, componentCount)
    self.presentationStyle = presentationStyle
    self.pickerHeight = max(160, pickerHeight)
    self.toolbarHeight = max(44, toolbarHeight)
    self.animationDuration = max(0.12, animationDuration)
    self.dismissOnMaskTap = dismissOnMaskTap
    self.toolbarStyle = toolbarStyle
    self.rowStyle = rowStyle
    self.containerStyle = containerStyle
    self.defaultSelectionKeys = defaultSelectionKeys
  }
}
