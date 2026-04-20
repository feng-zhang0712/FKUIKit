import Foundation

/// Concrete service for sandbox and file content operations.
@MainActor
final class FKFileStorageCore: FKFileOperating, FKFileContentStoring {
  private let fileManager: Foundation.FileManager

  init(fileManager: Foundation.FileManager = .default) {
    self.fileManager = fileManager
  }

  /// Resolves standard sandbox directory URL.
  func directoryURL(_ directory: FKSandboxDirectory) -> URL {
    switch directory {
    case .home:
      return URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
    case .documents:
      return fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    case .caches:
      return fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    case .temporary:
      return fileManager.temporaryDirectory
    }
  }

  func createDirectory(at url: URL, intermediate: Bool = true) async throws {
    do {
      try fileManager.createDirectory(at: url, withIntermediateDirectories: intermediate)
    } catch {
      throw FKFileManagerError.unknown(error.localizedDescription)
    }
  }

  func removeItem(at url: URL) async throws {
    guard fileManager.fileExists(atPath: url.path) else { throw FKFileManagerError.fileNotFound(path: url.path) }
    do {
      try fileManager.removeItem(at: url)
    } catch {
      throw FKFileManagerError.unknown(error.localizedDescription)
    }
  }

  func moveItem(from sourceURL: URL, to destinationURL: URL) async throws {
    guard fileManager.fileExists(atPath: sourceURL.path) else { throw FKFileManagerError.fileNotFound(path: sourceURL.path) }
    if fileManager.fileExists(atPath: destinationURL.path) { throw FKFileManagerError.fileAlreadyExists(path: destinationURL.path) }
    do {
      try fileManager.moveItem(at: sourceURL, to: destinationURL)
    } catch {
      throw FKFileManagerError.unknown(error.localizedDescription)
    }
  }

  func copyItem(from sourceURL: URL, to destinationURL: URL) async throws {
    guard fileManager.fileExists(atPath: sourceURL.path) else { throw FKFileManagerError.fileNotFound(path: sourceURL.path) }
    if fileManager.fileExists(atPath: destinationURL.path) { throw FKFileManagerError.fileAlreadyExists(path: destinationURL.path) }
    do {
      try fileManager.copyItem(at: sourceURL, to: destinationURL)
    } catch {
      throw FKFileManagerError.unknown(error.localizedDescription)
    }
  }

  func renameItem(at url: URL, newName: String) async throws -> URL {
    guard fileManager.fileExists(atPath: url.path) else { throw FKFileManagerError.fileNotFound(path: url.path) }
    let destination = url.deletingLastPathComponent().appendingPathComponent(newName, isDirectory: false)
    if fileManager.fileExists(atPath: destination.path) { throw FKFileManagerError.fileAlreadyExists(path: destination.path) }
    do {
      try fileManager.moveItem(at: url, to: destination)
      return destination
    } catch {
      throw FKFileManagerError.unknown(error.localizedDescription)
    }
  }

  func fileInfo(at url: URL) async throws -> FKFileInfo {
    let path = url.path
    guard fileManager.fileExists(atPath: path) else { throw FKFileManagerError.fileNotFound(path: path) }
    do {
      let attributes = try fileManager.attributesOfItem(atPath: path)
      let size = (attributes[.size] as? NSNumber)?.int64Value ?? 0
      let modified = attributes[.modificationDate] as? Date
      let ext = url.pathExtension
      return FKFileInfo(
        path: path,
        name: url.lastPathComponent,
        fileExtension: ext,
        mimeType: FKFileMimeResolver.mimeType(for: ext),
        sizeInBytes: size,
        modifiedAt: modified,
        exists: true
      )
    } catch {
      throw FKFileManagerError.unknown(error.localizedDescription)
    }
  }

  func exists(at url: URL) -> Bool {
    fileManager.fileExists(atPath: url.path)
  }

  func writeContent(_ content: FKFileContent, to url: URL, atomically: Bool = true) async throws {
    do {
      try ensureParentDirectory(for: url)
      switch content {
      case let .text(text, encoding):
        guard let data = text.data(using: encoding) else { throw FKFileManagerError.unknown("Text encoding failed.") }
        try data.write(to: url, options: atomically ? .atomic : [])
      case let .data(data):
        try data.write(to: url, options: atomically ? .atomic : [])
      case let .jsonObject(json):
        let dictionary = Dictionary(uniqueKeysWithValues: json.map { ($0.key, $0.value.value) })
        let data = try JSONSerialization.data(withJSONObject: dictionary, options: [.prettyPrinted])
        try data.write(to: url, options: atomically ? .atomic : [])
      }
    } catch let error as FKFileManagerError {
      throw error
    } catch {
      throw FKFileManagerError.unknown(error.localizedDescription)
    }
  }

