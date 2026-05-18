import AVFoundation
import Foundation
import UIKit

/// AVFoundation-backed playback engine using `AVPlayer`.
@MainActor
public final class FKAVPlayerEngine: FKMediaPlayerEngine {

  public let kind: FKMediaEngineKind = .avFoundation
  public var presentationMode: FKMediaPresentationMode
  public private(set) var state: FKMediaPlaybackState = .idle {
    didSet {
      guard state != oldValue else { return }
      onStateChange?(state)
    }
  }

  public var onStateChange: ((FKMediaPlaybackState) -> Void)?
  public var onTimeUpdate: ((TimeInterval, TimeInterval) -> Void)?
  public var onBufferedRangesUpdate: (([ClosedRange<TimeInterval>]) -> Void)?

  public var currentTime: TimeInterval {
    guard let player else { return 0 }
    let seconds = CMTimeGetSeconds(player.currentTime())
    return seconds.isFinite ? seconds : 0
  }

  public var duration: TimeInterval {
    guard let item = player?.currentItem else { return 0 }
    let seconds = CMTimeGetSeconds(item.duration)
    return seconds.isFinite ? seconds : 0
  }

  public var isLive: Bool {
    if formatDescriptor?.isLive == true { return true }
    guard let item = player?.currentItem else { return false }
    if case .hls(onDemand: false) = formatDescriptor?.delivery {
      return item.duration.isIndefinite
    }
    return false
  }

  public var liveLatencySeconds: TimeInterval? {
    guard isLive, let item = player?.currentItem else { return nil }
    let seekable = item.seekableTimeRanges.last?.timeRangeValue
    guard let seekable else { return nil }
    let liveEdge = CMTimeGetSeconds(CMTimeRangeGetEnd(seekable))
    let current = currentTime
    let latency = liveEdge - current
    return latency.isFinite && latency >= 0 ? latency : nil
  }

  public var bufferedTimeRanges: [ClosedRange<TimeInterval>] {
    guard let ranges = player?.currentItem?.loadedTimeRanges else { return [] }
    return ranges.compactMap { value -> ClosedRange<TimeInterval>? in
      let range = value.timeRangeValue
      let start = CMTimeGetSeconds(range.start)
      let end = CMTimeGetSeconds(CMTimeAdd(range.start, range.duration))
      guard start.isFinite, end.isFinite, end >= start else { return nil }
      return start...end
    }
  }

  private let networkSession: FKMediaNetworkSession
  public weak var drmPlugin: FKMediaDRMPlugin?
  private var player: AVPlayer?
  private var playerLayer: AVPlayerLayer?
  private var playerKVO = FKMediaPlayerKVO()
  private var itemKVO = FKMediaPlayerKVO()
  private var timeObserver: Any?
  private var formatDescriptor: FKMediaFormatDescriptor?
  private var endObserver: NSObjectProtocol?
  private var preferredForwardBufferDuration: TimeInterval = 5
  private var advancedOptions = FKMediaAdvancedPlaybackOptions.default
  private var pendingRate: Float = 1

  public init(
    networkSession: FKMediaNetworkSession,
    presentationMode: FKMediaPresentationMode
  ) {
    self.networkSession = networkSession
    self.presentationMode = presentationMode
  }

  /// Supplies format metadata from the coordinator to avoid duplicate probing.
  public func applyFormatDescriptor(_ descriptor: FKMediaFormatDescriptor?) {
    formatDescriptor = descriptor
  }

  /// Rebinds the video render target without reloading the media item.
  public func attachRenderTarget(_ target: FKMediaRenderTarget?) {
    guard presentationMode == .video, let player else { return }

    let targetLayer: AVPlayerLayer? = {
      guard let target else { return nil }
      switch target {
      case let .playerLayer(layer):
        return layer
      case .containerView, .none:
        return nil
      }
    }()

    // Do not detach a host-owned layer when rebinding the same instance (e.g. after fullscreen).
    if let existingLayer = playerLayer,
       existingLayer !== targetLayer,
       existingLayer.superlayer != nil
    {
      existingLayer.removeFromSuperlayer()
    }
    playerLayer = nil
    attachRenderTarget(target, player: player)
  }

