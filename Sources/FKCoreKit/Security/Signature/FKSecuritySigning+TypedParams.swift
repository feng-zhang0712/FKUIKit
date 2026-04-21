import Foundation

extension FKSecuritySigning {
  /// Signs request parameters using only `String` values (Sendable-friendly overload).
  public func signParameters(
    _ parameters: [String: String],
    secret: String,
    algorithm: FKHMACAlgorithm
  ) async throws -> String {
    try await signParameters(parameters as [String: Any], secret: secret, algorithm: algorithm)
  }

  /// Closure overload for `String`-only parameters.
  public func signParameters(
    _ parameters: [String: String],
    secret: String,
    algorithm: FKHMACAlgorithm,
    completion: @escaping @Sendable (Result<String, FKSecurityError>) -> Void
  ) {
    Task {
      do { completion(.success(try await signParameters(parameters, secret: secret, algorithm: algorithm))) }
      catch let e as FKSecurityError { completion(.failure(e)) }
      catch { completion(.failure(.unknown(error.localizedDescription))) }
    }
  }
}

