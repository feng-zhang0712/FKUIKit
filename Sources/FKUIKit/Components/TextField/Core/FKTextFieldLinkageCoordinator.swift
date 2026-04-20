//
// FKTextFieldLinkageCoordinator.swift
//
// Multi-text-field linkage coordinator (OTP style).
//

import UIKit

/// Coordinates multiple `FKTextField` instances for OTP-like flows.
///
/// This helper provides a reusable, centralized focus policy for multi-field inputs:
/// - when a field completes (fixed length), focus moves to the next field,
/// - when backspace is pressed on an empty field, focus moves to the previous field.
@MainActor
public final class FKTextFieldLinkageCoordinator: NSObject {
  /// Linked text fields in order.
  public private(set) var textFields: [FKTextField]

  /// Creates a linkage coordinator.
  ///
  /// - Parameter textFields: Ordered fields from left to right.
  public init(textFields: [FKTextField]) {
    self.textFields = textFields
    super.init()
    bind()
  }

  /// Rebinds with a new text field list.
  public func updateTextFields(_ textFields: [FKTextField]) {
    self.textFields = textFields
    bind()
  }
}

private extension FKTextFieldLinkageCoordinator {
  /// Binds callbacks and delegates for all linked fields.
  func bind() {
    for (index, field) in textFields.enumerated() {
      // Move forward when the current field reports completion.
      field.onInputCompleted = { [weak self, weak field] _ in
        guard let self, let field else { return }
        self.moveToNextField(after: field, fallbackIndex: index)
      }
      // Forward delegate callbacks to handle backspace navigation.
      field.forwardingDelegate = self
    }
  }

  /// Moves focus to the next field if available, otherwise resigns.
  func moveToNextField(after field: FKTextField, fallbackIndex: Int) {
    let currentIndex = textFields.firstIndex(of: field) ?? fallbackIndex
    let nextIndex = currentIndex + 1
    guard textFields.indices.contains(nextIndex) else {
      field.resignFirstResponder()
      return
    }
    textFields[nextIndex].becomeFirstResponder()
  }
}

extension FKTextFieldLinkageCoordinator: UITextFieldDelegate {
  public func textField(
    _ textField: UITextField,
    shouldChangeCharactersIn range: NSRange,
    replacementString string: String
  ) -> Bool {
    guard let field = textField as? FKTextField else { return true }
    // If user hits backspace on an empty field, move focus back.
    if string.isEmpty, range.length == 1, field.rawText.isEmpty {
      let index = textFields.firstIndex(of: field) ?? 0
      let previous = index - 1
      if textFields.indices.contains(previous) {
        textFields[previous].becomeFirstResponder()
      }
    }
    return true
  }
}

