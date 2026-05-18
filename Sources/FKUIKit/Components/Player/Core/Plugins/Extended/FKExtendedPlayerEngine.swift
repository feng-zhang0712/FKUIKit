import AVFoundation
import Foundation
import UIKit

/// AVPlayer best-effort stand-in when no decoder factory is registered.
///
/// This type is **not** an MKV/DASH/RTMP player. It delegates to ``FKAVPlayerEngine`` and re-maps failures to
/// ``FKMediaError/unsupportedFormat`` when AV cannot open the asset. For real extended containers, register
/// ``FKMediaEngineRouter/registerExtendedEngineFactory(_:)`` with FFmpeg/VLC (or transcode to HLS/MP4 server-side).
@MainActor
public final class FKExtendedPlayerEngine: FKMediaPlayerEngine {

  public let kind: FKMediaEngineKind = .extended
  public var presentationMode: FKMediaPresentationMode {
    get { avEngine.presentationMode }
    set { avEngine.presentationMode = newValue }
  }

  public var state: FKMediaPlaybackState { avEngine.state }
  public var currentTime: TimeInterval { avEngine.currentTime }
  public var duration: TimeInterval { avEngine.duration }
  public var isLive: Bool { avEngine.isLive }
  public var liveLatencySeconds: TimeInterval? { avEngine.liveLatencySeconds }
  public var bufferedTimeRanges: [ClosedRange<TimeInterval>] { avEngine.bufferedTimeRanges }

  public var onStateChange: ((FKMediaPlaybackState) -> Void)? {
    get { avEngine.onStateChange }
    set { avEngine.onStateChange = newValue }
  }
  public var onTimeUpdate: ((TimeInterval, TimeInterval) -> Void)? {
    get { avEngine.onTimeUpdate }
    set { avEngine.onTimeUpdate = newValue }
  }
  public var onBufferedRangesUpdate: (([ClosedRange<TimeInterval>]) -> Void)? {
    get { avEngine.onBufferedRangesUpdate }
    set { avEngine.onBufferedRangesUpdate = newValue }
  }

  public weak var drmPlugin: FKMediaDRMPlugin? {
    get { avEngine.drmPlugin }
    set { avEngine.drmPlugin = newValue }
  }

  private let avEngine: FKAVPlayerEngine

  public init(
    networkSession: FKMediaNetworkSession,
    presentationMode: FKMediaPresentationMode
  ) {
    self.avEngine = FKAVPlayerEngine(networkSession: networkSession, presentationMode: presentationMode)
  }

  public func prepare(item: FKMediaItem, renderTarget: FKMediaRenderTarget?) async throws {
    do {
      try await avEngine.prepare(item: item, renderTarget: renderTarget)
    } catch {
      if let url = item.source.primaryURL ?? item.source.assetURL {
        let descriptor = FKMediaFormatProbe.probe(url: url)
        throw FKMediaError.unsupportedFormat(descriptor)
      }
      throw error
    }
  }

  public func play() { avEngine.play() }
  public func pause() { avEngine.pause() }
  public func stop() { avEngine.stop() }
  public func seek(to time: TimeInterval) async throws { try await avEngine.seek(to: time) }
  public func seekToLiveEdge() async throws { try await avEngine.seekToLiveEdge() }
  public func setRate(_ rate: Float) { avEngine.setRate(rate) }
  public func setVolume(_ volume: Float) { avEngine.setVolume(volume) }
  public func setMuted(_ muted: Bool) { avEngine.setMuted(muted) }
  public func teardown() { avEngine.teardown() }

  public func applyAdvancedOptions(_ options: FKMediaAdvancedPlaybackOptions) {
    avEngine.applyAdvancedOptions(options)
  }

  public var avPlayer: AVPlayer? { avEngine.avPlayer }
}
