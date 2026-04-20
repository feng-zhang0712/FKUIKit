import Foundation

/// Unified error type for FKFileManager file and transfer operations.
public enum FKFileManagerError: Error, Sendable, Equatable {
  /// Target path does not exist.
  case fileNotFound(path: String)
  /// Target path already exists.
  case fileAlreadyExists(path: String)
  /// URL is not valid for the requested operation.
  case invalidURL(String)
  /// Network transfer failed.
  case transferFailed(String)
  /// Response content is invalid for transfer handling.
  case invalidResponse
  /// Available disk space is below required bytes.
  case insufficientDiskSpace(required: Int64, available: Int64)
  /// ZIP APIs are unavailable on current platform version.
  case zipUnavailable
  /// Unknown wrapped error.
  case unknown(String)
}

extension FKFileManagerError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case let .fileNotFound(path):
      return "File not found at path: \(path)"
    case let .fileAlreadyExists(path):
      return "File already exists at path: \(path)"
    case let .invalidURL(value):
      return "Invalid URL: \(value)"
    case let .transferFailed(message):
      return "Transfer failed: \(message)"
    case .invalidResponse:
      return "Invalid transfer response."
    case let .insufficientDiskSpace(required, available):
      return "Insufficient disk space. Required: \(required), available: \(available)."
    case .zipUnavailable:
      return "ZIP operations are unavailable on this OS version."
    case let .unknown(message):
      return "Unknown error: \(message)"
    }
  }
}
