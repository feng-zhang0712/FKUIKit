import Foundation

enum FKFileMimeResolver {
  private static let fallbackMap: [String: String] = [
    "jpg": "image/jpeg",
    "jpeg": "image/jpeg",
    "png": "image/png",
    "gif": "image/gif",
    "webp": "image/webp",
    "heic": "image/heic",
    "pdf": "application/pdf",
    "json": "application/json",
    "txt": "text/plain",
    "html": "text/html",
    "zip": "application/zip",
    "mp4": "video/mp4",
    "mp3": "audio/mpeg",
  ]

  static func mimeType(for fileExtension: String) -> String {
    guard !fileExtension.isEmpty else { return "application/octet-stream" }
    return fallbackMap[fileExtension.lowercased()] ?? "application/octet-stream"
  }
}

actor FKTransferPersistenceStore {
  private let key: String
  private let defaults: UserDefaults

  init(key: String, defaults: UserDefaults = .standard) {
    self.key = key
    self.defaults = defaults
  }

  func save(_ transfers: [FKPersistedTransfer]) {
    if let data = try? JSONEncoder().encode(transfers) {
      defaults.set(data, forKey: key)
    }
  }

  func load() -> [FKPersistedTransfer] {
    guard let data = defaults.data(forKey: key),
          let items = try? JSONDecoder().decode([FKPersistedTransfer].self, from: data) else {
      return []
    }
    return items
  }
}
