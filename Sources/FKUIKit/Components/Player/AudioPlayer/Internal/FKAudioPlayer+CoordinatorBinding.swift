import Foundation

extension FKAudioPlayer {

  public func setAnalyticsPlugins(_ plugins: [FKMediaAnalyticsPlugin]) {
    coordinator.analyticsPlugins = plugins
  }

  public var resourceLoader: FKMediaResourceLoaderPlugin? {
    get { coordinator.resourceLoader }
    set { coordinator.resourceLoader = newValue }
  }

  public var drmPlugin: FKMediaDRMPlugin? {
    get { coordinator.drmPlugin }
    set { coordinator.drmPlugin = newValue }
  }

  public var offlineProvider: FKMediaOfflinePlaybackProviding? {
    get { coordinator.offlineProvider }
    set { coordinator.offlineProvider = newValue }
  }
}
