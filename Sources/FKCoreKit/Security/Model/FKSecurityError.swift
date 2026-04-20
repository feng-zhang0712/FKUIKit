import Foundation
import Security

/// Unified error type for FKSecurity operations.
public enum FKSecurityError: Error, Sendable, Equatable {
  /// Input data is invalid for the requested operation.
  case invalidInput(String)
  /// A required key or IV is missing or has an invalid length.
  case invalidKey(String)
  /// Cryptographic operation failed with a platform status code.
  case cryptoFailed(status: Int32, message: String)
  /// Security framework operation failed with an OSStatus code.
  case securityFailed(status: OSStatus, message: String)
  /// Key material is not available in Keychain or memory.
  case keyNotFound(String)
  /// File operation failed.
  case fileFailed(String)
  /// Feature is unavailable on the current OS/runtime.
  case unavailable(String)
  /// Unknown wrapped error message.
  case unknown(String)
}

extension FKSecurityError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case let .invalidInput(message):
      return "Invalid input: \(message)"
    case let .invalidKey(message):
      return "Invalid key material: \(message)"
    case let .cryptoFailed(status, message):
      return "Crypto operation failed (\(status)): \(message)"
    case let .securityFailed(status, message):
      return "Security operation failed (\(status)): \(message)"
    case let .keyNotFound(message):
      return "Key not found: \(message)"
    case let .fileFailed(message):
      return "File operation failed: \(message)"
    case let .unavailable(message):
      return "Unavailable: \(message)"
    case let .unknown(message):
      return "Unknown error: \(message)"
    }
  }
}

