import Foundation

public extension UserDefaults {
  /// Reads and decodes a JSON-encoded value for `key`.
  func fk_decodeJSON<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T? {
    guard let data = data(forKey: key) else { return nil }
    return try JSONDecoder().decode(T.self, from: data)
  }

  /// Encodes `value` to JSON and stores it under `key`.
  func fk_encodeJSON<T: Encodable>(_ value: T, forKey key: String) throws {
    let data = try JSONEncoder().encode(value)
    set(data, forKey: key)
  }

  /// Removes the value for `key` when it exists.
  func fk_removeValue(forKey key: String) {
    removeObject(forKey: key)
  }
}
