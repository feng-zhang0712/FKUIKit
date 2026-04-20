import Foundation

// MARK: - Storage keys

/// Namespace-aware logical key for FKStorage to reduce collisions between features or apps.
///
/// Conform with `String` raw values that are unique **within** ``namespace`` (for example `"auth.token"`).
/// Use ``fullKey`` when calling ``FKCodableStorage`` APIs. Centralizing keys in one enum improves maintainability.
///
/// ```swift
/// enum AppStorageKey: String, FKStorageKey {
///   case authToken = "auth.token"
///   var namespace: String { "com.myapp" }
/// }
/// try storage.set("…", key: AppStorageKey.authToken.fullKey)
/// ```
public protocol FKStorageKey: Hashable, Sendable {
  /// Short identifier segment; unique when combined with ``namespace``.
  var rawValue: String { get }

  /// Stable prefix (bundle ID, team id, or feature id) that groups keys for your module.
  var namespace: String { get }
}

public extension FKStorageKey {
  /// Canonical string passed to storage: `"<namespace>.<rawValue>"`.
  var fullKey: String {
    "\(namespace).\(rawValue)"
  }
}

/// Concrete ``FKStorageKey`` for ad-hoc keys without an `enum`.
///
/// Use when keys are built dynamically or you only need a few one-off entries.
public struct FKStorageStringKey: FKStorageKey, Sendable {
  /// Isolates keys between modules or apps (mirror ``FKStorageKey/namespace``).
  public let namespace: String

  /// Logical key body paired with ``namespace`` for ``FKStorageKey/fullKey``.
  public let rawValue: String

  /// Creates a namespaced key.
  ///
  /// - Parameters:
  ///   - namespace: Prefix to avoid collisions.
  ///   - rawValue: Logical key body.
  public init(namespace: String, rawValue: String) {
    self.namespace = namespace
    self.rawValue = rawValue
  }
}
