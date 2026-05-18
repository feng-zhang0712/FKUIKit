import Foundation

extension FKVideoPlayer {

  /// Forwards analytics plugins to the underlying coordinator.
  public func setAnalyticsPlugins(_ plugins: [FKMediaAnalyticsPlugin]) {
    coordinator.analyticsPlugins = plugins
  }

  /// Forwards resource loading to the underlying coordinator.
  public var resourceLoader: FKMediaResourceLoaderPlugin? {
    get { coordinator.resourceLoader }
    set { coordinator.resourceLoader = newValue }
  }

  /// FairPlay / DRM configuration hook on the coordinator's AV engine path.
  public var drmPlugin: FKMediaDRMPlugin? {
    get { coordinator.drmPlugin }
    set { coordinator.drmPlugin = newValue }
  }

  /// Offline HLS package lookup for ``FKMediaSource/offline``.
  public var offlineProvider: FKMediaOfflinePlaybackProviding? {
    get { coordinator.offlineProvider }
    set { coordinator.offlineProvider = newValue }
  }

  /// Photos library resolver for ``FKMediaSource/photoAsset``.
  public var photoAssetResolver: FKMediaPhotoAssetResolver? {
    get { coordinator.photoAssetResolver }
    set { coordinator.photoAssetResolver = newValue }
  }

  public var fairPlayContentKeyProvider: FKMediaFairPlayContentKeyProviding? {
    get { (drmPlugin as? FKMediaFairPlayDRMPlugin)?.contentKeyProvider }
    set {
      let plugin = drmPlugin as? FKMediaFairPlayDRMPlugin ?? FKMediaFairPlayDRMPlugin()
      plugin.contentKeyProvider = newValue
      drmPlugin = plugin
    }
  }
}