  func writeModel<T: Codable & Sendable>(_ model: T, to url: URL) async throws {
    do {
      try ensureParentDirectory(for: url)
      let data = try JSONEncoder().encode(model)
      try data.write(to: url, options: .atomic)
    } catch {
      throw FKFileManagerError.unknown(error.localizedDescription)
    }
  }

  func readData(from url: URL) async throws -> Data {
    guard fileManager.fileExists(atPath: url.path) else { throw FKFileManagerError.fileNotFound(path: url.path) }
    do { return try Data(contentsOf: url) }
    catch { throw FKFileManagerError.unknown(error.localizedDescription) }
  }

  func readText(from url: URL, encoding: String.Encoding = .utf8) async throws -> String {
    let data = try await readData(from: url)
    guard let text = String(data: data, encoding: encoding) else { throw FKFileManagerError.unknown("Text decoding failed.") }
    return text
  }

  func readModel<T: Codable & Sendable>(_ type: T.Type, from url: URL) async throws -> T {
    let data = try await readData(from: url)
    do { return try JSONDecoder().decode(type, from: data) }
    catch { throw FKFileManagerError.unknown(error.localizedDescription) }
  }

  /// Enumerates files under directory by traversal options.
  func enumerateFiles(at directoryURL: URL, options: FKFileTraversalOptions) async throws -> [URL] {
    guard fileManager.fileExists(atPath: directoryURL.path) else { throw FKFileManagerError.fileNotFound(path: directoryURL.path) }
    let keys: [URLResourceKey] = [.isDirectoryKey, .isHiddenKey]
    let enumerationOptions: Foundation.FileManager.DirectoryEnumerationOptions = options.recursive ? [] : [.skipsSubdirectoryDescendants]
    guard let enumerator = fileManager.enumerator(at: directoryURL, includingPropertiesForKeys: keys, options: enumerationOptions) else { return [] }
    var output: [URL] = []
    while let next = enumerator.nextObject() as? URL {
      let values = try? next.resourceValues(forKeys: Set(keys))
      if options.includeHiddenFiles == false, values?.isHidden == true { continue }
      if values?.isDirectory == true { continue }
      let ext = next.pathExtension.lowercased()
      if options.allowedExtensions.isEmpty == false, options.allowedExtensions.contains(ext) == false { continue }
      output.append(next)
    }
    return output
  }

  func sizeOfDirectory(at directoryURL: URL) async throws -> Int64 {
    let files = try await enumerateFiles(at: directoryURL, options: FKFileTraversalOptions(recursive: true, includeHiddenFiles: true))
    return files.reduce(into: Int64(0)) { total, file in
      let values = try? file.resourceValues(forKeys: [.fileSizeKey])
      total += Int64(values?.fileSize ?? 0)
    }
  }

  func clearDirectory(at directoryURL: URL) async throws {
    guard fileManager.fileExists(atPath: directoryURL.path) else { return }
    do {
      let items = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
      for item in items { try fileManager.removeItem(at: item) }
    } catch {
      throw FKFileManagerError.unknown(error.localizedDescription)
    }
  }

  /// Public ZIP API placeholder for future native ZIP integration.
  func zipItem(at sourceURL: URL, to destinationURL: URL) async throws {
    _ = destinationURL
    guard fileManager.fileExists(atPath: sourceURL.path) else { throw FKFileManagerError.fileNotFound(path: sourceURL.path) }
    throw FKFileManagerError.zipUnavailable
  }

  /// Public unzip API placeholder for future native ZIP integration.
  func unzipItem(at sourceURL: URL, to destinationURL: URL) async throws {
    _ = destinationURL
    guard fileManager.fileExists(atPath: sourceURL.path) else { throw FKFileManagerError.fileNotFound(path: sourceURL.path) }
    throw FKFileManagerError.zipUnavailable
  }

  private func ensureParentDirectory(for url: URL) throws {
    let directory = url.deletingLastPathComponent()
    if fileManager.fileExists(atPath: directory.path) == false {
      try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }
  }
}
