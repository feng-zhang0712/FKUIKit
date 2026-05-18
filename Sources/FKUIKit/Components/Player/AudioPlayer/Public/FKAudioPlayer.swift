import AVFoundation
import Foundation
import MediaPlayer
import UIKit

/// Audio playback facade wrapping ``FKMediaPlaybackCoordinator`` for music, podcasts, and voice.
@MainActor
public final class FKAudioPlayer: NSObject {

  public let coordinator: FKMediaPlaybackCoordinator
  public let queue = FKAudioQueue()

  public var configuration: FKAudioPlayerConfiguration {
    didSet {
      coordinator.configuration = configuration.media
      applyLoopModeFromQueue()
    }
  }

  public weak var delegate: FKAudioPlayerDelegate?
  public weak var boundView: FKAudioPlayerView?
  /// Secondary chrome (e.g. modal Now Playing) that should mirror transport updates.
  private weak var attachedChromeView: FKAudioPlayerView?
  public weak var miniBar: FKAudioMiniBar?

  public var playHistoryStore: FKAudioPlayHistoryStore? = FKAudioUserDefaultsPlayHistoryStore()
  public lazy var carPlayCoordinator: FKAudioCarPlayCoordinator = FKAudioCarPlayCoordinator(player: self)
  public var qoeReporter = FKAudioQoEReporter()

  public private(set) var currentItem: FKAudioItem?
  public var currentIndex: Int? { queue.currentIndex }

  public var state: FKMediaPlaybackState { coordinator.state }
  public var currentTime: TimeInterval { coordinator.currentTime }
  public var duration: TimeInterval { coordinator.duration }
  public var bufferedTimeRanges: [ClosedRange<TimeInterval>] { coordinator.bufferedTimeRanges }

  public var rate: Float {
    get { coordinator.rate }
    set {
      let clamped = min(configuration.playback.maxRate, max(0.5, newValue))
      coordinator.rate = clamped
      if configuration.playback.remembersRatePerItem, let id = currentItem?.id {
        rateMemory[id] = clamped
      }
    }
  }

  private let sleepTimer = FKAudioSleepTimer()
  private var stopAfterCurrentItem = false
  var trackTransitionGeneration = 0
  private var rateMemory: [String: Float] = [:]
  private var lyricsLines: [FKAudioLyricLine] = []
  public private(set) var currentLyricLines: [FKAudioLyricLine] = []
  private var remoteTrackCommandTokens: [(command: MPRemoteCommand, token: Any)] = []

  public init(
    configuration: FKAudioPlayerConfiguration = .shared,
    coordinator: FKMediaPlaybackCoordinator? = nil
  ) {
    self.configuration = configuration
    var media = configuration.media
    media.enablesNowPlayingInfo = true
    media.enablesRemoteCommands = true
    self.coordinator = coordinator ?? FKMediaPlaybackCoordinator(configuration: media)
    super.init()
    self.coordinator.delegate = self
    applyLoopModeFromQueue()
    qoeReporter.attach(to: self)
    carPlayCoordinator.activate()
  }

  // MARK: - Loading

  public func load(_ item: FKAudioItem, autoPlay: Bool = false) {
    queue.replace([item], startIndex: 0)
    loadTrack(item, autoPlay: autoPlay)
  }

  public func loadQueue(_ items: [FKAudioItem], startIndex: Int = 0, autoPlay: Bool = false) {
    queue.replace(items, startIndex: startIndex)
    applyLoopModeFromQueue()
    guard let item = queue.currentItem else { return }
    if items.count > 1, queue.mode == .repeatAll {
      coordinator.configuration.playback.autoPlay = autoPlay
      coordinator.load(playlist: queue.toMediaPlaylist(), presentationMode: .audioOnly)
      coordinator.setRemotePlaylistSkipEnabled(true)
      currentItem = item
      notifyItemChange()
      boundView?.reload(for: item)
      attachedChromeView?.reload(for: item)
      miniBar?.reload(for: item)
      loadLyrics(for: item)
    } else {
      loadTrack(item, autoPlay: autoPlay)
    }
  }

  public func bind(to view: FKAudioPlayerView) {
    boundView = view
    view.bind(player: self)
    syncChrome(with: view)
    coordinator.attachRenderTarget(.none)
  }

  /// Binds chrome without replacing the primary ``boundView`` (e.g. modal Now Playing).
  public func attachChrome(_ view: FKAudioPlayerView) {
    view.bind(player: self)
    syncChrome(with: view)
    if boundView !== view {
      attachedChromeView = view
    }
  }

  /// Stops mirroring updates to a secondary chrome instance (call when a modal dismisses).
  public func detachChrome(_ view: FKAudioPlayerView) {
    if attachedChromeView === view {
      attachedChromeView = nil
    }
  }

