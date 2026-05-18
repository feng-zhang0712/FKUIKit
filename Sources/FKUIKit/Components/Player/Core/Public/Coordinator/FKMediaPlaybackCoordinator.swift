import AVFoundation
import Foundation
import MediaPlayer

/// Orchestrates playback engines, state, and system integration for video and audio facades.
@MainActor
public final class FKMediaPlaybackCoordinator: FKMediaNowPlayingCommandTarget {

  public var configuration: FKMediaConfiguration {
    didSet { networkSession.configuration = configuration.network }
  }

  public weak var delegate: FKMediaPlaybackCoordinatorDelegate?

  public private(set) var state: FKMediaPlaybackState = .idle {
    didSet {
      guard oldValue != state else { return }
      delegate?.mediaPlaybackCoordinator(self, didChangeState: state)
    }
  }

  public private(set) var currentItem: FKMediaItem?
  public private(set) var presentationMode: FKMediaPresentationMode = .video
  public private(set) var formatDescriptor: FKMediaFormatDescriptor?

  public var engineKind: FKMediaEngineKind {
    engine?.kind ?? .avFoundation
  }

  /// Active AVFoundation engine when the current session uses it.
  public var avPlayerEngine: FKAVPlayerEngine? {
    engine as? FKAVPlayerEngine
  }

  /// Convenience accessor for variant/subtitle selection in facades.
  public var avPlayer: AVPlayer? {
    avPlayerEngine?.avPlayer
  }

  /// Active player item when using AVFoundation.
  public var avPlayerItem: AVPlayerItem? {
    avPlayerEngine?.avPlayerItem
  }

  public var currentTime: TimeInterval { engine?.currentTime ?? 0 }
  public var duration: TimeInterval { engine?.duration ?? 0 }
  public var isLive: Bool { engine?.isLive ?? false }
  public var liveLatencySeconds: TimeInterval? { engine?.liveLatencySeconds }
  public var bufferedTimeRanges: [ClosedRange<TimeInterval>] { engine?.bufferedTimeRanges ?? [] }

  public var rate: Float {
    get { engine == nil ? configuration.playback.defaultRate : storedRate }
    set {
      storedRate = newValue
      engine?.setRate(newValue)
      refreshNowPlaying()
    }
  }

  public var volume: Float = 1 {
    didSet { engine?.setVolume(volume) }
  }

  public var isMuted: Bool = false {
    didSet { engine?.setMuted(isMuted) }
  }

  public var resourceLoader: FKMediaResourceLoaderPlugin? {
    didSet { networkSession.resourceLoader = resourceLoader }
  }

  public var drmPlugin: FKMediaDRMPlugin?

  public var photoAssetResolver: FKMediaPhotoAssetResolver? {
    didSet { networkSession.photoAssetResolver = photoAssetResolver }
  }

  public var offlineProvider: FKMediaOfflinePlaybackProviding? {
    didSet { networkSession.offlineProvider = offlineProvider }
  }

  public var analyticsPlugins: [FKMediaAnalyticsPlugin] = []

  public private(set) var playlist: FKMediaPlaylist?
  public private(set) var currentPlaylistIndex: Int = 0

  private var engine: FKMediaPlayerEngine?
  private let networkSession: FKMediaNetworkSession
  private let resumeStore: FKMediaResumeStore
  private let nowPlayingService: FKMediaNowPlayingService
  private let audioSessionManager: FKMediaAudioSessionManager
  private var storedRate: Float
  private var loadTask: Task<Void, Never>?
  private var pendingRenderTarget: FKMediaRenderTarget?

  public init(
    configuration: FKMediaConfiguration = .shared,
    networkSession: FKMediaNetworkSession? = nil,
    resumeStore: FKMediaResumeStore? = nil,
    nowPlayingService: FKMediaNowPlayingService? = nil,
    audioSessionManager: FKMediaAudioSessionManager? = nil
  ) {
    self.configuration = configuration
    self.networkSession = networkSession ?? FKMediaNetworkSession(configuration: configuration.network)
    self.resumeStore = resumeStore ?? FKMediaUserDefaultsResumeStore()
    self.nowPlayingService = nowPlayingService ?? FKMediaNowPlayingService()
    self.audioSessionManager = audioSessionManager ?? .shared
    self.storedRate = configuration.playback.defaultRate
    let photoResolver = FKMediaPhotoLibraryAssetResolver()
    self.photoAssetResolver = photoResolver
    self.networkSession.photoAssetResolver = photoResolver

    if configuration.enablesRemoteCommands {
      self.nowPlayingService.registerCommands(target: self)
    }
    self.audioSessionManager.setInterruptionHandler(owner: self) { [weak self] shouldResume in
      guard let self else { return }
      if !shouldResume {
        if self.state == .playing || self.state == .buffering {
          self.pause()
        }
        return
      }
      if self.state == .paused {
        self.play()
      }
    }
  }

