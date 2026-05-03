//
// FKMultiPickerRowFactory.swift
//

import UIKit

@MainActor
enum FKMultiPickerRowFactory {
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
