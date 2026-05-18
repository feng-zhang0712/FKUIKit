import Foundation

/// How the engine router chooses between AVFoundation and the extended engine.
public struct FKMediaEnginePolicy: Sendable, Equatable {
  public var preferredEngine: FKMediaEngineSelection
  public var allowExtendedFallback: Bool
  public var allowAVFallback: Bool

  public init(
    preferredEngine: FKMediaEngineSelection = .automatic,
    allowExtendedFallback: Bool = true,
    allowAVFallback: Bool = false
  ) {
    self.preferredEngine = preferredEngine
    self.allowExtendedFallback = allowExtendedFallback
    self.allowAVFallback = allowAVFallback
  }

  public static let `default` = FKMediaEnginePolicy()
}

/// Engine selection preference applied before format-based routing.
public enum FKMediaEngineSelection: String, Sendable, Equatable {
  case automatic
  case avFoundation
  case extended
}
