import Foundation

#if os(iOS)

public extension FKPermissions {
  /// One-line async request for a single permission kind.
  ///
  /// - Parameters:
  ///   - kind: Permission kind.
  ///   - prePrompt: Optional custom guide alert shown before system prompt.
  ///   - temporaryLocationPurposeKey: Purpose key used only for temporary full-accuracy location request.
  /// - Returns: Unified permission request result.
  func request(
    _ kind: FKPermissionKind,
    prePrompt: FKPermissionPrePrompt? = nil,
    temporaryLocationPurposeKey: String? = nil
  ) async -> FKPermissionResult {
    await request(
      FKPermissionRequest(
        kind: kind,
        prePrompt: prePrompt,
        temporaryLocationPurposeKey: temporaryLocationPurposeKey
      )
    )
  }

  /// One-line closure request for a single permission kind.
  ///
  /// - Parameters:
  ///   - kind: Permission kind.
  ///   - prePrompt: Optional custom guide alert shown before system prompt.
  ///   - temporaryLocationPurposeKey: Purpose key used only for temporary full-accuracy location request.
  ///   - completion: Callback with request result.
  func request(
    _ kind: FKPermissionKind,
    prePrompt: FKPermissionPrePrompt? = nil,
    temporaryLocationPurposeKey: String? = nil,
    completion: @escaping @Sendable (FKPermissionResult) -> Void
  ) {
    request(
      FKPermissionRequest(
        kind: kind,
        prePrompt: prePrompt,
        temporaryLocationPurposeKey: temporaryLocationPurposeKey
      ),
      completion: completion
    )
  }

  /// One-line async batch request from permission kinds.
  ///
  /// - Parameter kinds: List of permission kinds.
  /// - Returns: Result map keyed by permission kind.
  func request(_ kinds: [FKPermissionKind]) async -> [FKPermissionKind: FKPermissionResult] {
    let requests = kinds.map { FKPermissionRequest(kind: $0) }
    return await request(requests)
  }
}

#endif
