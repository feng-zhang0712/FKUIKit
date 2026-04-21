import Foundation

extension FKAESCrypting {
  public func encrypt(
    _ data: Data,
    using key: Data,
    iv: Data?,
    mode: FKAESMode,
    completion: @escaping @Sendable (Result<Data, FKSecurityError>) -> Void
  ) {
    Task {
      do { completion(.success(try await encrypt(data, using: key, iv: iv, mode: mode))) }
      catch let e as FKSecurityError { completion(.failure(e)) }
      catch { completion(.failure(.unknown(error.localizedDescription))) }
    }
  }

  public func decrypt(
    _ data: Data,
    using key: Data,
    iv: Data?,
    mode: FKAESMode,
    completion: @escaping @Sendable (Result<Data, FKSecurityError>) -> Void
  ) {
    Task {
      do { completion(.success(try await decrypt(data, using: key, iv: iv, mode: mode))) }
      catch let e as FKSecurityError { completion(.failure(e)) }
      catch { completion(.failure(.unknown(error.localizedDescription))) }
    }
  }

  public func encryptFile(
    at inputURL: URL,
    to outputURL: URL,
    using key: Data,
    iv: Data?,
    mode: FKAESMode,
    completion: @escaping @Sendable (Result<Void, FKSecurityError>) -> Void
  ) {
    Task {
      do { try await encryptFile(at: inputURL, to: outputURL, using: key, iv: iv, mode: mode); completion(.success(())) }
      catch let e as FKSecurityError { completion(.failure(e)) }
      catch { completion(.failure(.unknown(error.localizedDescription))) }
    }
  }

  public func decryptFile(
    at inputURL: URL,
    to outputURL: URL,
    using key: Data,
    iv: Data?,
    mode: FKAESMode,
    completion: @escaping @Sendable (Result<Void, FKSecurityError>) -> Void
  ) {
    Task {
      do { try await decryptFile(at: inputURL, to: outputURL, using: key, iv: iv, mode: mode); completion(.success(())) }
      catch let e as FKSecurityError { completion(.failure(e)) }
      catch { completion(.failure(.unknown(error.localizedDescription))) }
    }
  }
}

