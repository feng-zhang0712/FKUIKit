//
// FKTextFieldFormatType.swift
//
// Built-in formatting and input-limit types for FKTextField.
//

import Foundation
import UIKit

/// Describes the built-in formatting strategy used by `FKTextField`.
///
/// `FKTextField` uses this value to:
/// - filter and sanitize incoming characters,
/// - format the displayed text (grouping/separators),
/// - pick a reasonable `UIKeyboardType`,
/// - decide when the input is considered “complete” (fixed-length modes).
public enum FKTextFieldFormatType: Sendable, Equatable {
  /// Phone number formatting. Example: `138 1234 5678`.
  ///
  /// The formatter keeps digits only and applies 3-4-4 grouping for display.
  case phoneNumber
  /// Chinese ID card formatting for 15/18 characters.
  ///
  /// The formatter keeps digits and an optional trailing `X` (case-insensitive),
  /// and inserts grouping separators for readability.
  case idCard
  /// Bank card formatting with groups of 4.
  ///
  /// The formatter keeps digits only and groups them by 4 for display.
  case bankCard
  /// Verification code with fixed length and optional alphabet support.
  ///
  /// - Parameters:
  ///   - length: Fixed code length. When reached, completion callbacks may fire.
  ///   - allowsAlphabet: If `true`, allows ASCII letters and digits; otherwise digits only.
  case verificationCode(length: Int, allowsAlphabet: Bool)
  /// Password mode with optional strength validation.
  ///
  /// - Parameters:
  ///   - minLength: Minimum length required for validation.
  ///   - maxLength: Maximum length allowed for input.
  ///   - validatesStrength: If `true`, applies a stronger rule (uppercase + lowercase + digit).
  case password(minLength: Int, maxLength: Int, validatesStrength: Bool)
  /// Amount formatting with grouping and fixed decimal scale.
  ///
  /// - Parameters:
  ///   - maxIntegerDigits: Maximum digits allowed before the decimal point.
  ///   - decimalDigits: Maximum digits allowed after the decimal point.
  case amount(maxIntegerDigits: Int, decimalDigits: Int)
  /// Email input and validation mode.
  ///
  /// The formatter lowercases the input and the validator applies an email regex.
  case email
  /// Numeric-only input.
  ///
  /// The formatter keeps digits only.
  case numeric
  /// Alphabet-only input.
  ///
  /// The formatter keeps ASCII letters only.
  case alphabetic
  /// Alphanumeric input.
  ///
  /// The formatter keeps ASCII letters and digits only.
  case alphaNumeric
  /// Custom regular expression filtering and optional visual grouping.
  ///
  /// - Parameters:
  ///   - regex: A single-character regular expression used for per-character filtering.
  ///   - maxLength: Optional max length override for this format.
  ///   - separator: Optional separator inserted between groups for display.
  ///   - groupPattern: Group sizes (e.g. `[4, 4, 4]`).
  case custom(
    regex: String,
    maxLength: Int?,
    separator: Character?,
    groupPattern: [Int]
  )

  /// Returns the suggested keyboard type for the format type.
  ///
  /// This is a convenience mapping and does not prevent you from overriding
  /// `keyboardType` manually if needed.
  public var keyboardType: UIKeyboardType {
    switch self {
    case .phoneNumber, .numeric, .bankCard, .verificationCode:
      return .numberPad
    case .amount:
      return .decimalPad
    case .email:
      return .emailAddress
    case .password:
      return .asciiCapable
    case .alphabetic, .alphaNumeric, .idCard, .custom:
      return .asciiCapable
    }
  }

  /// Returns the fixed completed length when the input type has one.
  ///
  /// When non-`nil`, `FKTextField` can treat the input as complete when raw text
  /// reaches this length and may auto-dismiss keyboard based on configuration.
  public var fixedLength: Int? {
    switch self {
    case let .verificationCode(length, _):
      return max(0, length)
    default:
      return nil
    }
  }
}

