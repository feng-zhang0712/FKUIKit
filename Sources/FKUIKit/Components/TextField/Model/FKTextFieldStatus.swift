import Foundation

/// Represents the visual and semantic state of a text input.
///
/// This state is intentionally explicit so business layers can force the component into
/// a known mode (for example, server-side validation failure) without depending on
/// UIKit focus timing.
public enum FKTextFieldStatus: Sendable, Equatable {
  /// Idle state without focus and without committed content.
  case normal
  /// Editing state while the control is first responder.
  case focused
  /// Non-empty state after user input is accepted.
  case filled
  /// Invalid state with an error message.
  case error
  /// Explicit success state, commonly used after async validation succeeds.
  case success
  /// Disabled state (`isEnabled == false`).
  case disabled
  /// Read-only state that allows selection/copy but blocks edits.
  case readOnly
}

/// Describes when validation should be performed.
public enum FKTextFieldValidationTrigger: Sendable, Equatable {
  /// Validates while typing.
  case onChange
  /// Validates when editing ends.
  case onBlur
  /// Validates only when submit/return is triggered.
  case onSubmit
}

/// High-level message slots used by advanced text field UI.
///
/// Keeping message channels separate allows products to display helper guidance while still
/// surfacing independent success or error feedback without message collisions.
public struct FKTextFieldMessages: Sendable, Equatable {
  /// Optional helper text shown when no error/success message is active.
  public var helper: String?
  /// Optional success text shown when state is `.success`.
  public var success: String?
  /// Optional error text shown when state is `.error`.
  public var error: String?

  /// Creates message channels.
  public init(
    helper: String? = nil,
    success: String? = nil,
    error: String? = nil
  ) {
    self.helper = helper
    self.success = success
    self.error = error
  }
}

