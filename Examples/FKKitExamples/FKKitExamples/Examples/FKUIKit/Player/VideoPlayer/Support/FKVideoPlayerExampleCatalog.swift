import FKUIKit
import Foundation

/// Canonical sample URLs and ``FKVideoItem`` builders for VideoPlayer examples.
enum FKVideoPlayerExampleCatalog {

  // MARK: - Sample streams

  /// Full Big Buck Bunny (~9m 56s, Blender Foundation CDN).
  static let progressiveMP4 = URL(
    string: "https://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_320x180.mp4"
  )!

  /// Shorter fallback (~52s) when the primary CDN is blocked or slow.
  static let progressiveMP4Fallback = URL(string: "https://media.w3.org/2010/05/sintel/trailer.mp4")!

  /// Apple HLS VOD sample (multi-minute adaptive stream).
  static let hlsVOD = URL(
    string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8"
  )!

  /// Low-latency style live playlist (network required).
  static let hlsLive = URL(string: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8")!

  // MARK: - Items

  static func progressiveItem(title: String = "Big Buck Bunny (MP4)") -> FKVideoItem {
    FKVideoItem(
      id: "sample.mp4",
      source: .url(progressiveMP4, fallbackURLs: [progressiveMP4Fallback]),
      title: title
    )
  }

  static func hlsVODItem(title: String = "Apple Bip-Bop (HLS VOD)") -> FKVideoItem {
    FKVideoItem(
      id: "sample.hls.vod",
      source: .url(hlsVOD),
      title: title
    )
  }

  static func hlsLiveItem(title: String = "Mux test stream (Live)") -> FKVideoItem {
    FKVideoItem(
      id: "sample.hls.live",
      source: .url(hlsLive),
      title: title
    )
  }

  static func playlist() -> FKVideoPlaylist {
    FKVideoPlaylist(
      id: "demo.playlist",
      items: [
        progressiveItem(title: "Episode 1 — MP4"),
        hlsVODItem(title: "Episode 2 — HLS"),
        FKVideoItem(
          id: "episode.3",
          source: .url(progressiveMP4, fallbackURLs: [progressiveMP4Fallback]),
          title: "Episode 3 — Skip intro",
          chapters: [
            FKVideoChapter(title: "Opening", time: 0),
            FKVideoChapter(title: "Middle", time: 60),
            FKVideoChapter(title: "Credits", time: 480),
          ],
          skipIntroDuration: 5,
          skipOutroDuration: 8
        ),
      ],
      currentIndex: 0
    )
  }

  /// Bundled WebVTT in the example target (see `Support/Resources/sample-en.vtt`).
  static func bundledWebVTTURL() -> URL? {
    Bundle.main.url(forResource: "sample-en", withExtension: "vtt")
  }

  static func itemWithExternalSubtitles() -> FKVideoItem {
    var item = progressiveItem(title: "External WebVTT")
    if let url = bundledWebVTTURL() {
      item.subtitleSources = [.bundled(url: url, format: .vtt)]
    }
    return item
  }
}
