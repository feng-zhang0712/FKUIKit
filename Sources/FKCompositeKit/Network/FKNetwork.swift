//
// FKNetwork.swift
//

import Foundation
import Combine

/// Entry point. Configure once at app launch, then use `FKNetwork.shared`.
///
/// ```swift
/// FKNetwork.configure {
///   $0.baseURL = "https://api.example.com"
///   $0.defaultHeaders["Authorization"] = "Bearer \(token)"
///   $0.logLevel = .verbose
///   $0.retryCount = 2
/// }
///
/// // async/await
/// let user: User = try await FKNetwork.shared.send(
///   FKRequest(.get, path: "/users/1")
/// )
///
/// // Combine
/// FKNetwork.shared.publisher(FKRequest(.post, path: "/login").json(["email": email]))
///   .sink(receiveCompletion: { ... }, receiveValue: { (resp: LoginResponse) in ... })
///   .store(in: &cancellables)
/// ```
public final class FKNetwork: @unchecked Sendable {

  // MARK: - Shared

  nonisolated(unsafe) public static var shared: FKNetworkClient = FKNetworkClient()

  /// Shared download session (supports resume / progress).
  nonisolated(unsafe) public static var download: FKDownloadSession = FKDownloadSession()

  // MARK: - Configure

  public static func configure(_ block: (inout FKNetworkConfiguration) -> Void) {
    var config = FKNetworkConfiguration()
    block(&config)
    shared = FKNetworkClient(configuration: config)
    download = FKDownloadSession(configuration: config)
  }
}

// MARK: - Convenience shortcuts on FKNetworkClient

public extension FKNetworkClient {

  func get<T: Decodable & Sendable>(_ path: String, query: [String: String?] = [:]) async throws -> T {
    try await send(FKRequest(.get, path: path).query(query))
  }

  func post<T: Decodable & Sendable>(_ path: String, json: [String: any Sendable]) async throws -> T {
    try await send(FKRequest(.post, path: path).json(json))
  }

  func put<T: Decodable & Sendable>(_ path: String, json: [String: any Sendable]) async throws -> T {
    try await send(FKRequest(.put, path: path).json(json))
  }

  func delete<T: Decodable & Sendable>(_ path: String) async throws -> T {
    try await send(FKRequest(.delete, path: path))
  }
}