  // MARK: - Loading

  /// Loads a playlist starting at ``FKMediaPlaylist/startIndex``.
  public func load(
    playlist: FKMediaPlaylist,
    presentationMode: FKMediaPresentationMode
  ) {
    guard !playlist.items.isEmpty else {
      transition(to: .failed(.invalidState("Playlist is empty")))
      return
    }
    self.playlist = playlist
    currentPlaylistIndex = playlist.startIndex
    loadItem(playlist.items[currentPlaylistIndex], presentationMode: presentationMode)
  }

  /// Advances to the next item when a playlist is active.
  @discardableResult
  public func playNext() -> Bool {
    advancePlaylist(by: 1)
  }

  /// Returns to the previous item when a playlist is active.
  @discardableResult
  public func playPrevious() -> Bool {
    guard advancePlaylist(by: -1) else { return false }
    return true
  }

  /// Loads a specific playlist entry by index.
  @discardableResult
  public func jumpToPlaylistItem(at index: Int) -> Bool {
    guard let playlist, playlist.items.indices.contains(index) else { return false }
    guard index != currentPlaylistIndex else { return true }
    currentPlaylistIndex = index
    let item = playlist.items[index]
    loadItem(item, presentationMode: presentationMode)
    delegate?.mediaPlaybackCoordinator(self, didAdvanceTo: item, at: index, in: playlist)
    return true
  }

  /// Loads a single media item and clears any active playlist.
  public func load(_ item: FKMediaItem, presentationMode: FKMediaPresentationMode) {
    playlist = nil
    currentPlaylistIndex = 0
    loadItem(item, presentationMode: presentationMode)
  }

  private func loadItem(_ item: FKMediaItem, presentationMode: FKMediaPresentationMode) {
    loadTask?.cancel()
    detachCallbacks(from: engine)
    engine?.teardown()
    engine = nil

    currentItem = item
    self.presentationMode = presentationMode
    transition(to: .preparing)
    track(.loadStarted(itemID: item.id))

    loadTask = Task { [weak self] in
      guard let self else { return }
      do {
        try self.audioSessionManager.activatePlaybackCategory(
          mode: presentationMode == .video ? .moviePlayback : .default
        )
        try await self.loadWithRouting(item: item, presentationMode: presentationMode)
      } catch {
        if Task.isCancelled {
          if self.state == .preparing {
            self.transition(to: .idle)
          }
          return
        }
        let mapped = self.normalizeError(error)
        let alreadyFailed = self.state.isFailed
        if !alreadyFailed {
          self.transition(to: .failed(mapped))
          self.delegate?.mediaPlaybackCoordinator(self, didFail: mapped)
        }
        self.track(.error(itemID: item.id, error: mapped))
      }
    }
  }

  /// Attaches or updates the video render target for the active engine.
  public func attachRenderTarget(_ target: FKMediaRenderTarget) {
    pendingRenderTarget = target
    guard let avEngine = engine as? FKAVPlayerEngine, presentationMode == .video else { return }
    avEngine.attachRenderTarget(target)
  }

  // MARK: - Transport

  public func play() {
    guard state == .ready || state == .paused || state == .buffering || state == .completed else { return }
    engine?.setRate(storedRate)
    engine?.play()
    syncStateFromEngine()
    if let item = currentItem {
      track(.play(itemID: item.id))
    }
    refreshNowPlaying()
  }

  public func pause() {
    engine?.pause()
    syncStateFromEngine()
    if let item = currentItem {
      track(.pause(itemID: item.id))
    }
    persistResumePosition()
    refreshNowPlaying()
  }

  public func stop() {
    loadTask?.cancel()
    loadTask = nil
    persistResumePosition()
    detachCallbacks(from: engine)
    engine?.stop()
    engine?.teardown()
    engine = nil
    playlist = nil
    currentPlaylistIndex = 0
    transition(to: .idle)
    nowPlayingService.clear()
  }

  public func seek(to time: TimeInterval, completion: ((Bool) -> Void)? = nil) {
    Task {
      guard let engine else {
        completion?(false)
        return
      }
      do {
        try await engine.seek(to: time)
        if let item = currentItem {
          track(.seek(itemID: item.id, position: time))
        }
        delegate?.mediaPlaybackCoordinator(self, didUpdateTime: currentTime, duration: duration)
        refreshNowPlaying()
        completion?(true)
      } catch {
        completion?(false)
      }
    }
  }

  public func seekToLiveEdge() {
    Task {
      guard let engine else { return }
      try? await engine.seekToLiveEdge()
      delegate?.mediaPlaybackCoordinator(self, didUpdateTime: currentTime, duration: duration)
      refreshNowPlaying()
    }
  }

  // MARK: - FKMediaNowPlayingCommandTarget

