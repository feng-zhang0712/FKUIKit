import Foundation

/// Unified error type for FKNetwork request lifecycle.
///
/// This enum normalizes transport, decoding, business, and security failures
/// into a single contract so callers can handle errors consistently.
public enum NetworkError: LocalizedError {
  /// URL construction failed.
  case invalidURL
  /// Response cannot be interpreted as valid HTTP response.
  case invalidResponse
  /// Request was cancelled by caller or URLSession.
  case requestCancelled
  /// Server returned empty body when data was expected.
  case noData
  /// Decoding from raw data to model failed.
  case decodingFailed(underlying: Error)
  /// Server returned non-2xx status code.
  case serverError(statusCode: Int, message: String?)
  /// Business layer returned explicit failure.
  case businessError(code: Int, message: String)
  /// SSL trust validation failed.
  case sslValidationFailed
  /// Network is not reachable.
  case offline
  /// Token refresh flow failed.
  case tokenRefreshFailed
  /// Signing process failed.
  case signingFailed
  /// Parameter encryption process failed.
  case encryptionFailed
  /// Fallback wrapper for unknown underlying errors.
  case underlying(Error)

  /// Human-readable error message for logging and UI display.
  public var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "Invalid URL."
    case .invalidResponse:
      return "Invalid HTTP response."
    case .requestCancelled:
      return "Request was cancelled."
    case .noData:
      return "No data returned from server."
    case let .decodingFailed(underlying):
      return "Failed to decode response: \(underlying.localizedDescription)"
    case let .serverError(statusCode, message):
      return "Server error(\(statusCode)): \(message ?? "Unknown error")"
    case let .businessError(code, message):
      return "Business error(\(code)): \(message)"
    case .sslValidationFailed:
      return "SSL validation failed."
    case .offline:
      return "No network connection."
    case .tokenRefreshFailed:
      return "Token refresh failed."
    case .signingFailed:
      return "Request signing failed."
    case .encryptionFailed:
      return "Parameter encryption failed."
    case let .underlying(error):
      return error.localizedDescription
    }
  }
}
