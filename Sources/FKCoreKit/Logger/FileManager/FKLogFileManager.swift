import Foundation

/// File manager responsible for persistence, rotation, and storage control.
public final class FKLogFileManager: FKLogFileManaging, @unchecked Sendable {
  private let queue = DispatchQueue(label: "com.fkkit.logger.file", qos: .utility)
  private let fileManager = FileManager.default
  private let logsDirectoryURL: URL
  private let dayFormatter: DateFormatter

  /// Creates a file manager using default app support folder.
  public convenience init() {
    self.init(
      baseDirectoryURL: Self.fileManagerDefaultDirectory()
    )
  }

  /// Creates a file manager in a custom base directory.
  ///
  /// - Parameter baseDirectoryURL: Parent directory where `FKLogger` folder is stored.
  public init(baseDirectoryURL: URL) {
    logsDirectoryURL = baseDirectoryURL.appendingPathComponent("FKLogger", isDirectory: true)
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    dayFormatter = formatter
    createLogsDirectoryIfNeeded()
  }

  public func write(line: String, timestamp: Date, config: FKLoggerConfig) {
    queue.async { [weak self] in
      guard let self else { return }
      self.createLogsDirectoryIfNeeded()
      let targetFile = self.resolveWritableFileURL(timestamp: timestamp, config: config)
      self.append(line: line, to: targetFile)
      self.enforceStorageLimit(maxBytes: config.maxStorageSizeInBytes)
    }
  }

  public func allLogFiles() -> [URL] {
    queue.sync {
      listedLogFiles()
    }
  }

  public func clearAllLogs() {
    queue.async { [weak self] in
      guard let self else { return }
      let files = self.listedLogFiles()
      files.forEach { _ = try? self.fileManager.removeItem(at: $0) }
    }
  }

  public func exportLogsArchive() -> URL? {
    queue.sync {
      let files = listedLogFiles()
      guard !files.isEmpty else { return nil }

      let exportFile = fileManager.temporaryDirectory
        .appendingPathComponent("FKLogger-export-\(Int(Date().timeIntervalSince1970)).log")

      var mergedText = ""
      for file in files {
        mergedText += "\n===== \(file.lastPathComponent) =====\n"
        if let text = try? String(contentsOf: file, encoding: .utf8) {
          mergedText += text
        }
      }

      do {
        try mergedText.write(to: exportFile, atomically: true, encoding: .utf8)
        return exportFile
      } catch {
        return nil
      }
    }
  }

  private func resolveWritableFileURL(timestamp: Date, config: FKLoggerConfig) -> URL {
    let dayKey = config.rotatesDaily ? dayFormatter.string(from: timestamp) : "shared"
    let prefix = "FKLogger-\(dayKey)"
    let files = listedLogFiles().filter { $0.lastPathComponent.hasPrefix(prefix) }
    if let last = files.last, fileSize(of: last) < config.maxFileSizeInBytes {
      return last
    }
    let index = (files.count + 1)
    return logsDirectoryURL.appendingPathComponent("\(prefix)-\(index).log")
  }

  private func append(line: String, to fileURL: URL) {
    let text = line + "\n"
    let data = Data(text.utf8)

    if !fileManager.fileExists(atPath: fileURL.path) {
      fileManager.createFile(atPath: fileURL.path, contents: data, attributes: nil)
      return
    }

    guard let handle = try? FileHandle(forWritingTo: fileURL) else { return }
    defer { try? handle.close() }
    handle.seekToEndOfFile()
    handle.write(data)
  }

  private func enforceStorageLimit(maxBytes: UInt64) {
    guard maxBytes > 0 else { return }
    let files = listedLogFiles()
    var total = files.reduce(UInt64(0)) { $0 + fileSize(of: $1) }
    guard total > maxBytes else { return }

    for file in files {
      try? fileManager.removeItem(at: file)
      total -= fileSize(of: file)
      if total <= maxBytes {
        break
      }
    }
  }

  private func listedLogFiles() -> [URL] {
    let candidates = (try? fileManager.contentsOfDirectory(
      at: logsDirectoryURL,
      includingPropertiesForKeys: [.creationDateKey, .contentModificationDateKey],
      options: [.skipsHiddenFiles]
    )) ?? []

    return candidates
      .filter { $0.pathExtension == "log" }
      .sorted {
        fileDate(for: $0) < fileDate(for: $1)
      }
  }

  private func fileDate(for url: URL) -> Date {
    let values = try? url.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
    return values?.creationDate ?? values?.contentModificationDate ?? .distantPast
  }

  private func fileSize(of url: URL) -> UInt64 {
    let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
    return UInt64(size)
  }

  private func createLogsDirectoryIfNeeded() {
    if !fileManager.fileExists(atPath: logsDirectoryURL.path) {
      try? fileManager.createDirectory(
        at: logsDirectoryURL,
        withIntermediateDirectories: true
      )
    }
  }

  private static func fileManagerDefaultDirectory() -> URL {
    let fm = FileManager.default
    if let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
      return appSupport
    }
    return fm.temporaryDirectory
  }
}
