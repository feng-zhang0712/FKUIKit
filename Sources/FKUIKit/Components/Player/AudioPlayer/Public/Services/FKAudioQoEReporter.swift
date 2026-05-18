import Foundation

/// Bridges ``FKMediaQoEService`` into ``FKAudioPlayer`` analytics.
@MainActor
public final class FKAudioQoEReporter {

  public let qoeService = FKMediaQoEService()

  public init() {}

  public func attach(to player: FKAudioPlayer) {
    var plugins = player.coordinator.analyticsPlugins
    if !plugins.contains(where: { $0 === qoeService }) {
      plugins.append(qoeService)
    }
    player.setAnalyticsPlugins(plugins)
  }

  public func snapshot() -> FKMediaQoESnapshot {
    qoeService.currentSnapshot()
  }
}
