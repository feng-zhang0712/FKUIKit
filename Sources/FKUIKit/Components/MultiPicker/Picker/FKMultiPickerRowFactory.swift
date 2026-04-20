//
// FKMultiPickerRowFactory.swift
//
// Picker row rendering helper.
//

import UIKit

@MainActor
enum FKMultiPickerRowFactory {
  /// Creates reusable label for picker row display.
  ///
  /// - Parameter view: Existing reusable row view from `UIPickerView`.
  /// - Returns: Configured row label instance.
  static func makeLabel(reusing view: UIView?) -> UILabel {
    if let label = view as? UILabel {
      return label
    }
    let label = UILabel()
    label.textAlignment = .center
    label.numberOfLines = 1
    label.adjustsFontSizeToFitWidth = true
    label.minimumScaleFactor = 0.75
    return label
  }
}
