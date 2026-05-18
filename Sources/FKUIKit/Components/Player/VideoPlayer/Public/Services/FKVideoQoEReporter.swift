import Foundation

/// Bridges ``FKMediaQoEService`` into ``FKVideoPlayer`` analytics.
@MainActor
public final class FKVideoQoEReporter {

  public let qoeService = FKMediaQoEService()

  public init() {}

  public func attach(to player: FKVideoPlayer) {
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
