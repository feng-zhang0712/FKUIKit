import AVFoundation
import Foundation
import UIKit

/// Video playback facade wrapping ``FKMediaPlaybackCoordinator`` with UI helpers.
@MainActor
public final class FKVideoPlayer: NSObject {

  public let coordinator: FKMediaPlaybackCoordinator
  public var configuration: FKVideoPlayerConfiguration {
    didSet {
      coordinator.configuration = configuration.media
    }
  }

  public weak var delegate: FKVideoPlayerDelegate?
  public weak var boundView: FKVideoPlayerView?

  public private(set) var currentItem: FKVideoItem?
  public private(set) var playlist: FKVideoPlaylist?
  public var thumbnailProvider: FKVideoThumbnailProvider?
  public var adPlugin: FKVideoAdPlugin?
  public var offlineDownloadManager = FKVideoOfflineDownloadManager()
  public var qoeReporter = FKVideoQoEReporter()
  public var sharePlayCoordinator: FKVideoSharePlayCoordinating = FKVideoSharePlayCoordinator()
  public var showsLLHLSDebugPanel = false

  public var state: FKMediaPlaybackState { coordinator.state }
  public var engineKind: FKMediaEngineKind { coordinator.engineKind }
  public var isLive: Bool { coordinator.isLive }
  public var liveLatencySeconds: TimeInterval? { coordinator.liveLatencySeconds }
  public var currentTime: TimeInterval { coordinator.currentTime }
  public var duration: TimeInterval { coordinator.duration }
  public var bufferedTimeRanges: [ClosedRange<TimeInterval>] { coordinator.bufferedTimeRanges }

  public var rate: Float {
    get { coordinator.rate }
    set { coordinator.rate = newValue }
  }

  public var volume: Float {
    get { coordinator.volume }
    set { coordinator.volume = newValue }
  }

  public var isMuted: Bool {
    get { coordinator.isMuted }
    set { coordinator.isMuted = newValue }
  }

  private var screenCaptureObserver: NSObjectProtocol?
  private var didApplySkipIntro = false
  private var didApplySkipOutro = false

  public init(
    configuration: FKVideoPlayerConfiguration = .shared,
    coordinator: FKMediaPlaybackCoordinator? = nil
  ) {
    self.configuration = configuration
    let mediaCoordinator = coordinator ?? FKMediaPlaybackCoordinator(configuration: configuration.media)
    self.coordinator = mediaCoordinator
    super.init()
    mediaCoordinator.delegate = self
    mediaCoordinator.offlineProvider = offlineDownloadManager.offlinePlaybackProvider
    qoeReporter.attach(to: self)
    observeScreenCapture()
  }

  /// Enables LL-HLS mode on the underlying coordinator.
  public func setLowLatencyHLS(enabled: Bool, liveOffsetSeconds: TimeInterval = 3) {
    configuration.media.advanced.enablesLowLatencyHLS = enabled
    configuration.media.advanced.preferredLiveOffsetSeconds = liveOffsetSeconds
    coordinator.configuration = configuration.media
    coordinator.avPlayerEngine?.applyAdvancedOptions(configuration.media.advanced)
  }

  /// Runs a pre-roll ad when ``adPlugin`` is configured.
  public func playPrerollAd(from viewController: UIViewController?) async {
    guard let item = currentItem, let plugin = adPlugin else { return }
    try? await plugin.prepareAdBreak(kind: .preroll, for: item)
    await plugin.playAdBreak(from: viewController)
  }

  // MARK: - Loading

  public func load(_ item: FKVideoItem) {
    playlist = nil
    coordinator.setRemotePlaylistSkipEnabled(false)
    currentItem = item
    didApplySkipIntro = false
    didApplySkipOutro = false
    coordinator.load(item.toMediaItem(), presentationMode: .video)
    boundView?.reloadSubtitles(for: item)
  }

  public func load(playlist: FKVideoPlaylist, startIndex: Int = 0) {
    var list = playlist
    list.currentIndex = min(max(0, startIndex), max(0, list.items.count - 1))
    self.playlist = list
    didApplySkipIntro = false
    didApplySkipOutro = false
    coordinator.setRemotePlaylistSkipEnabled(list.items.count > 1)
    coordinator.load(playlist: list.toMediaPlaylist(), presentationMode: .video)
    if let item = list.currentItem {
      currentItem = item
      boundView?.reloadSubtitles(for: item)
    }
  }

  public func bind(to view: FKVideoPlayerView) {
    boundView = view
    view.bind(player: self)
    coordinator.attachRenderTarget(.playerLayer(view.playerLayer))
  }

