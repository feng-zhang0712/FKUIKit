//
// FKTextField+Convenience.swift
//
// Convenience APIs for one-line setup.
//

import UIKit

public extension FKTextField {
  /// Creates a one-line configured text field.
  ///
  /// - Parameters:
  ///   - formatType: Built-in format type.
  ///   - placeholder: Optional placeholder text.
  ///   - maxLength: Optional max raw text length.
  /// - Returns: Configured `FKTextField`.
  static func make(
    formatType: FKTextFieldFormatType,
    placeholder: String? = nil,
    maxLength: Int? = nil
  ) -> FKTextField {
    let rule = FKTextFieldInputRule(formatType: formatType, maxLength: maxLength)
    let configuration = FKTextFieldConfiguration(
      inputRule: rule,
      style: FKTextFieldManager.shared.defaultStyle,
      placeholder: placeholder
    )
    return FKTextField(configuration: configuration)
  }
}

