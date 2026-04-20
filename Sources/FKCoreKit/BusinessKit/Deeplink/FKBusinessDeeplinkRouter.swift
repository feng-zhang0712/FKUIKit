import Foundation

/// Default implementation of ``FKBusinessDeeplinkRouting``.
public final class FKBusinessDeeplinkRouter: FKBusinessDeeplinkRouting, @unchecked Sendable {
  /// Lock protecting route registry mutations.
  private let lock = NSLock()
  /// Route registry keyed by route identifier.
  private var routes: [String: FKDeeplinkRoute] = [:]

  /// Creates an empty deeplink router.
  public init() {}

  /// Registers or replaces route by its identifier.
  ///
  /// - Parameter route: Route descriptor.
  public func register(_ route: FKDeeplinkRoute) {
    lock.lock()
    routes[route.id] = route
    lock.unlock()
  }

  /// Removes route by identifier.
  ///
  /// - Parameter routeID: Route identifier.
  public func unregister(_ routeID: String) {
    lock.lock()
    routes[routeID] = nil
    lock.unlock()
  }

  /// Attempts to route URL through registered candidates.
  ///
  /// - Parameters:
  ///   - url: Incoming deeplink URL.
  ///   - source: Deeplink source type.
  /// - Returns: `true` when at least one route handled the URL.
  public func route(_ url: URL, source: FKDeeplinkSource) -> Bool {
    let candidates: [FKDeeplinkRoute] = {
      lock.lock()
      let values = Array(routes.values)
      lock.unlock()
      return values
    }()

    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    let host = url.host
    let path = url.path
    let parameters = Self.extractParameters(components: components)
    let context = FKDeeplinkContext(url: url, source: source, parameters: parameters)

    for route in candidates {
      if Self.matches(route: route, host: host, path: path) {
        if route.handler(context) { return true }
      }
    }
    return false
  }

  /// Extracts query parameters from URL components.
  ///
  /// - Parameter components: URL components object.
  /// - Returns: Parameter dictionary.
  private static func extractParameters(components: URLComponents?) -> [String: String] {
    var dict: [String: String] = [:]
    for item in components?.queryItems ?? [] {
      guard let value = item.value else { continue }
      dict[item.name] = value
    }
    return dict
  }

  /// Evaluates whether route matches target host and path.
  ///
  /// - Parameters:
  ///   - route: Route descriptor.
  ///   - host: URL host.
  ///   - path: URL path.
  /// - Returns: `true` when route matches.
  private static func matches(route: FKDeeplinkRoute, host: String?, path: String) -> Bool {
    if let expectedHost = route.host, expectedHost != host { return false }
    if let pattern = route.pathPattern, !matchPath(path, pattern: pattern) { return false }
    return true
  }

  /// Matches path patterns with `*` wildcard segments.
  ///
  /// - Example:
  ///   - Path: `/product/123`
  ///   - Pattern: `/product/*`
  private static func matchPath(_ path: String, pattern: String) -> Bool {
    let p = normalize(path)
    let pat = normalize(pattern)
    if pat == "*" { return true }
    let pSeg = p.split(separator: "/")
    let patSeg = pat.split(separator: "/")
    guard pSeg.count == patSeg.count else { return false }
    for (a, b) in zip(pSeg, patSeg) {
      if b == "*" { continue }
      if a != b { return false }
    }
    return true
  }

  /// Normalizes path string by trimming leading and trailing slash characters.
  ///
  /// - Parameter value: Raw path string.
  /// - Returns: Normalized path string.
  private static func normalize(_ value: String) -> String {
    var v = value
    while v.hasPrefix("/") { v.removeFirst() }
    while v.hasSuffix("/") { v.removeLast() }
    return v
  }
}

