import FKUIKit
import Foundation

/// Synthetic and real URLs for extended-engine demos (probe + load).
enum FKMediaPlayerCoreExampleSamples {

  struct ProbeSample: Sendable {
    let label: String
    let url: URL
  }

  /// URLs chosen to exercise ``FKMediaFormatProbe`` — hosts may be unreachable; probing needs no network.
  static let probes: [ProbeSample] = [
    ProbeSample(
      label: "MP4 (AV-native)",
      url: URL(string: "https://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_320x180.mp4")!
    ),
    ProbeSample(label: "MKV (extended-only)", url: URL(string: "https://cdn.example.com/film.mkv")!),
    ProbeSample(label: "WebM (extended-only)", url: URL(string: "https://cdn.example.com/clip.webm")!),
    ProbeSample(label: "DASH manifest", url: URL(string: "https://cdn.example.com/stream.mpd")!),
    ProbeSample(label: "RTMP live", url: URL(string: "rtmp://live.example.com/app/stream")!),
    ProbeSample(label: "RTSP live", url: URL(string: "rtsp://camera.example.com/live")!),
    ProbeSample(label: "HTTP-FLV", url: URL(string: "https://live.example.com/room.flv")!),
  ]

  static func item(id: String, url: URL, title: String? = nil) -> FKMediaItem {
    FKMediaItem(
      id: id,
      source: .url(url),
      title: title ?? url.lastPathComponent
    )
  }

  static var progressiveMP4: FKMediaItem {
    item(
      id: "core.demo.mp4",
      url: URL(string: "https://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_320x180.mp4")!,
      title: "Big Buck Bunny (MP4)"
    )
  }

  static var syntheticMKV: FKMediaItem {
    item(id: "core.demo.mkv", url: URL(string: "https://cdn.example.com/film.mkv")!, title: "Synthetic MKV")
  }

  static var syntheticDASH: FKMediaItem {
    item(id: "core.demo.mpd", url: URL(string: "https://cdn.example.com/stream.mpd")!, title: "Synthetic DASH")
  }
}