  public func remotePlay() -> MPRemoteCommandHandlerStatus {
    play()
    return .success
  }

  public func remotePause() -> MPRemoteCommandHandlerStatus {
    pause()
    return .success
  }

  public func remoteTogglePlayPause() -> MPRemoteCommandHandlerStatus {
    switch state {
    case .playing, .buffering:
      pause()
    default:
      play()
    }
    return .success
  }

  public func remoteSeek(to time: TimeInterval) -> MPRemoteCommandHandlerStatus {
    seek(to: time, completion: nil)
    return .success
  }

  public func remoteNextTrack() -> MPRemoteCommandHandlerStatus {
    playNext() ? .success : .commandFailed
  }

  public func remotePreviousTrack() -> MPRemoteCommandHandlerStatus {
    playPrevious() ? .success : .commandFailed
  }

  /// Enables lock-screen next/previous when a coordinator playlist is active.
  public func setRemotePlaylistSkipEnabled(_ enabled: Bool) {
    if enabled {
      nowPlayingService.registerPlaylistSkipCommands(target: self)
    } else {
      nowPlayingService.unregisterPlaylistSkipCommands()
    }
  }

  // MARK: - Private

  private func loadWithRouting(item: FKMediaItem, presentationMode: FKMediaPresentationMode) async throws {
    var resolvedItem = item
    if configuration.playback.resumePlaybackEnabled,
       resolvedItem.startPosition == nil,
       let saved = resumeStore.position(for: item.id) {
      resolvedItem.startPosition = saved
    }

    let descriptor = try probeDescriptor(for: resolvedItem.source)
    formatDescriptor = descriptor

    let primaryKind = try FKMediaEngineRouter.selectEngine(descriptor: descriptor, policy: configuration.enginePolicy)

    do {
      try await loadWithEngine(kind: primaryKind, item: resolvedItem, presentationMode: presentationMode, descriptor: descriptor)
    } catch {
      if primaryKind == .avFoundation,
         configuration.enginePolicy.allowExtendedFallback,
         descriptor.allowsExtended {
        try await loadWithEngine(kind: .extended, item: resolvedItem, presentationMode: presentationMode, descriptor: descriptor)
        return
      }
      if primaryKind == .extended,
         configuration.enginePolicy.allowAVFallback,
         descriptor.allowsAVFoundation {
        try await loadWithEngine(kind: .avFoundation, item: resolvedItem, presentationMode: presentationMode, descriptor: descriptor)
        return
      }
      if !descriptor.allowsAVFoundation, !descriptor.allowsExtended {
        throw FKMediaError.transcodingRequired(suggested: descriptor.delivery)
      }
      throw error
    }
  }

  private func loadWithEngine(
    kind: FKMediaEngineKind,
    item: FKMediaItem,
    presentationMode: FKMediaPresentationMode,
    descriptor: FKMediaFormatDescriptor?
  ) async throws {
    detachCallbacks(from: engine)
    engine?.teardown()
    let newEngine = try FKMediaEngineRouter.makeEngine(
      kind: kind,
      networkSession: networkSession,
      presentationMode: presentationMode
    )

    if let avEngine = newEngine as? FKAVPlayerEngine {
      avEngine.setPreferredForwardBufferDuration(configuration.playback.preferredForwardBufferDuration)
      avEngine.applyAdvancedOptions(configuration.advanced)
      avEngine.applyFormatDescriptor(descriptor ?? formatDescriptor)
      avEngine.drmPlugin = drmPlugin
    } else if let extendedEngine = newEngine as? FKExtendedPlayerEngine {
      extendedEngine.applyAdvancedOptions(configuration.advanced)
      extendedEngine.drmPlugin = drmPlugin
    }

    wireEngineCallbacks(newEngine)
    engine = newEngine

    let renderTarget: FKMediaRenderTarget? = presentationMode == .video ? pendingRenderTarget : .none
    try await newEngine.prepare(item: item, renderTarget: renderTarget)

    newEngine.setVolume(volume)
    newEngine.setMuted(isMuted)
    newEngine.setRate(storedRate)

    transition(to: newEngine.state)
    track(.ready(itemID: item.id, engine: kind))

    if configuration.playback.autoPlay {
      play()
    }

    refreshNowPlaying()
    delegate?.mediaPlaybackCoordinator(self, didUpdateTime: currentTime, duration: duration)
    delegate?.mediaPlaybackCoordinator(self, didUpdateBuffered: bufferedTimeRanges)

    if case .failed(let error) = state {
      throw error
    }
  }

