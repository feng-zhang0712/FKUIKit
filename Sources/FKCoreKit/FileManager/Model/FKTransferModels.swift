import Foundation

/// Transfer direction type.
public enum FKTransferKind: String, Sendable, Codable {
  case download
  case upload
}

/// Transfer execution state.
public enum FKTransferState: String, Sendable, Codable {
  case idle
  case running
  case paused
  case completed
  case cancelled
  case failed
}

/// Transfer progress model delivered by callbacks.
public struct FKTransferProgress: Sendable, Equatable {
  public let taskID: Int
  public let progress: Double
  public let completedBytes: Int64
  public let totalBytes: Int64

  public init(taskID: Int, progress: Double, completedBytes: Int64, totalBytes: Int64) {
    self.taskID = taskID
    self.progress = progress
    self.completedBytes = completedBytes
    self.totalBytes = totalBytes
  }
}

/// Download request model.
public struct FKDownloadRequest: Sendable, Codable, Equatable {
  public let sourceURL: URL
  public let destinationDirectory: URL
  public let fileName: String?
  public let allowsBackground: Bool

  public init(
    sourceURL: URL,
    destinationDirectory: URL,
    fileName: String? = nil,
    allowsBackground: Bool = true
  ) {
    self.sourceURL = sourceURL
    self.destinationDirectory = destinationDirectory
    self.fileName = fileName
    self.allowsBackground = allowsBackground
  }
}

/// Download result model.
public struct FKDownloadResult: Sendable, Equatable {
  public let taskID: Int
  public let fileURL: URL
  public let sourceURL: URL

  public init(taskID: Int, fileURL: URL, sourceURL: URL) {
    self.taskID = taskID
    self.fileURL = fileURL
    self.sourceURL = sourceURL
  }
}

/// Upload request model.
public struct FKUploadRequest: Sendable, Equatable {
  public let urlRequest: URLRequest
  public let files: [FKUploadFile]
  public let formFields: [String: String]

  public init(urlRequest: URLRequest, files: [FKUploadFile], formFields: [String: String] = [:]) {
    self.urlRequest = urlRequest
    self.files = files
    self.formFields = formFields
  }
}

/// Upload file part model.
public struct FKUploadFile: Sendable, Equatable {
  public let fieldName: String
  public let fileURL: URL
  public let fileName: String
  public let mimeType: String

  public init(fieldName: String, fileURL: URL, fileName: String? = nil, mimeType: String? = nil) {
    self.fieldName = fieldName
    self.fileURL = fileURL
    self.fileName = fileName ?? fileURL.lastPathComponent
    self.mimeType = mimeType ?? FKFileMimeResolver.mimeType(for: fileURL.pathExtension)
  }
}

/// Upload result model.
public struct FKUploadResult: Sendable, Equatable {
  public let taskID: Int
  public let responseData: Data
  public let response: URLResponse?

  public init(taskID: Int, responseData: Data, response: URLResponse?) {
    self.taskID = taskID
    self.responseData = responseData
    self.response = response
  }
}

/// Persisted transfer snapshot used to restore state after relaunch.
public struct FKPersistedTransfer: Sendable, Codable, Equatable {
  public let id: Int
  public let kind: FKTransferKind
  public let state: FKTransferState
  public let sourceURL: URL
  public let destinationPath: String?
  public let updatedAt: Date

  public init(
    id: Int,
    kind: FKTransferKind,
    state: FKTransferState,
    sourceURL: URL,
    destinationPath: String?,
    updatedAt: Date
  ) {
    self.id = id
    self.kind = kind
    self.state = state
    self.sourceURL = sourceURL
    self.destinationPath = destinationPath
    self.updatedAt = updatedAt
  }
}
