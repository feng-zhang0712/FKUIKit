import FKUIKit

/// Example ``FKMediaExtendedEngineFactory`` registered at app launch.
///
/// This stub forwards to ``FKExtendedPlayerEngine`` (AVPlayer best-effort). It demonstrates the
/// registration hook only — **MKV, DASH, RTMP, and similar formats still require a real decoder** in production.
@MainActor
final class FKMediaExtendedEngineExampleFactory: FKMediaExtendedEngineFactory {

  static let shared = FKMediaExtendedEngineExampleFactory()

  private init() {}

  func makeEngine(
    networkSession: FKMediaNetworkSession,
    presentationMode: FKMediaPresentationMode
  ) -> FKMediaPlayerEngine {
    FKExtendedPlayerEngine(networkSession: networkSession, presentationMode: presentationMode)
  }
}