  public func prepare(item: FKMediaItem, renderTarget: FKMediaRenderTarget?) async throws {
    teardownPlayerOnly()
    state = .preparing

    let asset = try await networkSession.resolveAsset(for: item.source)
    if let drmPlugin {
      try drmPlugin.configure(asset: asset, item: item)
    }
    let playerItem = AVPlayerItem(asset: asset)
    playerItem.preferredForwardBufferDuration = preferredForwardBufferDuration

    let avPlayer = AVPlayer(playerItem: playerItem)
    avPlayer.automaticallyWaitsToMinimizeStalling = true
    applyLowLatencySettings(to: playerItem, player: avPlayer)
    player = avPlayer

    attachRenderTarget(renderTarget, player: avPlayer)
    observePlayer(avPlayer, item: playerItem)

    if let start = item.startPosition, start > 0 {
      let time = CMTime(seconds: start, preferredTimescale: 600)
      await avPlayer.seek(to: time, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
    }

    try await waitUntilReady(playerItem: playerItem)
    state = .ready
    emitTimeUpdate()
    emitBufferedUpdate()
  }

  public func play() {
    guard let player else { return }
    if state == .completed {
      Task {
        try? await seek(to: 0)
        player.playImmediately(atRate: pendingRate)
        updateStateFromPlayer()
      }
      return
    }
    player.playImmediately(atRate: pendingRate)
    updateStateFromPlayer()
  }

  public func pause() {
    player?.pause()
    if state == .playing || state == .buffering {
      state = .paused
    }
  }

  public func stop() {
    player?.pause()
    player?.replaceCurrentItem(with: nil)
    state = .idle
  }

  public func seek(to time: TimeInterval) async throws {
    guard let player else { throw FKMediaError.invalidState("No active player") }
    let cmTime = CMTime(seconds: time, preferredTimescale: 600)
    let finished = await player.seek(to: cmTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
    if !finished {
      throw FKMediaError.seekFailed
    }
    emitTimeUpdate()
  }

  public func seekToLiveEdge() async throws {
    guard let item = player?.currentItem else {
      throw FKMediaError.invalidState("No current item")
    }
    guard let range = item.seekableTimeRanges.last?.timeRangeValue else {
      throw FKMediaError.seekFailed
    }
    let liveEdge = CMTimeRangeGetEnd(range)
    try await seek(to: CMTimeGetSeconds(liveEdge))
  }

  public func setRate(_ rate: Float) {
    pendingRate = rate
    if state == .playing {
      player?.rate = rate
    }
  }

  public func setVolume(_ volume: Float) {
    player?.volume = volume
  }

  public func setMuted(_ muted: Bool) {
    player?.isMuted = muted
  }

  public func teardown() {
    teardownPlayerOnly()
    playerLayer?.removeFromSuperlayer()
    playerLayer = nil
    state = .idle
    formatDescriptor = nil
  }

  /// Exposes the underlying player for variant/subtitle selection in facades (same module).
  public var avPlayer: AVPlayer? { player }

  /// Exposes the active player item for thumbnail or metadata helpers.
  public var avPlayerItem: AVPlayerItem? { player?.currentItem }

  // MARK: - Configuration

  func setPreferredForwardBufferDuration(_ duration: TimeInterval) {
    preferredForwardBufferDuration = duration
    player?.currentItem?.preferredForwardBufferDuration = duration
  }

  func applyAdvancedOptions(_ options: FKMediaAdvancedPlaybackOptions) {
    advancedOptions = options
    guard let player, let playerItem = player.currentItem else { return }
    if options.enablesLowLatencyHLS {
      applyLowLatencySettings(to: playerItem, player: player)
    } else {
      player.automaticallyWaitsToMinimizeStalling = true
      playerItem.preferredForwardBufferDuration = preferredForwardBufferDuration
      if #available(iOS 13.0, *) {
        playerItem.configuredTimeOffsetFromLive = .invalid
      }
    }
  }

  private func applyLowLatencySettings(to playerItem: AVPlayerItem, player: AVPlayer) {
    guard advancedOptions.enablesLowLatencyHLS else { return }
    player.automaticallyWaitsToMinimizeStalling = false
    playerItem.preferredForwardBufferDuration = 0
    if #available(iOS 13.0, *) {
      playerItem.configuredTimeOffsetFromLive = CMTime(
        seconds: advancedOptions.preferredLiveOffsetSeconds,
        preferredTimescale: 1
      )
    }
  }

  // MARK: - Private

  private func attachRenderTarget(_ target: FKMediaRenderTarget?, player: AVPlayer) {
    guard presentationMode == .video else { return }

    guard let target else { return }

    switch target {
    case let .playerLayer(layer):
      layer.player = player
      playerLayer = layer
    case let .containerView(view):
      let layer = AVPlayerLayer(player: player)
      layer.frame = view.bounds
      layer.videoGravity = .resizeAspect
      view.layer.insertSublayer(layer, at: 0)
      playerLayer = layer
    case .none:
      break
    }
  }

