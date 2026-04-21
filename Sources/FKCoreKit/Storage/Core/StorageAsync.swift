import Foundation

// MARK: - Async API

// MARK: - FKCodableStorage (async)

/// `async`/`await` facades that forward to synchronous ``FKCodableStorage`` methods inside unstructured `Task` blocks.
///
/// Scheduling uses the default executor; callers are not blocked by the backend’s internal queue work for the duration
/// of the synchronous call, but work still runs on the cooperative thread pool. For UI updates after completion,
/// hop to the main actor explicitly.
///
/// Each method begins with ``Task/yield()`` so the function contains a real suspension point (avoids redundant-`await` warnings).
public extension FKCodableStorage {
  /// Async version of ``FKCodableStorage/set(_:key:ttl:)``.
  ///
  /// - Parameters:
  ///   - value: Value to store.
  ///   - key: Logical key.
  ///   - ttl: Optional lifetime in seconds.
  func set<Value: Codable & Sendable>(_ value: Value, key: String, ttl: TimeInterval?) async throws {
    await Task.yield()
    try await Task { [self] in
      try self.set(value, key: key, ttl: ttl)
    }.value
  }

  /// Async version of ``FKCodableStorage/value(key:as:)``.
  ///
  /// - Parameters:
  ///   - key: Logical key.
  ///   - type: Expected decoded type.
  /// - Returns: Decoded value.
  func value<Value: Codable & Sendable>(key: String, as type: Value.Type) async throws -> Value {
    await Task.yield()
    return try await Task { [self] in
      try self.value(key: key, as: type)
    }.value
  }
}

// MARK: - FKStorageBackend (async)

public extension FKStorageBackend {
  /// Async version of ``FKStorageBackend/remove(key:)``.
  ///
  /// - Parameter key: Logical key to remove.
  func remove(key: String) async throws {
    await Task.yield()
    try await Task { [self] in
      try self.remove(key: key)
    }.value
  }

  /// Async version of ``FKStorageBackend/removeAll()``.
  func removeAll() async throws {
    await Task.yield()
    try await Task { [self] in
      try self.removeAll()
    }.value
  }

  /// Async version of ``FKStorageBackend/allKeys()``.
  ///
  /// - Returns: All logical keys for this backend instance.
  func allKeys() async throws -> [String] {
    await Task.yield()
    return try await Task { [self] in
      try self.allKeys()
    }.value
  }

  /// Async version of ``FKStorageBackend/purgeExpired()``.
  func purgeExpired() async throws {
    await Task.yield()
    try await Task { [self] in
      try self.purgeExpired()
    }.value
  }

  /// Async version of ``FKStorageBackend/exists(key:)``.
  ///
  /// - Parameter key: Logical key.
  /// - Returns: Whether a non-expired value exists.
  func exists(key: String) async -> Bool {
    await Task.yield()
    return await Task { [self] in
      self.exists(key: key)
    }.value
  }
}
