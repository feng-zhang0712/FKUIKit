import Foundation

/// How media is delivered to the player (file, streaming protocol, etc.).
public enum FKMediaDelivery: Sendable, Equatable {
  case file
  case progressiveHTTP
  case hls(onDemand: Bool)
  case rtmp
  case rtsp
  case dash
  case httpFLV
}

extension FKMediaDelivery {

  /// Whether this delivery mode can carry live streams.
  public var isLiveCapable: Bool {
    switch self {
    case .hls, .rtmp, .rtsp, .httpFLV, .dash:
      return true
    case .file, .progressiveHTTP:
      return false
    }
  }

  /// Human-readable label for logging and errors.
  public var displayName: String {
    switch self {
    case .file: return "file"
    case .progressiveHTTP: return "progressiveHTTP"
    case let .hls(onDemand): return onDemand ? "hls-vod" : "hls-live"
    case .rtmp: return "rtmp"
    case .rtsp: return "rtsp"
    case .dash: return "dash"
    case .httpFLV: return "httpFLV"
    }
  }
}
