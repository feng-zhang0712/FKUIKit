import Foundation

// MARK: - StorageCodec (internal)

/// Shared JSON encoder/decoder for all FKStorage backends (stable key ordering for debugging).
///
/// Encoding uses sorted keys for deterministic output. Decoding uses default `JSONDecoder` rules.
enum StorageCodec {
  /// Encoder reused across calls; not configured with custom date strategies (clients encode `Date` as ISO8601 in models if needed).
  static let encoder: JSONEncoder = {
    let e = JSONEncoder()
    e.outputFormatting = [.sortedKeys]
    return e
  }()

  /// Shared decoder for ``ExpiringRecord`` and user payloads.
  static let decoder = JSONDecoder()

  /// Encodes a value to JSON `Data`.
  ///
  /// - Throws: Rethrows `EncodingError` from `JSONEncoder` (wrapped as ``FKStorageError/encodingFailed`` by callers).
  static func encode<Value: Encodable>(_ value: Value) throws -> Data {
    try encoder.encode(value)
  }

  /// Decodes JSON `Data` into `type`.
  ///
  /// - Throws: Rethrows `DecodingError` (wrapped as ``FKStorageError/decodingFailed`` by callers).
  static func decode<Value: Decodable>(_ type: Value.Type, from data: Data) throws -> Value {
    try decoder.decode(type, from: data)
  }
}
