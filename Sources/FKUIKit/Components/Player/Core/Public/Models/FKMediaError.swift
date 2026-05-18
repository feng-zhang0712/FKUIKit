import Foundation

/// Errors surfaced by the media playback core.
public enum FKMediaError: Error, Sendable, Equatable {
  case unsupportedFormat(FKMediaFormatDescriptor)
  case transcodingRequired(suggested: FKMediaDelivery)
  case networkUnavailable
  case httpStatus(code: Int)
  case drmFailed(message: String)
  case engineFailed(engine: FKMediaEngineKind, message: String)
  case seekFailed
  case cancelled
  case notImplemented(feature: String)
  case invalidState(String)
}

extension FKMediaError: LocalizedError {

  public var errorDescription: String? {
    switch self {
    case let .unsupportedFormat(descriptor):
      return "Unsupported format: \(descriptor.container.rawValue)"
    case let .transcodingRequired(suggested):
      return "Transcoding required. Suggested delivery: \(suggested.displayName)"
    case .networkUnavailable:
      return "Network is unavailable."
    case let .httpStatus(code):
      return "HTTP error \(code)."
    case let .drmFailed(message):
      return "DRM failed: \(message)"
    case let .engineFailed(engine, message):
      return "Engine \(engine.rawValue) failed: \(message)"
    case .seekFailed:
      return "Seek operation failed."
    case .cancelled:
      return "Operation was cancelled."
    case let .notImplemented(feature):
      return "Not implemented: \(feature)"
    case let .invalidState(message):
      return "Invalid state: \(message)"
    }
  }
}
