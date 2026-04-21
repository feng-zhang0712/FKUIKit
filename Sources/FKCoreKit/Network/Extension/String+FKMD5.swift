import CryptoKit
import Foundation

/// Internal utility extensions for stable cache key hashing and signatures.
extension String {
  /// Returns lowercase MD5 hash string when available.
  ///
  /// - Note:
  ///   - Uses CryptoKit MD5 on iOS 13+/macOS 10.15+.
  ///   - Falls back to `hashValue`-based string on older systems to preserve
  ///     compatibility. Fallback is not cryptographically secure.
  var fk_md5: String {
    if #available(iOS 13.0, macOS 10.15, *) {
      let digest = Insecure.MD5.hash(data: Data(utf8))
      return digest.map { String(format: "%02hhx", $0) }.joined()
    } else {
      return String(abs(hashValue))
    }
  }
}
