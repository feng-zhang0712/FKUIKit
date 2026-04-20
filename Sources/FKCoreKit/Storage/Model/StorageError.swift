import Foundation

// MARK: - FKStorageError

/// Single error type for all FKStorage backends; inspect cases instead of parsing descriptions in production code.
///
/// Map failures from encoding, decoding, Keychain `OSStatus`, or file I/O into this enum for consistent handling.
public enum FKStorageError: Error, Sendable {
  /// No value for the key, or the entry expired and was treated as missing.
  case notFound

  /// `JSONEncoder` failed (rare for typical `Codable` types).
  case encodingFailed(underlying: Error)

  /// `JSONDecoder` could not produce the requested type (schema drift or wrong `type` at read time).
  case decodingFailed(underlying: Error)

  /// Keychain API returned a status other than success where FKStorage expects success.
  ///
  /// - Parameter status: Raw `OSStatus` from `SecItem*` APIs.
  case keychainFailed(status: OSStatus)

  /// Underlying `FileManager` or `Data` read/write error.
  case fileSystemFailed(underlying: Error)

  /// Reserved for invalid logical keys (for example empty after sanitization).
  case invalidKey

  /// Placeholder for backends that omit an operation.
  case unsupported
}

extension FKStorageError: LocalizedError {
  /// Human-readable messages suitable for logging or simple alerts (not for programmatic branching).
  public var errorDescription: String? {
    switch self {
    case .notFound:
      return "No stored value for key."
    case let .encodingFailed(error):
      return "Encoding failed: \(error.localizedDescription)"
    case let .decodingFailed(error):
      return "Decoding failed: \(error.localizedDescription)"
    case let .keychainFailed(status):
      return "Keychain error (status \(status))."
    case let .fileSystemFailed(error):
      return "File system error: \(error.localizedDescription)"
    case .invalidKey:
      return "Invalid storage key."
    case .unsupported:
      return "Operation not supported."
    }
  }
}
