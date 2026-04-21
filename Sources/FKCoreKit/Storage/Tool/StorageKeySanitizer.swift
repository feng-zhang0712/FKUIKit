import Foundation
import CryptoKit

// MARK: - StorageKeySanitizer (internal)

/// Maps arbitrary logical keys to deterministic, filesystem-safe blob filenames.
///
/// Uses SHA256 so keys with slashes or long Unicode still produce valid single-segment names under the sandbox.
enum StorageKeySanitizer {
  /// Builds a unique file name for `key` (hex digest + fixed suffix).
  ///
  /// - Parameter key: Logical storage key from the public API.
  /// - Returns: Lowercase hex SHA256 plus `.fkstore` extension.
  static func fileName(for key: String) -> String {
    // Hash UTF-8 bytes so the filename is bounded and path-safe on all supported OS versions.
    let digest = SHA256.hash(data: Data(key.utf8))
    return digest.map { String(format: "%02x", $0) }.joined() + ".fkstore"
  }
}
