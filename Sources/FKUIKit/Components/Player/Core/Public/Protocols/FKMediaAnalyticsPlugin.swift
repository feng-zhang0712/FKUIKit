import Foundation

/// Observes playback events for QoE or third-party analytics.
public protocol FKMediaAnalyticsPlugin: AnyObject, Sendable {
  func track(event: FKMediaAnalyticsEvent)
}

/// Analytics events emitted by the core.
public enum FKMediaAnalyticsEvent: Sendable, Equatable {
  case loadStarted(itemID: String)
  case ready(itemID: String, engine: FKMediaEngineKind)
  case play(itemID: String)
  case pause(itemID: String)
  case seek(itemID: String, position: TimeInterval)
  case stall(itemID: String)
  case complete(itemID: String)
  case error(itemID: String, error: FKMediaError)
}
