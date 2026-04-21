import Foundation

extension FKSecuritySigning {
  public func hmac(
    _ data: Data,
    key: Data,
    algorithm: FKHMACAlgorithm,
    completion: @escaping @Sendable (Result<Data, FKSecurityError>) -> Void
  ) {
    Task {
      do { completion(.success(try await hmac(data, key: key, algorithm: algorithm))) }
      catch let e as FKSecurityError { completion(.failure(e)) }
      catch { completion(.failure(.unknown(error.localizedDescription))) }
    }
  }
}

