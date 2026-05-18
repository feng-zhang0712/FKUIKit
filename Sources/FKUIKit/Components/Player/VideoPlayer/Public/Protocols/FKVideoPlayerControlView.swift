import UIKit

/// Custom transport and progress chrome for ``FKVideoPlayerView``.
@MainActor
public protocol FKVideoPlayerControlView: UIView {
  var isControlsLocked: Bool { get set }

  func bind(player: FKVideoPlayer)
  func update(
    state: FKMediaPlaybackState,
    currentTime: TimeInterval,
    duration: TimeInterval,
    buffered: [ClosedRange<TimeInterval>],
    isLive: Bool,
    liveLatency: TimeInterval?
  )
  func setControlsVisible(_ visible: Bool, animated: Bool)
}
