import Foundation

/// Asynchronous validator for server-backed or expensive validation scenarios.
///
/// Implementers should be cancellation-aware because newer input should invalidate older
/// in-flight checks to avoid stale validation feedback.
@MainActor
public protocol FKTextFieldAsyncValidating: AnyObject {
  /// Validates current canonical value asynchronously.
  ///
  /// - Parameters:
  ///   - rawText: Canonical raw value.
  ///   - formattedText: UI display value.
  ///   - rule: Active input rule.
  /// - Returns: Validation result.
  func validateAsync(
    rawText: String,
    formattedText: String,
    rule: FKTextFieldInputRule
  ) async -> FKTextFieldValidationResult
}

/// Type-erased async validator.
@MainActor
public final class FKTextFieldAnyAsyncValidator: FKTextFieldAsyncValidating {
  private let block: @MainActor (_ raw: String, _ formatted: String, _ rule: FKTextFieldInputRule) async -> FKTextFieldValidationResult

  /// Creates a type-erased async validator from closure.
  public init(
    _ block: @escaping @MainActor (_ raw: String, _ formatted: String, _ rule: FKTextFieldInputRule) async -> FKTextFieldValidationResult
  ) {
    self.block = block
  }

  public func validateAsync(
    rawText: String,
    formattedText: String,
    rule: FKTextFieldInputRule
  ) async -> FKTextFieldValidationResult {
    await block(rawText, formattedText, rule)
  }
}