  private func wireEngineCallbacks(_ engine: FKMediaPlayerEngine) {
    engine.onStateChange = { [weak self] engineState in
      guard let self else { return }
      self.applyEngineState(engineState)
    }
    engine.onTimeUpdate = { [weak self] current, duration in
      guard let self else { return }
      self.delegate?.mediaPlaybackCoordinator(self, didUpdateTime: current, duration: duration)
      self.refreshNowPlaying()
    }
    engine.onBufferedRangesUpdate = { [weak self] ranges in
      guard let self else { return }
      self.delegate?.mediaPlaybackCoordinator(self, didUpdateBuffered: ranges)
    }
  }

  private func applyEngineState(_ engineState: FKMediaPlaybackState) {
    switch engineState {
    case .failed(let error):
      guard !state.isFailed else { return }
      transition(to: .failed(error))
      track(.error(itemID: currentItem?.id ?? "", error: error))
      delegate?.mediaPlaybackCoordinator(self, didFail: error)
    case .completed:
      transition(to: .completed)
      track(.complete(itemID: currentItem?.id ?? ""))
      delegate?.mediaPlaybackCoordinatorDidFinish(self)
      handlePlaybackEnded()
    case .buffering:
      transition(to: .buffering)
      if let id = currentItem?.id {
        track(.stall(itemID: id))
      }
    default:
      transition(to: engineState)
    }
  }

  private func syncStateFromEngine() {
    if let engineState = engine?.state {
      transition(to: engineState)
    }
  }

  private func transition(to newState: FKMediaPlaybackState) {
    guard newState != state else { return }
    guard FKMediaStateMachine.canTransition(from: state, to: newState) else { return }
    state = newState
  }

  private func detachCallbacks(from engine: FKMediaPlayerEngine?) {
    engine?.onStateChange = nil
    engine?.onTimeUpdate = nil
    engine?.onBufferedRangesUpdate = nil
  }

  private func handlePlaybackEnded() {
    persistResumePosition()
    guard currentItem != nil else { return }

    switch configuration.playback.loopMode {
    case .none:
      if playlist != nil, advancePlaylist(by: 1) {
        return
      }
    case .one:
      seek(to: 0, completion: { [weak self] _ in self?.play() })
    case .all:
      if playlist != nil {
        if advancePlaylist(by: 1) { return }
        currentPlaylistIndex = 0
        if let first = playlist?.items.first {
          loadItem(first, presentationMode: presentationMode)
          return
        }
      }
      seek(to: 0, completion: { [weak self] _ in self?.play() })
    }
  }

  @discardableResult
  private func advancePlaylist(by delta: Int) -> Bool {
    guard let playlist, !playlist.items.isEmpty else { return false }
    let nextIndex = currentPlaylistIndex + delta
    guard playlist.items.indices.contains(nextIndex) else { return false }
    currentPlaylistIndex = nextIndex
    let item = playlist.items[nextIndex]
    loadItem(item, presentationMode: presentationMode)
    delegate?.mediaPlaybackCoordinator(self, didAdvanceTo: item, at: nextIndex, in: playlist)
    return true
  }

  private func persistResumePosition() {
    guard configuration.playback.resumePlaybackEnabled, let item = currentItem else { return }
    let position = currentTime
    guard position > 0, duration <= 0 || position < duration - 1 else { return }
    resumeStore.setPosition(position, for: item.id)
  }

  private func refreshNowPlaying() {
    guard configuration.enablesNowPlayingInfo else { return }
    nowPlayingService.isEnabled = configuration.enablesNowPlayingInfo
    let playing = state == .playing || state == .buffering
    nowPlayingService.updateNowPlaying(
      item: currentItem,
      currentTime: currentTime,
      duration: duration,
      rate: storedRate,
      isPlaying: playing
    )
  }

  private func probeDescriptor(for source: FKMediaSource) throws -> FKMediaFormatDescriptor {
    if let probeURL = source.primaryURL ?? source.assetURL {
      return FKMediaFormatProbe.probe(url: probeURL, headers: source.httpHeaders)
    }
    switch source {
    case .photoAsset:
      return FKMediaFormatDescriptor(
        container: .mov,
        mediaType: .video,
        suggestedEngine: .avFoundation,
        delivery: .file,
        isLive: false,
        allowsAVFoundation: true,
        allowsExtended: false
      )
    case .offline:
      return FKMediaFormatDescriptor(
        container: .m3u8,
        mediaType: .multiplex,
        suggestedEngine: .avFoundation,
        delivery: .hls(onDemand: true),
        isLive: false,
        allowsAVFoundation: true,
        allowsExtended: false
      )
    case .asset, .url:
      throw FKMediaError.invalidState("Media source has no URL for format probing")
    }
  }

  private func normalizeError(_ error: Error) -> FKMediaError {
    if let mediaError = error as? FKMediaError { return mediaError }
    return FKMediaErrorMapper.map(error, engine: engine?.kind ?? .avFoundation)
  }

  private func track(_ event: FKMediaAnalyticsEvent) {
    analyticsPlugins.forEach { $0.track(event: event) }
  }
}
