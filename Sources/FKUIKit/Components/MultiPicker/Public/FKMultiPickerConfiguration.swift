//
// FKMultiPickerConfiguration.swift
//

import Foundation
import UIKit

/// Per-instance layout and styling for `FKMultiPicker`.
public struct FKMultiPickerConfiguration: Hashable {
  /// Number of visible linked columns (`UIPickerView` components).
  public var numberOfColumns: Int
  public var presentationStyle: FKMultiPickerPresentationStyle
  /// Wheel area height (toolbar is separate).
  public var pickerHeight: CGFloat
  public var toolbarHeight: CGFloat
  public var animationDuration: TimeInterval
  public var dismissOnMaskTap: Bool
  public var toolbarStyle: FKMultiPickerToolbarStyle
  public var rowStyle: FKMultiPickerRowStyle
  public var containerStyle: FKMultiPickerContainerStyle
  /// Per-column keys matched against node `id`, then `title`, when opening or after `reloadData()`.
  public var defaultSelectionKeys: [String]

  public init(
    numberOfColumns: Int = 4,
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
    self.numberOfColumns = max(1, numberOfColumns)
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
