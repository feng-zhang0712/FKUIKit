import Foundation

// MARK: - ExpiringRecord (internal)

/// Internal wrapper: JSON-encoded user payload plus optional expiry (Unix time in seconds).
///
/// Stored as the outer layer when backends persist TTL (UserDefaults, Keychain, file). The inner ``data``
/// is the encoded `Codable` value from the public API.
struct ExpiringRecord: Codable, Sendable {
  /// Absolute expiry time since 1970; `nil` means the entry never expires via TTL.
  var expiresAt: TimeInterval?

  /// Inner JSON payload (encoded user value).
  var data: Data

  /// Creates a record for writing to disk or defaults.
  ///
  /// - Parameters:
  ///   - data: Encoded value bytes.
  ///   - expiresAt: Same semantics as property; pass `nil` for no expiry.
  init(data: Data, expiresAt: TimeInterval?) {
    self.data = data
    self.expiresAt = expiresAt
  }

  /// Whether the entry should be discarded at `now` (TTL elapsed).
  ///
  /// - Parameters:
  ///   - now: Current time as `Date().timeIntervalSince1970` for consistency with writers.
  /// - Returns: `false` when ``expiresAt`` is `nil` (no TTL).
  func isExpired(now: TimeInterval) -> Bool {
    guard let expiresAt else { return false }
    return now >= expiresAt
  }
}
