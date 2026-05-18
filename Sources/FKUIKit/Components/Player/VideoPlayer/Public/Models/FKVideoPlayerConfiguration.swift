import Foundation

/// Root configuration for ``FKVideoPlayer``.
public struct FKVideoPlayerConfiguration: Sendable, Equatable {
  public var media: FKMediaConfiguration
  public var ui: FKVideoUIConfiguration
  public var appliesSkipIntroOnLoad: Bool

  public init(
    media: FKMediaConfiguration = .default,
    ui: FKVideoUIConfiguration = .default,
    appliesSkipIntroOnLoad: Bool = true
  ) {
    self.media = media
    self.ui = ui
    self.appliesSkipIntroOnLoad = appliesSkipIntroOnLoad
  }

  public static let `default` = FKVideoPlayerConfiguration()

  /// Shared mutable default for quick integration (set at launch or on the main actor).
  public nonisolated(unsafe) static var shared: FKVideoPlayerConfiguration = .default
}
