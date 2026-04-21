import Foundation

extension FKSecurityUtilizing {
  public func randomBytes(count: Int, completion: @escaping @Sendable (Result<Data, FKSecurityError>) -> Void) {
    Task {
      do { completion(.success(try await randomBytes(count: count))) }
      catch let e as FKSecurityError { completion(.failure(e)) }
      catch { completion(.failure(.unknown(error.localizedDescription))) }
    }
  }

  public func secureWipeFile(at url: URL, passes: Int, completion: @escaping @Sendable (Result<Void, FKSecurityError>) -> Void) {
    Task {
      do { try await secureWipeFile(at: url, passes: passes); completion(.success(())) }
      catch let e as FKSecurityError { completion(.failure(e)) }
      catch { completion(.failure(.unknown(error.localizedDescription))) }
    }
  }
}

