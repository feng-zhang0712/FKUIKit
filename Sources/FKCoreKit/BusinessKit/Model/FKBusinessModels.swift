import Foundation
import UIKit

// MARK: - Version

/// Current app metadata extracted from the main bundle.
public struct FKAppMetadata: Sendable, Equatable {
  /// Application bundle identifier.
  public let bundleID: String
  /// Application marketing version.
  public let version: String
  /// Application build number.
  public let build: String

  /// Creates app metadata.
  ///
  /// - Parameters:
  ///   - bundleID: Application bundle identifier.
  ///   - version: Application marketing version.
  ///   - build: Application build number.
  public init(bundleID: String, version: String, build: String) {
    self.bundleID = bundleID
    self.version = version
    self.build = build
  }
}

/// Remote version information used for update decisions.
public struct FKRemoteVersionInfo: Sendable, Equatable {
  /// Remote marketing version.
  public let version: String
  /// Optional remote build number.
  public let build: String?
  /// Optional release notes for user display.
  public let releaseNotes: String?
  /// Optional destination URL for update action.
  public let updateURL: URL?
  /// Whether the update is mandatory.
  public let isForceUpdate: Bool

  /// Creates remote version information.
  ///
  /// - Parameters:
  ///   - version: Remote marketing version.
  ///   - build: Optional remote build number.
  ///   - releaseNotes: Optional release notes.
  ///   - updateURL: Optional update destination URL.
  ///   - isForceUpdate: Whether update is mandatory.
  public init(
    version: String,
    build: String? = nil,
    releaseNotes: String? = nil,
    updateURL: URL? = nil,
    isForceUpdate: Bool = false
  ) {
    self.version = version
    self.build = build
    self.releaseNotes = releaseNotes
    self.updateURL = updateURL
    self.isForceUpdate = isForceUpdate
  }
}

/// Version check result.
public struct FKVersionCheckResult: Sendable, Equatable {
  /// Local app metadata.
  public let local: FKAppMetadata
  /// Remote version metadata.
  public let remote: FKRemoteVersionInfo
  /// Computed update decision.
  public let decision: FKUpdateDecision

  /// Creates a version check result.
  ///
  /// - Parameters:
  ///   - local: Local app metadata.
  ///   - remote: Remote version metadata.
  ///   - decision: Computed update decision.
  public init(local: FKAppMetadata, remote: FKRemoteVersionInfo, decision: FKUpdateDecision) {
    self.local = local
    self.remote = remote
    self.decision = decision
  }
}

/// Update decision derived from local and remote versions.
public enum FKUpdateDecision: Sendable, Equatable {
  /// No update is needed.
  case upToDate

  /// Update is available but optional.
  case optionalUpdate

  /// Update is required before continuing.
  case forceUpdate
}

// MARK: - Analytics

/// Analytics event type.
public enum FKAnalyticsEventType: String, Sendable, Equatable, Codable {
  /// Page exposure event.
  case pageView
  /// Click interaction event.
  case click
  /// Developer-defined custom event.
  case custom
}

/// A single analytics event record.
public struct FKAnalyticsEvent: Sendable, Equatable, Codable {
  /// Unique event identifier.
  public let id: String
  /// Event classification.
  public let type: FKAnalyticsEventType
  /// Event logical name.
  public let name: String
  /// Event timestamp in seconds since 1970.
  public let timestamp: TimeInterval
  /// Event parameter dictionary.
  public let parameters: [String: String]

  /// Creates an analytics event.
  ///
  /// - Parameters:
  ///   - id: Unique event identifier.
  ///   - type: Event type.
  ///   - name: Event logical name.
  ///   - timestamp: Event timestamp.
  ///   - parameters: Event parameter dictionary.
  public init(
    id: String = UUID().uuidString,
    type: FKAnalyticsEventType,
    name: String,
    timestamp: TimeInterval = Date().timeIntervalSince1970,
    parameters: [String: String]
  ) {
    self.id = id
    self.type = type
    self.name = name
    self.timestamp = timestamp
    self.parameters = parameters
  }
}

// MARK: - Lifecycle

