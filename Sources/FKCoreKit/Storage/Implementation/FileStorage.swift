import Foundation

// MARK: - FKFileStorage

/// File-based JSON persistence under the app’s Application Support directory.
///
/// Each logical key maps to one blob file (``ExpiringRecord`` + payload) and a central `index.json` lists keys
/// for ``allKeys()``. Filenames are hashed via ``StorageKeySanitizer`` so keys stay valid on disk.
///
/// **When to use:** medium-sized cached DTOs, offline bundles, images as `Data`. Very large trees may need a database.
///
/// **Thread safety:** internal serial queue for all mutations and reads.
public final class FKFileStorage: FKCodableStorage, @unchecked Sendable {
  /// Container directory (`Application Support/<directoryName>/`).
  private let rootDirectory: URL

  /// JSON file listing logical keys for enumeration.
  private let indexURL: URL

  private let queue = DispatchQueue(label: "com.fkkit.storage.file", qos: .utility)

  /// Creates the on-disk layout if missing.
  ///
  /// - Parameters:
  ///   - directoryName: Subfolder name under Application Support (created if needed).
  ///   - fileManager: Inject in tests to use a temporary directory.
  /// - Throws: ``FKStorageError/fileSystemFailed`` if the directory or empty index cannot be written.
  public init(directoryName: String = "FKStorage", fileManager: FileManager = .default) throws {
    let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    rootDirectory = base.appendingPathComponent(directoryName, isDirectory: true)
    indexURL = rootDirectory.appendingPathComponent("index.json", isDirectory: false)
    try fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
    if !fileManager.fileExists(atPath: indexURL.path) {
      let empty = IndexFile(keys: [])
      let data = try StorageCodec.encode(empty)
      try data.write(to: indexURL, options: .atomic)
    }
  }

  /// Atomically writes the blob file and updates `index.json` when the key is new.
  public func set<Value: Codable & Sendable>(_ value: Value, key: String, ttl: TimeInterval?) throws {
    try queue.sync {
      let payload = try StorageCodec.encode(value)
      let now = Date().timeIntervalSince1970
      let expiresAt = ttl.map { now + $0 }
      let record = ExpiringRecord(data: payload, expiresAt: expiresAt)
      let data = try StorageCodec.encode(record)
      let fileURL = blobURL(for: key)
      try data.write(to: fileURL, options: .atomic)
      try addKeyToIndex(key)
    }
  }

  /// Reads blob file, honors TTL, and decodes the inner payload.
  public func value<Value: Codable & Sendable>(key: String, as type: Value.Type) throws -> Value {
    try queue.sync {
      let fileURL = blobURL(for: key)
      guard FileManager.default.fileExists(atPath: fileURL.path) else {
        throw FKStorageError.notFound
      }
      let data = try Data(contentsOf: fileURL)
      let record = try StorageCodec.decode(ExpiringRecord.self, from: data)
      let now = Date().timeIntervalSince1970
      if record.isExpired(now: now) {
        try? FileManager.default.removeItem(at: fileURL)
        try? removeKeyFromIndex(key)
        throw FKStorageError.notFound
      }
      do {
        return try StorageCodec.decode(type, from: record.data)
      } catch {
        throw FKStorageError.decodingFailed(underlying: error)
      }
    }
  }

  /// Deletes blob + index entry.
  public func remove(key: String) throws {
    try queue.sync {
      let url = blobURL(for: key)
      if FileManager.default.fileExists(atPath: url.path) {
        try FileManager.default.removeItem(at: url)
      }
      try removeKeyFromIndex(key)
    }
  }

  /// `true` if blob exists and TTL has not passed (stale files may be deleted).
  public func exists(key: String) -> Bool {
    queue.sync {
      let fileURL = blobURL(for: key)
      guard FileManager.default.fileExists(atPath: fileURL.path) else { return false }
      guard let data = try? Data(contentsOf: fileURL),
            let record = try? StorageCodec.decode(ExpiringRecord.self, from: data)
      else { return false }
      let now = Date().timeIntervalSince1970
      if record.isExpired(now: now) {
        try? FileManager.default.removeItem(at: fileURL)
        try? removeKeyFromIndex(key)
        return false
      }
      return true
    }
  }

  /// Removes every blob listed in the index and resets `index.json` to empty.
  public func removeAll() throws {
    try queue.sync {
      let fm = FileManager.default
      let keys = try readIndex().keys
      for key in keys {
        let url = blobURL(for: key)
        if fm.fileExists(atPath: url.path) {
          try fm.removeItem(at: url)
        }
      }
      let empty = IndexFile(keys: [])
      try StorageCodec.encode(empty).write(to: indexURL, options: .atomic)
    }
  }

  /// Keys from `index.json` (may omit orphans if index was edited externally).
  public func allKeys() throws -> [String] {
    try queue.sync {
      try readIndex().keys
    }
  }

  /// Walks indexed keys and deletes expired blobs plus index rows.
  public func purgeExpired() throws {
    try queue.sync {
      let keys = try readIndex().keys
      let now = Date().timeIntervalSince1970
      for key in keys {
        let url = blobURL(for: key)
        guard let data = try? Data(contentsOf: url),
              let record = try? StorageCodec.decode(ExpiringRecord.self, from: data)
        else { continue }
        if record.isExpired(now: now) {
          try? FileManager.default.removeItem(at: url)
          try? removeKeyFromIndex(key)
        }
      }
    }
  }

  /// Absolute folder containing blob files and `index.json` (useful for debugging or migration).
  public var directoryURL: URL { rootDirectory }

  /// Resolves the on-disk path for a logical key.
  private func blobURL(for key: String) -> URL {
    rootDirectory.appendingPathComponent(StorageKeySanitizer.fileName(for: key), isDirectory: false)
  }

  /// Serializable list of logical keys mirrored to `index.json`.
  private struct IndexFile: Codable, Sendable {
    var keys: [String]
  }

  private func readIndex() throws -> IndexFile {
    let data = try Data(contentsOf: indexURL)
    return try StorageCodec.decode(IndexFile.self, from: data)
  }

  private func writeIndex(_ index: IndexFile) throws {
    try StorageCodec.encode(index).write(to: indexURL, options: .atomic)
  }

  /// Appends `key` to the index if not already present (idempotent for overwrites).
  private func addKeyToIndex(_ key: String) throws {
    var index = try readIndex()
    if !index.keys.contains(key) {
      index.keys.append(key)
      try writeIndex(index)
    }
  }

  /// Removes `key` from the index file.
  private func removeKeyFromIndex(_ key: String) throws {
    var index = try readIndex()
    index.keys.removeAll { $0 == key }
    try writeIndex(index)
  }
}
