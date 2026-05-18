import AVFoundation
import Foundation

/// Abstraction over AVFoundation and optional extended playback backends.
@MainActor
public protocol FKMediaPlayerEngine: AnyObject {
  var kind: FKMediaEngineKind { get }
  var presentationMode: FKMediaPresentationMode { get set }
  var state: FKMediaPlaybackState { get }
  var currentTime: TimeInterval { get }
  var duration: TimeInterval { get }
  var isLive: Bool { get }
  var liveLatencySeconds: TimeInterval? { get }
  var bufferedTimeRanges: [ClosedRange<TimeInterval>] { get }

  var onStateChange: ((FKMediaPlaybackState) -> Void)? { get set }
  var onTimeUpdate: ((TimeInterval, TimeInterval) -> Void)? { get set }
  var onBufferedRangesUpdate: (([ClosedRange<TimeInterval>]) -> Void)? { get set }

  func prepare(item: FKMediaItem, renderTarget: FKMediaRenderTarget?) async throws
  func play()
  func pause()
  func stop()
  func seek(to time: TimeInterval) async throws
  func seekToLiveEdge() async throws
  func setRate(_ rate: Float)
  func setVolume(_ volume: Float)
  func setMuted(_ muted: Bool)
  func teardown()
}
