import Foundation

/// A unified error type for FKBusinessKit.
public enum FKBusinessError: LocalizedError, Equatable, Sendable {
  /// The input is invalid.
  case invalidArgument(String)

  /// A required configuration is missing.
  case missingConfiguration(String)

  /// The requested operation is not supported in current environment.
  case unsupported(String)

  /// A network request failed.
  case networkFailed(underlying: String)

  /// A persistence operation failed.
  case persistenceFailed(underlying: String)

  /// A task was cancelled.
  case cancelled

  /// An unknown error occurred.
  case unknown(String)

  /// Human-readable error description for logging and UI fallback usage.
  public var errorDescription: String? {
    switch self {
    case let .invalidArgument(reason):
      return "Invalid argument: \(reason)"
    case let .missingConfiguration(reason):
      return "Missing configuration: \(reason)"
    case let .unsupported(reason):
      return "Unsupported: \(reason)"
    case let .networkFailed(underlying):
      return "Network failed: \(underlying)"
    case let .persistenceFailed(underlying):
      return "Persistence failed: \(underlying)"
    case .cancelled:
      return "Cancelled"
    case let .unknown(reason):
      return "Unknown: \(reason)"
    }
  }
}

