import Foundation

/// Shared abstraction for single-line and multi-line text input controls.
///
/// This protocol enables form engines to work with `FKTextField` and `FKCountTextView`
/// using a unified API without coupling business logic to specific UIKit classes.
@MainActor
public protocol FKTextInputComponent: AnyObject {
  /// Canonical raw text value.
  var fk_rawText: String { get }
  /// Applies text content.
  func fk_setText(_ text: String)
  /// Clears content.
  func fk_clear()
}

