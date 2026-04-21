import Foundation

public extension FKFileManager {
  /// Closure-based convenience for creating a directory.
  func createDirectory(
    at url: URL,
    intermediate: Bool = true,
    completion: @escaping @Sendable (Result<Void, FKFileManagerError>) -> Void
  ) {
    Task { @MainActor in
      do {
        try await createDirectory(at: url, intermediate: intermediate)
        completion(.success(()))
      } catch let error as FKFileManagerError {
        completion(.failure(error))
      } catch {
        completion(.failure(.unknown(error.localizedDescription)))
      }
    }
  }

  /// Closure-based convenience for deleting a file or directory.
  func removeItem(
    at url: URL,
    completion: @escaping @Sendable (Result<Void, FKFileManagerError>) -> Void
  ) {
    Task { @MainActor in
      do {
        try await removeItem(at: url)
        completion(.success(()))
      } catch let error as FKFileManagerError {
        completion(.failure(error))
      } catch {
        completion(.failure(.unknown(error.localizedDescription)))
      }
    }
  }

  /// Closure-based convenience for writing content.
  func writeContent(
    _ content: FKFileContent,
    to url: URL,
    atomically: Bool = true,
    completion: @escaping @Sendable (Result<Void, FKFileManagerError>) -> Void
  ) {
    Task { @MainActor in
      do {
        try await writeContent(content, to: url, atomically: atomically)
        completion(.success(()))
      } catch let error as FKFileManagerError {
        completion(.failure(error))
      } catch {
        completion(.failure(.unknown(error.localizedDescription)))
      }
    }
  }

  /// Closure-based convenience for reading Data.
  func readData(
    from url: URL,
    completion: @escaping @Sendable (Result<Data, FKFileManagerError>) -> Void
  ) {
    Task { @MainActor in
      do {
        completion(.success(try await readData(from: url)))
      } catch let error as FKFileManagerError {
        completion(.failure(error))
      } catch {
        completion(.failure(.unknown(error.localizedDescription)))
      }
    }
  }

  /// Closure-based convenience for reading text.
  func readText(
    from url: URL,
    encoding: String.Encoding = .utf8,
    completion: @escaping @Sendable (Result<String, FKFileManagerError>) -> Void
  ) {
    Task { @MainActor in
      do {
        completion(.success(try await readText(from: url, encoding: encoding)))
      } catch let error as FKFileManagerError {
        completion(.failure(error))
      } catch {
        completion(.failure(.unknown(error.localizedDescription)))
      }
    }
  }

  /// Closure-based convenience for writing codable model.
  func writeModel<T: Codable & Sendable>(
    _ model: T,
    to url: URL,
    completion: @escaping @Sendable (Result<Void, FKFileManagerError>) -> Void
  ) {
    Task { @MainActor in
      do {
        try await writeModel(model, to: url)
        completion(.success(()))
      } catch let error as FKFileManagerError {
        completion(.failure(error))
      } catch {
        completion(.failure(.unknown(error.localizedDescription)))
      }
    }
  }

  /// Closure-based convenience for reading codable model.
  func readModel<T: Codable & Sendable>(
    _ type: T.Type,
    from url: URL,
    completion: @escaping @Sendable (Result<T, FKFileManagerError>) -> Void
  ) {
    Task { @MainActor in
      do {
        completion(.success(try await readModel(type, from: url)))
      } catch let error as FKFileManagerError {
        completion(.failure(error))
      } catch {
        completion(.failure(.unknown(error.localizedDescription)))
      }
    }
  }

  /// Closure-based convenience for starting a download task.
  func download(
    _ request: FKDownloadRequest,
    completion: @escaping @Sendable (Result<Int, FKFileManagerError>) -> Void
  ) {
    Task { @MainActor in
      do {
        completion(.success(try await download(request)))
      } catch let error as FKFileManagerError {
        completion(.failure(error))
      } catch {
        completion(.failure(.unknown(error.localizedDescription)))
      }
    }
  }

  /// Closure-based convenience for starting an upload task.
  func upload(
    _ request: FKUploadRequest,
    completion: @escaping @Sendable (Result<Int, FKFileManagerError>) -> Void
  ) {
    Task { @MainActor in
      do {
        completion(.success(try await upload(request)))
      } catch let error as FKFileManagerError {
        completion(.failure(error))
      } catch {
        completion(.failure(.unknown(error.localizedDescription)))
      }
    }
  }
}