  private func observePlayer(_ player: AVPlayer, item: AVPlayerItem) {
    playerKVO.observe(
      player: player,
      onRateChange: { [weak self] in self?.updateStateFromPlayer() },
      onTimeControlStatusChange: { [weak self] in self?.updateStateFromPlayer() },
      onCurrentItemChange: { [weak self] in self?.updateStateFromPlayer() }
    )

    itemKVO.observe(
      item: item,
      onStatusChange: { [weak self] in self?.updateStateFromPlayer() },
      onPlaybackLikelyToKeepUpChange: { [weak self] in self?.updateStateFromPlayer() },
      onPlaybackBufferEmptyChange: { [weak self] in self?.updateStateFromPlayer() },
      onLoadedTimeRangesChange: { [weak self] in
        self?.emitBufferedUpdate()
      }
    )

    let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
    timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] _ in
      self?.emitTimeUpdate()
    }

    endObserver = NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: item,
      queue: .main
    ) { [weak self] _ in
      self?.state = .completed
    }
  }

  private func waitUntilReady(playerItem: AVPlayerItem) async throws {
    if playerItem.status == .readyToPlay { return }

    let timeoutNanoseconds: UInt64 = 60_000_000_000
    try await withThrowingTaskGroup(of: Void.self) { group in
      group.addTask {
        let statusWaiter = PlayerItemStatusWaiter()
        try await withTaskCancellationHandler {
          try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            statusWaiter.observe(playerItem, continuation: continuation)
          }
        } onCancel: {
          statusWaiter.cancel()
        }
      }
      group.addTask {
        try await Task.sleep(nanoseconds: timeoutNanoseconds)
        throw FKMediaError.engineFailed(engine: .avFoundation, message: "Timed out waiting for player item")
      }
      try await group.next()
      group.cancelAll()
    }
  }

  private func updateStateFromPlayer() {
    guard let player else { return }

    if let item = player.currentItem, item.status == .failed {
      let error = FKMediaErrorMapper.mapPlayerItemError(item.error) ?? .engineFailed(engine: .avFoundation, message: "Playback failed")
      state = .failed(error)
      return
    }

    switch player.timeControlStatus {
    case .waitingToPlayAtSpecifiedRate:
      if state == .playing || state == .ready || state == .buffering {
        state = .buffering
      }
    case .playing:
      state = .playing
    case .paused:
      if state != .completed && state != .idle && state != .preparing {
        if player.rate == 0, state != .ready {
          state = .paused
        }
      }
    @unknown default:
      break
    }
  }

  private func emitTimeUpdate() {
    onTimeUpdate?(currentTime, duration)
  }

  private func emitBufferedUpdate() {
    onBufferedRangesUpdate?(bufferedTimeRanges)
  }

  private func teardownPlayerOnly() {
    if let timeObserver, let player {
      player.removeTimeObserver(timeObserver)
      self.timeObserver = nil
    }
    if let endObserver {
      NotificationCenter.default.removeObserver(endObserver)
      self.endObserver = nil
    }
    playerKVO.invalidate()
    itemKVO.invalidate()
    player?.pause()
    player = nil
  }
}

/// KVO waiter for `AVPlayerItem.status` with explicit cancellation cleanup.
private final class PlayerItemStatusWaiter: @unchecked Sendable {

  private let lock = NSLock()
  private var observation: NSKeyValueObservation?
  private var continuation: CheckedContinuation<Void, Error>?
  private var didFinish = false

  func observe(_ playerItem: AVPlayerItem, continuation: CheckedContinuation<Void, Error>) {
    lock.lock()
    self.continuation = continuation
    lock.unlock()

    observation = playerItem.observe(\.status, options: [.new]) { [weak self] item, _ in
      guard let self else { return }
      self.lock.lock()
      defer { self.lock.unlock() }
      guard !self.didFinish, let continuation = self.continuation else { return }
      switch item.status {
      case .readyToPlay:
        self.finish(observationCleanup: true) {
          continuation.resume()
        }
      case .failed:
        let error = FKMediaErrorMapper.mapPlayerItemError(item.error)
          ?? .engineFailed(engine: .avFoundation, message: "Item failed")
        self.finish(observationCleanup: true) {
          continuation.resume(throwing: error)
        }
      case .unknown:
        break
      @unknown default:
        break
      }
    }
  }

  func cancel() {
    lock.lock()
    defer { lock.unlock() }
    guard !didFinish, let continuation else { return }
    finish(observationCleanup: true) {
      continuation.resume(throwing: CancellationError())
    }
  }

  private func finish(observationCleanup: Bool, _ body: () -> Void) {
    didFinish = true
    if observationCleanup {
      observation?.invalidate()
      observation = nil
    }
    continuation = nil
    body()
  }
}