  /// Pushes the current transport state into any player chrome instance.
  public func syncChrome(with view: FKAudioPlayerView) {
    if let item = currentItem {
      view.reload(for: item)
    }
    view.handleStateChange(state)
    view.updateProgress(current: currentTime, duration: duration, buffered: bufferedTimeRanges)
  }

  public func bind(miniBar: FKAudioMiniBar) {
    self.miniBar = miniBar
    miniBar.bind(player: self)
    miniBar.syncFromPlayer()
  }

  // MARK: - Transport

  public func play() {
    coordinator.play()
  }

  public func pause() {
    coordinator.pause()
  }

  public func stop() {
    sleepTimer.cancel()
    stopAfterCurrentItem = false
    coordinator.setRemotePlaylistSkipEnabled(false)
    unregisterRemoteTrackCommands()
    coordinator.stop()
    queue.clear()
    currentItem = nil
    lyricsLines = []
    currentLyricLines = []
    boundView?.reset()
    attachedChromeView?.reset()
    miniBar?.reset()
  }

  public func togglePlayPause() {
    switch state {
    case .playing, .buffering:
      pause()
    default:
      play()
    }
  }

  public func playNext() {
    Task {
      if let next = queue.advance() {
        await performTrackTransition(to: next, autoPlay: true)
      } else if queue.mode == .repeatAll, let first = queue.items.first {
        queue.replace(queue.items, startIndex: 0)
        await performTrackTransition(to: first, autoPlay: true)
      }
    }
  }

  public func playPrevious() {
    if currentTime > 3, queue.mode != .repeatOne {
      seek(to: 0, completion: nil)
      return
    }
    Task {
      if let previous = queue.retreat() {
        await performTrackTransition(to: previous, autoPlay: true)
      }
    }
  }

  public func seek(to time: TimeInterval, completion: ((Bool) -> Void)? = nil) {
    coordinator.seek(to: time, completion: completion)
  }

  public func setSleepTimer(fireDate: Date?) {
    sleepTimer.schedule(fireDate: fireDate) { [weak self] in
      guard let self else { return }
      switch self.sleepTimer.action {
      case .pause:
        self.pause()
      case .stop:
        self.stop()
      }
    }
  }

  public func setStopAfterCurrentItem(_ enabled: Bool) {
    stopAfterCurrentItem = enabled
  }

  public func seekToChapter(_ chapter: FKAudioChapter) {
    seek(to: chapter.time, completion: nil)
  }

  /// Reloads the current track after a failure without rebuilding the queue.
  public func retryCurrentItem(autoPlay: Bool = true) {
    guard let item = currentItem else { return }
    loadTrack(item, autoPlay: autoPlay)
  }

  // MARK: - Internal helpers

  func notifyItemChange() {
    delegate?.audioPlayer(self, didChangeItem: currentItem, index: queue.currentIndex)
    delegate?.audioPlayer(self, didChangeQueueIndex: queue.currentIndex)
  }

  func loadTrack(_ item: FKAudioItem, autoPlay: Bool) {
    applyStoredRate(for: item)
    currentItem = item
    coordinator.setRemotePlaylistSkipEnabled(false)
    coordinator.configuration.playback.autoPlay = autoPlay
    coordinator.load(item.toMediaItem(), presentationMode: .audioOnly)
    boundView?.reload(for: item)
    attachedChromeView?.reload(for: item)
    miniBar?.reload(for: item)
    loadLyrics(for: item)
    notifyItemChange()
    recordHistoryIfNeeded(item)
  }

  func loadLyrics(for item: FKAudioItem) {
    lyricsLines = []
    currentLyricLines = []
    if let text = item.lyricsText, !text.isEmpty {
      let parsed = FKAudioLyricsParser.parse(content: text)
      lyricsLines = parsed.isEmpty ? [FKAudioLyricLine(time: 0, text: text)] : parsed
      publishLyrics(lines: lyricsLines)
      return
    }
    guard let url = item.lyricsURL else {
      publishLyrics(lines: [])
      return
    }
    let itemID = item.id
    Task {
      do {
        let data: Data
        if url.isFileURL {
          data = try Data(contentsOf: url)
        } else {
          let (remoteData, _) = try await URLSession.shared.data(from: url)
          data = remoteData
        }
        let lines = try FKAudioLyricsParser.parse(data: data)
        await MainActor.run {
          guard self.currentItem?.id == itemID else { return }
          self.publishLyrics(lines: lines)
        }
      } catch {
        await MainActor.run {
          guard self.currentItem?.id == itemID else { return }
          self.publishLyrics(lines: [])
        }
      }
    }
  }

  private func publishLyrics(lines: [FKAudioLyricLine]) {
    lyricsLines = lines
    currentLyricLines = lines
    boundView?.setLyrics(lines: lines)
    attachedChromeView?.setLyrics(lines: lines)
    delegate?.audioPlayer(self, didLoadLyrics: lines)
  }

