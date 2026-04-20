import Foundation

/// Default two-level cache implementation for FKNetwork.
///
/// Design notes:
/// - Memory layer is optimized for fast reads.
/// - Disk layer is optional and asynchronous to avoid blocking caller thread.
/// - Expiration is validated on both memory and disk reads.
public final class FKNetworkCache: Cacheable, @unchecked Sendable {
  /// Serializable disk record with expiration metadata.
  private struct CacheRecord: Codable {
    /// Unix timestamp when this record expires.
    let expiry: TimeInterval
    /// Cached payload data.
    let payload: Data
  }

  /// In-memory cache entry.
  fileprivate struct MemoryEntry {
    /// Unix timestamp when this entry expires.
    let expiry: TimeInterval
    /// Cached payload data.
    let data: Data

    /// Creates a memory entry.
    ///
    /// - Parameters:
    ///   - expiry: Expiration timestamp.
    ///   - data: Cached payload.
    init(expiry: TimeInterval, data: Data) {
      self.expiry = expiry
      self.data = data
    }
  }

  /// Fast in-memory store.
  private var memoryStore: [String: MemoryEntry] = [:]
  /// Lock for thread-safe read/write on in-memory store.
  private let lock = NSLock()
  /// Serial queue for disk IO operations.
  private let ioQueue = DispatchQueue(label: "com.fkkit.network.cache.io", qos: .utility)
  /// Disk root directory for cache files.
  private let directoryURL: URL
  /// Decoder for disk record payload.
  private let decoder = JSONDecoder()
  /// Encoder for disk record payload.
  private let encoder = JSONEncoder()

  /// Creates cache instance with optional namespace.
  ///
  /// - Parameter namespace: Subdirectory name under system caches directory.
  public init(namespace: String = "com.fkkit.network.cache") {
    let root = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    directoryURL = root.appendingPathComponent(namespace, isDirectory: true)
    try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
  }

  /// Reads cached value from memory first, then disk.
  ///
  /// - Parameter key: Stable cache key.
  /// - Returns: Cached data if present and not expired.
  public func value(for key: String) -> Data? {
    lock.lock()
    // Fast memory path.
    if let entry = memoryStore[key], entry.expiry > Date().timeIntervalSince1970 {
      lock.unlock()
      return entry.data
    }
    // Remove stale memory entry before disk fallback.
    memoryStore.removeValue(forKey: key)
    lock.unlock()
    // Disk fallback path.
    if let disk = valueFromDisk(for: key) {
      lock.lock()
      memoryStore[key] = disk
      lock.unlock()
      return disk.data
    }
    return nil
  }

  /// Stores value in memory and optionally persists to disk.
  ///
  /// - Parameters:
  ///   - value: Payload data.
  ///   - key: Stable cache key.
  ///   - ttl: Time-to-live in seconds.
  ///   - toDisk: Whether to persist to disk.
  public func set(_ value: Data, for key: String, ttl: TimeInterval, toDisk: Bool) {
    let expiry = Date().timeIntervalSince1970 + ttl
    lock.lock()
    memoryStore[key] = .init(expiry: expiry, data: value)
    lock.unlock()
    guard toDisk else { return }
    // Disk writes are async to reduce response latency.
    ioQueue.async { [encoder, directoryURL] in
      let record = CacheRecord(expiry: expiry, payload: value)
      guard let data = try? encoder.encode(record) else { return }
      let url = directoryURL.appendingPathComponent(key.fk_md5)
      try? data.write(to: url, options: .atomic)
    }
  }

  /// Removes cached value from both memory and disk.
  ///
  /// - Parameter key: Stable cache key.
  public func removeValue(for key: String) {
    lock.lock()
    memoryStore.removeValue(forKey: key)
    lock.unlock()
    ioQueue.async { [directoryURL] in
      let path = directoryURL.appendingPathComponent(key.fk_md5)
      try? FileManager.default.removeItem(at: path)
    }
  }

  /// Clears all memory and disk cache entries.
  public func removeAll() {
    lock.lock()
    memoryStore.removeAll()
    lock.unlock()
    ioQueue.async { [directoryURL] in
      try? FileManager.default.removeItem(at: directoryURL)
      try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }
  }

  /// Reads and validates disk cache record.
  ///
  /// - Parameter key: Stable cache key.
  /// - Returns: Valid memory entry if disk record exists and is not expired.
  private func valueFromDisk(for key: String) -> MemoryEntry? {
    let path = directoryURL.appendingPathComponent(key.fk_md5)
    guard let data = try? Data(contentsOf: path),
          let record = try? decoder.decode(CacheRecord.self, from: data)
    else {
      return nil
    }
    // Remove expired disk entry eagerly.
    if record.expiry <= Date().timeIntervalSince1970 {
      try? FileManager.default.removeItem(at: path)
      return nil
    }
    return MemoryEntry(expiry: record.expiry, data: record.payload)
  }
}