  // MARK: - Transport

  public func play() {
    coordinator.play()
    applySkipIntroIfNeeded()
  }

  public func pause() {
    coordinator.pause()
  }

  public func stop() {
    coordinator.setRemotePlaylistSkipEnabled(false)
    coordinator.stop()
    playlist = nil
    currentItem = nil
    didApplySkipIntro = false
    didApplySkipOutro = false
    boundView?.resetChrome()
    if let screenCaptureObserver {
      NotificationCenter.default.removeObserver(screenCaptureObserver)
      self.screenCaptureObserver = nil
    }
  }

  public func togglePlayPause() {
    switch state {
    case .playing, .buffering:
      pause()
    default:
      play()
    }
  }

  public func seek(to time: TimeInterval, completion: ((Bool) -> Void)? = nil) {
    coordinator.seek(to: time, completion: completion)
  }

  public func seekToLiveEdge() {
    coordinator.seekToLiveEdge()
  }

  public func playNextInPlaylist() {
    guard coordinator.playNext() else { return }
    syncPlaylistIndexFromCoordinator()
  }

  public func playPreviousInPlaylist() {
    guard coordinator.playPrevious() else { return }
    syncPlaylistIndexFromCoordinator()
  }

  /// Jumps to a playlist entry by index when a playlist is active.
  @discardableResult
  public func playPlaylistItem(at index: Int) -> Bool {
    guard playlist != nil else { return false }
    let didJump = coordinator.jumpToPlaylistItem(at: index)
    if didJump {
      syncPlaylistIndexFromCoordinator()
    }
    return didJump
  }

  /// Seeks to a chapter on the current item when chapter metadata is present.
  public func seekToChapter(at index: Int) {
    guard let chapters = currentItem?.chapters, chapters.indices.contains(index) else { return }
    seek(to: chapters[index].time, completion: nil)
  }

  /// Re-attaches the video output layer on the bound view (e.g. after fullscreen reparenting).
  public func rebindVideoOutput() {
    guard let boundView else { return }
    coordinator.attachRenderTarget(.playerLayer(boundView.playerLayer))
    boundView.setNeedsLayout()
    boundView.layoutIfNeeded()
  }

  /// Display names of embedded legible (subtitle) tracks, if available.
  public var embeddedSubtitleTrackNames: [String] {
    guard let group = coordinator.avPlayerItem?.asset.mediaSelectionGroup(forMediaCharacteristic: .legible) else {
      return []
    }
    return group.options.map(\.displayName)
  }

  /// Display names of embedded audible tracks, if available.
  public var embeddedAudioTrackNames: [String] {
    guard let group = coordinator.avPlayerItem?.asset.mediaSelectionGroup(forMediaCharacteristic: .audible) else {
      return []
    }
    return group.options.map(\.displayName)
  }

  // MARK: - Media selection

  /// Limits peak bitrate for adaptive HLS streams.
  public func selectPeakBitrate(_ bitsPerSecond: Double) {
    coordinator.avPlayerItem?.preferredPeakBitRate = bitsPerSecond
  }

  /// Selects embedded legible media option by display name.
  public func selectEmbeddedSubtitle(named name: String?) {
    guard let item = coordinator.avPlayerItem,
          let group = item.asset.mediaSelectionGroup(forMediaCharacteristic: .legible) else { return }
    if let name,
       let option = group.options.first(where: { $0.displayName == name }) {
      item.select(option, in: group)
    } else {
      item.select(nil, in: group)
    }
  }

  /// Selects an audible track by display name.
  public func selectAudioTrack(named name: String?) {
    guard let item = coordinator.avPlayerItem,
          let group = item.asset.mediaSelectionGroup(forMediaCharacteristic: .audible) else { return }
    if let name,
       let option = group.options.first(where: { $0.displayName == name }) {
      item.select(option, in: group)
    } else {
      item.select(nil, in: group)
    }
  }

  /// Captures a frame from the current asset.
  public func captureThumbnail(at time: TimeInterval? = nil) async -> UIImage? {
    guard let asset = coordinator.avPlayerItem?.asset else { return nil }
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    let cmTime: CMTime
    if let time {
      cmTime = CMTime(seconds: time, preferredTimescale: 600)
    } else {
      cmTime = coordinator.avPlayer?.currentTime() ?? .zero
    }
    return await withCheckedContinuation { continuation in
      DispatchQueue.global(qos: .userInitiated).async {
        let image = try? generator.copyCGImage(at: cmTime, actualTime: nil)
        continuation.resume(returning: image.map { UIImage(cgImage: $0) })
      }
    }
  }