  func applyStoredRate(for item: FKAudioItem) {
    if configuration.playback.remembersRatePerItem, let stored = rateMemory[item.id] {
      coordinator.rate = stored
    }
  }

  func recordHistoryIfNeeded(_ item: FKAudioItem) {
    playHistoryStore?.recordPlayed(itemID: item.id, at: Date())
  }

  func registerRemoteTrackCommands() {
    unregisterRemoteTrackCommands()
    let center = MPRemoteCommandCenter.shared()
    center.nextTrackCommand.isEnabled = true
    center.previousTrackCommand.isEnabled = true
    remoteTrackCommandTokens = [
      (center.nextTrackCommand, center.nextTrackCommand.addTarget { [weak self] _ in
        guard let self else { return .commandFailed }
        self.playNext()
        return .success
      }),
      (center.previousTrackCommand, center.previousTrackCommand.addTarget { [weak self] _ in
        guard let self else { return .commandFailed }
        self.playPrevious()
        return .success
      }),
    ]
  }

  func unregisterRemoteTrackCommands() {
    let center = MPRemoteCommandCenter.shared()
    for registration in remoteTrackCommandTokens {
      registration.command.removeTarget(registration.token)
    }
    remoteTrackCommandTokens.removeAll()
    _ = center
  }

  private func updateLyricsHighlight(current: TimeInterval) {
    let index = FKAudioLyricsParser.activeLineIndex(at: current, in: lyricsLines)
    delegate?.audioPlayer(self, didUpdateLyricsLine: index)
    boundView?.highlightLyricLine(at: index)
    attachedChromeView?.highlightLyricLine(at: index)
  }
}

// MARK: - FKMediaPlaybackCoordinatorDelegate

extension FKAudioPlayer: FKMediaPlaybackCoordinatorDelegate {

  public func mediaPlaybackCoordinator(
    _ coordinator: FKMediaPlaybackCoordinator,
    didChangeState state: FKMediaPlaybackState
  ) {
    delegate?.audioPlayer(self, didChangeState: state)
    boundView?.handleStateChange(state)
    attachedChromeView?.handleStateChange(state)
    miniBar?.handleStateChange(state)
  }

  public func mediaPlaybackCoordinator(
    _ coordinator: FKMediaPlaybackCoordinator,
    didUpdateTime current: TimeInterval,
    duration: TimeInterval
  ) {
    delegate?.audioPlayer(self, didUpdateTime: current, duration: duration)
    boundView?.updateProgress(current: current, duration: duration, buffered: bufferedTimeRanges)
    attachedChromeView?.updateProgress(current: current, duration: duration, buffered: bufferedTimeRanges)
    miniBar?.updateProgress(current: current, duration: duration)
    updateLyricsHighlight(current: current)
  }

  public func mediaPlaybackCoordinator(
    _ coordinator: FKMediaPlaybackCoordinator,
    didUpdateBuffered ranges: [ClosedRange<TimeInterval>]
  ) {
    boundView?.updateProgress(current: currentTime, duration: duration, buffered: ranges)
    attachedChromeView?.updateProgress(current: currentTime, duration: duration, buffered: ranges)
  }

  public func mediaPlaybackCoordinatorDidFinish(_ coordinator: FKMediaPlaybackCoordinator) {
    if stopAfterCurrentItem {
      pause()
      stopAfterCurrentItem = false
      delegate?.audioPlayerDidFinish(self)
      return
    }
    if queue.mode == .repeatOne {
      delegate?.audioPlayerDidFinish(self)
      return
    }
    if queue.mode == .repeatAll, queue.items.count > 1 {
      delegate?.audioPlayerDidFinish(self)
      return
    }
    if let next = queue.advance() {
      Task { await performTrackTransition(to: next, autoPlay: true) }
    } else {
      delegate?.audioPlayerDidFinish(self)
    }
  }

  public func mediaPlaybackCoordinator(
    _ coordinator: FKMediaPlaybackCoordinator,
    didFail error: FKMediaError
  ) {
    delegate?.audioPlayer(self, didFail: error)
    boundView?.handleStateChange(.failed(error))
    attachedChromeView?.handleStateChange(.failed(error))
    miniBar?.handleStateChange(.failed(error))
  }

  public func mediaPlaybackCoordinator(
    _ coordinator: FKMediaPlaybackCoordinator,
    didAdvanceTo item: FKMediaItem,
    at index: Int,
    in playlist: FKMediaPlaylist
  ) {
    _ = playlist
    guard let audioItem = queue.items.first(where: { $0.id == item.id }) ?? queue.currentItem else { return }
    currentItem = audioItem
    queue.setCurrentIndex(index)
    loadLyrics(for: audioItem)
    boundView?.reload(for: audioItem)
    attachedChromeView?.reload(for: audioItem)
    miniBar?.reload(for: audioItem)
    notifyItemChange()
  }
}
