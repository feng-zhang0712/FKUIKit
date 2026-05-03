//
// FKMultiPickerPresentationStyle.swift
//

import CoreGraphics

/// How the picker sheet is sized relative to its host.
public enum FKMultiPickerPresentationStyle: Hashable {
  /// Height is `toolbarHeight + pickerHeight` (typical bottom sheet).
  case halfScreen
  /// Expands to the full height of the host view.
  case fullScreen
  /// Fixed total sheet height (clamped to a sensible minimum).
  case custom(height: CGFloat)
}
