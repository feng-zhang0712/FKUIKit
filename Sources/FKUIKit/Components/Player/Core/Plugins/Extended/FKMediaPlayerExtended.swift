import Foundation

/// Convenience namespace for extended-engine registration (part of ``FKUIKit``).
///
/// FKKit does not bundle FFmpeg/VLC. Registration only takes effect when ``factory`` returns a engine that
/// can decode MKV/DASH/RTMP; the default ``FKExtendedPlayerEngine`` path remains AV best-effort.
public enum FKMediaPlayerExtended {

  /// Registers a decoder-backed extended-engine factory at app launch (before extended URLs are loaded).
  public static func registerExtendedEngineFactory(_ factory: FKMediaExtendedEngineFactory) {
    FKMediaEngineRouter.registerExtendedEngineFactory(factory)
  }

  /// Whether a custom factory is currently registered (weak reference; may be `nil` if deallocated).
  public static var hasRegisteredFactory: Bool {
    FKMediaEngineRouter.extendedFactory != nil
  }
}
