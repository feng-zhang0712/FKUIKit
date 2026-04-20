import Foundation

/// Common sandbox directories supported by FKFileManager.
public enum FKSandboxDirectory: Sendable {
  case home
  case documents
  case caches
  case temporary
}

/// Supported content write targets.
public enum FKFileContent: Sendable {
  case text(String, encoding: String.Encoding = .utf8)
  case data(Data)
  case jsonObject([String: AnySendable])
}

/// Type-erased sendable wrapper used by JSON object writing.
public struct AnySendable: @unchecked Sendable {
  public let value: Any
  public init(_ value: Any) {
    self.value = value
  }
}

/// File metadata model returned by FKFileManager.
public struct FKFileInfo: Sendable, Equatable {
  public let path: String
  public let name: String
  public let fileExtension: String
  public let mimeType: String
  public let sizeInBytes: Int64
  public let modifiedAt: Date?
  public let exists: Bool

  public init(
    path: String,
    name: String,
    fileExtension: String,
    mimeType: String,
    sizeInBytes: Int64,
    modifiedAt: Date?,
    exists: Bool
  ) {
    self.path = path
    self.name = name
    self.fileExtension = fileExtension
    self.mimeType = mimeType
    self.sizeInBytes = sizeInBytes
    self.modifiedAt = modifiedAt
    self.exists = exists
  }
}

/// Filter used for recursive file traversal.
public struct FKFileTraversalOptions: Sendable {
  public let recursive: Bool
  public let includeHiddenFiles: Bool
  public let allowedExtensions: Set<String>

  public init(
    recursive: Bool = true,
    includeHiddenFiles: Bool = false,
    allowedExtensions: Set<String> = []
  ) {
    self.recursive = recursive
    self.includeHiddenFiles = includeHiddenFiles
    self.allowedExtensions = allowedExtensions.map { $0.lowercased() }.reduce(into: Set<String>()) { $0.insert($1) }
  }
}
