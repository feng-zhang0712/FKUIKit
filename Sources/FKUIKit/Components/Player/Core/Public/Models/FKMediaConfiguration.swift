import Foundation

/// Root configuration for ``FKMediaPlaybackCoordinator``.
public struct FKMediaConfiguration: Sendable, Equatable {
  public var playback: FKMediaPlaybackConfiguration
  public var network: FKMediaNetworkConfiguration
  public var enginePolicy: FKMediaEnginePolicy
  public var enablesNowPlayingInfo: Bool
  public var enablesRemoteCommands: Bool
  public var advanced: FKMediaAdvancedPlaybackOptions

  public init(
    playback: FKMediaPlaybackConfiguration = .default,
    network: FKMediaNetworkConfiguration = .default,
    enginePolicy: FKMediaEnginePolicy = .default,
    enablesNowPlayingInfo: Bool = true,
    enablesRemoteCommands: Bool = true,
    advanced: FKMediaAdvancedPlaybackOptions = .default
  ) {
    self.playback = playback
    self.network = network
    self.enginePolicy = enginePolicy
    self.enablesNowPlayingInfo = enablesNowPlayingInfo
    self.enablesRemoteCommands = enablesRemoteCommands
    self.advanced = advanced
  }

  public static let `default` = FKMediaConfiguration()

  /// Shared mutable default used by facades when no custom configuration is supplied.
  ///
  /// Stored as process-wide mutable state; set at app launch or mutate on the main actor.
  public nonisolated(unsafe) static var shared: FKMediaConfiguration = .default
}
