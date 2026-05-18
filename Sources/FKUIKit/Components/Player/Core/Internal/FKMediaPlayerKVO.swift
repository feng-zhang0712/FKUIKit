import AVFoundation
import Foundation

/// Holds key-value observations for an `AVPlayer` instance.
@MainActor
final class FKMediaPlayerKVO {

  private var observations: [NSKeyValueObservation] = []

  func observe(
    player: AVPlayer,
    onRateChange: @escaping () -> Void,
    onTimeControlStatusChange: @escaping () -> Void,
    onCurrentItemChange: @escaping () -> Void
  ) {
    invalidate()

    observations.append(
      player.observe(\.rate, options: [.new]) { _, _ in
        onRateChange()
      }
    )

    observations.append(
      player.observe(\.timeControlStatus, options: [.new]) { _, _ in
        onTimeControlStatusChange()
      }
    )

    observations.append(
      player.observe(\.currentItem, options: [.new]) { _, _ in
        onCurrentItemChange()
      }
    )
  }

  func observe(
    item: AVPlayerItem,
    onStatusChange: @escaping () -> Void,
    onPlaybackLikelyToKeepUpChange: @escaping () -> Void,
    onPlaybackBufferEmptyChange: @escaping () -> Void,
    onLoadedTimeRangesChange: @escaping () -> Void
  ) {
    invalidate()

    observations.append(
      item.observe(\.status, options: [.new]) { _, _ in
        onStatusChange()
      }
    )

    observations.append(
      item.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { _, _ in
        onPlaybackLikelyToKeepUpChange()
      }
    )

    observations.append(
      item.observe(\.isPlaybackBufferEmpty, options: [.new]) { _, _ in
        onPlaybackBufferEmptyChange()
      }
    )

    observations.append(
      item.observe(\.loadedTimeRanges, options: [.new]) { _, _ in
        onLoadedTimeRangesChange()
      }
    )
  }

  func invalidate() {
    observations.forEach { $0.invalidate() }
    observations.removeAll()
  }

}
