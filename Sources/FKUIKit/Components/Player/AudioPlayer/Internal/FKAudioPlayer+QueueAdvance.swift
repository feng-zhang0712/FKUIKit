import Foundation

extension FKAudioPlayer {

  public func applyLoopModeFromQueue() {
    switch queue.mode {
    case .repeatOne:
      coordinator.configuration.playback.loopMode = .one
    case .repeatAll:
      coordinator.configuration.playback.loopMode = .all
    case .sequential, .shuffle:
      coordinator.configuration.playback.loopMode = .none
    }
    refreshRemoteTrackCommands()
    boundView?.refreshQueueModeChrome()
  }

  /// When the Core playlist drives repeat-all, skip commands are handled by ``FKMediaPlaybackCoordinator``.
  var usesCoordinatorPlaylistNavigation: Bool {
    queue.items.count > 1 && queue.mode == .repeatAll
  }

  func refreshRemoteTrackCommands() {
    if usesCoordinatorPlaylistNavigation {
      unregisterRemoteTrackCommands()
    } else {
      registerRemoteTrackCommands()
    }
  }

  func performTrackTransition(to item: FKAudioItem, autoPlay: Bool) async {
    trackTransitionGeneration += 1
    let generation = trackTransitionGeneration

    let fade = configuration.playback.fadeBetweenTracksDuration
    guard let fade, fade > 0 else {
      guard generation == trackTransitionGeneration else { return }
      loadTrack(item, autoPlay: autoPlay)
      return
    }

    let steps = 8
    let stepDuration = fade / Double(steps)
    let originalVolume = coordinator.volume
    for _ in 0..<steps {
      guard generation == trackTransitionGeneration else { return }
      coordinator.volume = max(0, coordinator.volume - originalVolume / Float(steps))
      try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
    }
    guard generation == trackTransitionGeneration else { return }
    loadTrack(item, autoPlay: false)
    if autoPlay {
      coordinator.play()
    }
    for step in 1...steps {
      guard generation == trackTransitionGeneration else { return }
      coordinator.volume = originalVolume * Float(step) / Float(steps)
      try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
    }
    guard generation == trackTransitionGeneration else { return }
    coordinator.volume = originalVolume
  }

}
