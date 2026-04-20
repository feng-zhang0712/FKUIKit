import Foundation

/// Service-level protocol that exposes a shared `Networkable` instance.
///
/// Conforming types (for example repositories/view models/services) can call
/// default helper methods below for cleaner business code.
public protocol NetworkServiceProvidable {
  /// Shared network client.
  var network: Networkable { get }
}

/// Convenience request APIs for service layer.
public extension NetworkServiceProvidable {
  /// Sends typed request with callback style.
  ///
  /// - Parameters:
  ///   - request: Request definition.
  ///   - completion: Result callback.
  /// - Returns: Cancellable token.
  @discardableResult
  func request<R: Requestable>(
    _ request: R,
    completion: @escaping (Result<R.Response, NetworkError>) -> Void
  ) -> Cancellable {
    network.send(request, completion: completion)
  }

  /// Sends typed request with async/await style.
  ///
  /// - Parameter request: Request definition.
  /// - Returns: Decoded response model.
  /// - Throws: `NetworkError` on failure.
  @discardableResult
  @available(iOS 13.0, macOS 10.15, *)
  func request<R: Requestable>(_ request: R) async throws -> R.Response {
    try await network.send(request)
  }
}