/// Simplified application lifecycle state.
public enum FKAppLifecycleState: String, Sendable, Equatable {
  /// App process is not running.
  case notRunning
  /// App is launching.
  case launching
  /// App is active in foreground.
  case active
  /// App is inactive (transitional or interrupted).
  case inactive
  /// App entered background.
  case background
  /// App is terminating.
  case terminated
}

// MARK: - Deeplink

/// Deeplink source type.
public enum FKDeeplinkSource: Sendable, Equatable {
  /// Opened via custom URL scheme.
  case deeplink
  /// Opened via universal link.
  case universalLink
  /// Opened via handoff activity.
  case handoff
  /// Unknown source.
  case unknown
}

/// Deeplink route handler.
public typealias FKDeeplinkHandler = @Sendable (_ context: FKDeeplinkContext) -> Bool

/// Deeplink routing context.
public struct FKDeeplinkContext: Sendable, Equatable {
  /// Original routed URL.
  public let url: URL
  /// Source type of this deeplink.
  public let source: FKDeeplinkSource
  /// Parsed URL query parameters.
  public let parameters: [String: String]

  /// Creates deeplink context.
  ///
  /// - Parameters:
  ///   - url: Original URL.
  ///   - source: Deeplink source type.
  ///   - parameters: Parsed query parameters.
  public init(url: URL, source: FKDeeplinkSource, parameters: [String: String]) {
    self.url = url
    self.source = source
    self.parameters = parameters
  }
}

/// A route registration.
public struct FKDeeplinkRoute: Sendable {
  /// A stable identifier for unregistering.
  public let id: String

  /// URL host to match. When `nil`, matches any host.
  public let host: String?

  /// URL path pattern (supports `*` wildcard segments).
  public let pathPattern: String?

  /// Handler invoked when the route matches.
  public let handler: FKDeeplinkHandler

  /// Creates route registration.
  ///
  /// - Parameters:
  ///   - id: Stable route identifier.
  ///   - host: Optional host to match.
  ///   - pathPattern: Optional path pattern to match.
  ///   - handler: Route handler closure.
  public init(
    id: String,
    host: String? = nil,
    pathPattern: String? = nil,
    handler: @escaping FKDeeplinkHandler
  ) {
    self.id = id
    self.host = host
    self.pathPattern = pathPattern
    self.handler = handler
  }
}

// MARK: - Alerts

/// Alert action descriptor.
public struct FKAlertAction: Sendable {
  /// Alert action style.
  public enum Style: Sendable, Equatable {
    /// Standard action style.
    case `default`
    /// Cancel action style.
    case cancel
    /// Destructive action style.
    case destructive
  }

  /// Action button title.
  public let title: String
  /// Action button style.
  public let style: Style
  /// Optional callback executed after action tap.
  public let handler: (@Sendable () -> Void)?

  /// Creates an alert action descriptor.
  ///
  /// - Parameters:
  ///   - title: Action title.
  ///   - style: Action style.
  ///   - handler: Optional action callback.
  public init(title: String, style: Style = .default, handler: (@Sendable () -> Void)? = nil) {
    self.title = title
    self.style = style
    self.handler = handler
  }
}

// MARK: - Startup

/// Startup task priority.
public enum FKStartupTaskPriority: Int, Sendable, Equatable, Comparable {
  /// Highest priority, executed first.
  case high = 0
  /// Default priority.
  case normal = 1
  /// Lowest priority, usually non-critical tasks.
  case low = 2

  /// Compares priority order where smaller raw value means higher priority.
  public static func < (lhs: FKStartupTaskPriority, rhs: FKStartupTaskPriority) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}

/// A startup task to be executed.
public struct FKStartupTask: Sendable {
  /// Stable task identifier.
  public let id: String
  /// Task priority.
  public let priority: FKStartupTaskPriority
  /// Delay before task execution in seconds.
  public let delay: TimeInterval
  /// Async task body.
  public let work: @Sendable () async -> Void

  /// Creates startup task descriptor.
  ///
  /// - Parameters:
  ///   - id: Stable task identifier.
  ///   - priority: Task priority.
  ///   - delay: Delay before execution.
  ///   - work: Async task body.
  public init(
    id: String,
    priority: FKStartupTaskPriority = .normal,
    delay: TimeInterval = 0,
    work: @escaping @Sendable () async -> Void
  ) {
    self.id = id
    self.priority = priority
    self.delay = delay
    self.work = work
  }
}