  // MARK: - Private

  private func syncPlaylistIndexFromCoordinator() {
    guard var list = playlist else { return }
    list.currentIndex = coordinator.currentPlaylistIndex
    playlist = list
    if let item = list.currentItem {
      currentItem = item
      didApplySkipIntro = false
      didApplySkipOutro = false
      boundView?.reloadSubtitles(for: item)
    }
  }

  private func syncVideoItem(from mediaItem: FKMediaItem, at index: Int) {
    guard var list = playlist else { return }
    list.currentIndex = index
    self.playlist = list
    guard let item = list.items.first(where: { $0.id == mediaItem.id }) ?? list.currentItem else { return }
    currentItem = item
    didApplySkipIntro = false
    didApplySkipOutro = false
    boundView?.reloadSubtitles(for: item)
  }

  private func applySkipOutroIfNeeded(current: TimeInterval, duration: TimeInterval) {
    guard !didApplySkipOutro,
          let skip = currentItem?.skipOutroDuration, skip > 0,
          duration > skip,
          current >= duration - skip else { return }
    didApplySkipOutro = true
    if playlist != nil {
      if !coordinator.playNext() {
        pause()
      } else {
        syncPlaylistIndexFromCoordinator()
      }
      return
    }
    seek(to: max(0, duration - 0.25), completion: { [weak self] _ in
      self?.pause()
    })
  }

  private func applySkipIntroIfNeeded() {
    guard !didApplySkipIntro,
          configuration.appliesSkipIntroOnLoad,
          let item = currentItem,
          let skip = item.skipIntroDuration, skip > 0,
          state == .playing || state == .ready else { return }
    didApplySkipIntro = true
    seek(to: skip, completion: nil)
  }

  private func observeScreenCapture() {
    guard screenCaptureObserver == nil else { return }
    screenCaptureObserver = NotificationCenter.default.addObserver(
      forName: UIScreen.capturedDidChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      Task { @MainActor in
        self?.handleScreenCaptureChange()
      }
    }
  }

  private func handleScreenCaptureChange() {
    guard UIScreen.main.isCaptured else {
      boundView?.setScreenCaptureOverlayVisible(false)
      return
    }
    boundView?.setScreenCaptureOverlayVisible(true)
    pause()
  }
}

// MARK: - FKMediaPlaybackCoordinatorDelegate

extension FKVideoPlayer: FKMediaPlaybackCoordinatorDelegate {

  public func mediaPlaybackCoordinator(
    _ coordinator: FKMediaPlaybackCoordinator,
    didChangeState state: FKMediaPlaybackState
  ) {
    delegate?.videoPlayer(self, didChangeState: state)
    boundView?.handleStateChange(state)

    if case .ready = state {
      applySkipIntroIfNeeded()
      rebindVideoOutput()
    }

  }

  public func mediaPlaybackCoordinator(
    _ coordinator: FKMediaPlaybackCoordinator,
    didAdvanceTo item: FKMediaItem,
    at index: Int,
    in playlist: FKMediaPlaylist
  ) {
    _ = playlist
    syncVideoItem(from: item, at: index)
    delegate?.videoPlayer(self, didAdvanceTo: currentItem, at: index, in: self.playlist)
  }

  public func mediaPlaybackCoordinator(
    _ coordinator: FKMediaPlaybackCoordinator,
    didUpdateTime current: TimeInterval,
    duration: TimeInterval
  ) {
    applySkipOutroIfNeeded(current: current, duration: duration)
    delegate?.videoPlayer(self, didUpdateTime: current, duration: duration)
    boundView?.updateProgress(current: current, duration: duration, buffered: bufferedTimeRanges)
  }

  public func mediaPlaybackCoordinator(
    _ coordinator: FKMediaPlaybackCoordinator,
    didUpdateBuffered ranges: [ClosedRange<TimeInterval>]
  ) {
    delegate?.videoPlayer(self, didUpdateBuffered: ranges)
    boundView?.updateProgress(current: currentTime, duration: duration, buffered: ranges)
  }

  public func mediaPlaybackCoordinatorDidFinish(_ coordinator: FKMediaPlaybackCoordinator) {
    delegate?.videoPlayerDidFinish(self)
  }

  public func mediaPlaybackCoordinator(
    _ coordinator: FKMediaPlaybackCoordinator,
    didFail error: FKMediaError
  ) {
    delegate?.videoPlayer(self, didFail: error)
    boundView?.handleStateChange(.failed(error))
  }
}
