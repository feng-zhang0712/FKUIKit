import Foundation

/// Factory that vends extended-engine instances (FFmpeg/VLC) when linked.
@MainActor
public protocol FKMediaExtendedEngineFactory: AnyObject {
  func makeEngine(
    networkSession: FKMediaNetworkSession,
    presentationMode: FKMediaPresentationMode
  ) -> FKMediaPlayerEngine
}

/// Selects the playback engine from format metadata and policy.
public enum FKMediaEngineRouter {

  /// Optional factory for a decoder-backed extended engine (e.g. FFmpeg/VLC).
  ///
  /// When `nil`, routing still selects `.extended` for MKV/DASH/RTMP probes, but ``makeEngine`` uses
  /// ``FKExtendedPlayerEngine`` (AVPlayer best-effort only — **not** a full MKV/DASH stack).
  public nonisolated(unsafe) static weak var extendedFactory: FKMediaExtendedEngineFactory?

  /// Registers a custom extended-engine factory at app launch (before loading extended-only URLs).
  ///
  /// Registering a stub that forwards to ``FKExtendedPlayerEngine`` does **not** add MKV/DASH support;
  /// you must vend an engine that can actually decode those containers.
  public static func registerExtendedEngineFactory(_ factory: FKMediaExtendedEngineFactory) {
    extendedFactory = factory
  }

  /// Resolves which engine kind should be used for the given descriptor.
  public static func selectEngine(
    descriptor: FKMediaFormatDescriptor,
    policy: FKMediaEnginePolicy
  ) throws -> FKMediaEngineKind {
    switch policy.preferredEngine {
    case .avFoundation:
      guard descriptor.allowsAVFoundation else {
        throw FKMediaError.unsupportedFormat(descriptor)
      }
      return .avFoundation

    case .extended:
      guard descriptor.allowsExtended else {
        throw FKMediaError.unsupportedFormat(descriptor)
      }
      return .extended

    case .automatic:
      if descriptor.suggestedEngine == .avFoundation, descriptor.allowsAVFoundation {
        return .avFoundation
      }
      if descriptor.allowsExtended {
        return .extended
      }
      if descriptor.allowsAVFoundation {
        return .avFoundation
      }
      throw FKMediaError.unsupportedFormat(descriptor)
    }
  }

  /// Builds an engine instance for the selected kind.
  @MainActor
  public static func makeEngine(
    kind: FKMediaEngineKind,
    networkSession: FKMediaNetworkSession,
    presentationMode: FKMediaPresentationMode
  ) throws -> FKMediaPlayerEngine {
    switch kind {
    case .avFoundation:
      return FKAVPlayerEngine(networkSession: networkSession, presentationMode: presentationMode)
    case .extended:
      if let factory = extendedFactory {
        return factory.makeEngine(networkSession: networkSession, presentationMode: presentationMode)
      }
      return FKExtendedPlayerEngine(networkSession: networkSession, presentationMode: presentationMode)
    }
  }
}
