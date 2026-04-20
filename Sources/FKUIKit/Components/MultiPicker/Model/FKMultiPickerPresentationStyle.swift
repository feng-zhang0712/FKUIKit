//
// FKMultiPickerPresentationStyle.swift
//
// Presentation styles for FKMultiPicker.
//

import CoreGraphics

/// Presentation mode for bottom sheet picker.
public enum FKMultiPickerPresentationStyle: Hashable {
  /// Uses fixed height as half sheet style.
  ///
  /// Actual height is calculated from `toolbarHeight + pickerHeight`.
  case halfScreen
  /// Uses full available height and safe area.
  ///
  /// The container stretches to the full host view height.
  case fullScreen
  /// Uses custom fixed height.
  ///
  /// - Parameter height: Custom sheet height in points.
  case custom(height: CGFloat)
}
