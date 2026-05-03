import Foundation

public extension URL {
  /// Query parameter dictionary; repeated keys keep the last value.
  var fk_queryParameters: [String: String] {
    guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
          let items = components.queryItems
    else {
      return [:]
    }
    var dict: [String: String] = [:]
    for item in items {
      if let value = item.value {
        dict[item.name] = value
      }
    }
    return dict
  }

  /// Appends or replaces query items and returns a new URL.
  func fk_appendingQueryParameters(_ parameters: [String: String?]) -> URL {
    guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
      return self
    }
    var items = components.queryItems ?? []
    for (name, value) in parameters {
      items.removeAll { $0.name == name }
      items.append(URLQueryItem(name: name, value: value))
    }
    components.queryItems = items
    return components.url ?? self
  }

  /// Removes listed query parameter names.
  func fk_removingQueryParameters(named names: Set<String>) -> URL {
    guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false),
          var items = components.queryItems
    else {
      return self
    }
    items.removeAll { names.contains($0.name) }
    components.queryItems = items.isEmpty ? nil : items
    return components.url ?? self
  }
}

public extension URL {
  /// File URL directory flag.
  var fk_isFileDirectory: Bool {
    (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
  }

  /// File size in bytes when available (file URLs only).
  var fk_fileSizeInBytes: Int64? {
    guard isFileURL else { return nil }
    guard let size = (try? resourceValues(forKeys: [.fileSizeKey]))?.fileSize else { return nil }
    return Int64(size)
  }

  /// Sets `isExcludedFromBackup` for file-system URLs (iCloud backup hint).
  mutating func fk_setExcludedFromBackup(_ excluded: Bool) throws {
    var values = URLResourceValues()
    values.isExcludedFromBackup = excluded
    try setResourceValues(values)
  }

  /// Non-mutating variant of `fk_setExcludedFromBackup(_:)`.
  func fk_withExcludedFromBackup(_ excluded: Bool) throws -> URL {
    var copy = self
    try copy.fk_setExcludedFromBackup(excluded)
    return copy
  }
}
