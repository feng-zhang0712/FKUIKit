import AVFoundation
import Foundation
import Network

/// Builds `AVURLAsset` instances and performs lightweight reachability checks.
public final class FKMediaNetworkSession: @unchecked Sendable {

  public var configuration: FKMediaNetworkConfiguration
  public weak var resourceLoader: FKMediaResourceLoaderPlugin?
  public weak var offlineProvider: FKMediaOfflinePlaybackProviding?
  public weak var photoAssetResolver: FKMediaPhotoAssetResolver?

  private let monitorQueue = DispatchQueue(label: "com.fkkit.media.network.monitor")
  private var pathMonitor: NWPathMonitor?
  private var isReachable = true

  public init(configuration: FKMediaNetworkConfiguration = .default) {
    self.configuration = configuration
    startMonitoring()
  }

  deinit {
    pathMonitor?.cancel()
  }

  /// Whether the device has a usable network path for remote playback.
  public var hasNetworkPath: Bool {
    isReachable
  }

  /// Creates an `AVURLAsset` with HTTP headers from the media source.
  public func makeAsset(url: URL, headers: [String: String]) -> AVURLAsset {
    var options: [String: Any] = [:]
    if !headers.isEmpty {
      options["AVURLAssetHTTPHeaderFieldsKey"] = headers
    }
    return AVURLAsset(url: url, options: options)
  }

  /// Attempts to build a playable asset, trying fallback URLs on failure.
  public func resolveAsset(for source: FKMediaSource) async throws -> AVURLAsset {
    let resourceLoader = resourceLoader
    switch source {
    case let .asset(asset):
      return asset
    case let .photoAsset(localIdentifier):
      guard let resolver = photoAssetResolver else {
        throw FKMediaError.notImplemented(feature: "photoAsset resolver")
      }
      return try await resolver.resolveAsset(localIdentifier: localIdentifier)
    case let .offline(downloadIdentifier):
      guard let url = offlineProvider?.playbackURL(forDownloadIdentifier: downloadIdentifier) else {
        throw FKMediaError.invalidState("Offline asset not found for id: \(downloadIdentifier)")
      }
      let asset = makeAsset(url: url, headers: [:])
      if !url.isFileURL {
        try await loadPlayable(asset: asset, timeout: configuration.readTimeout)
      }
      return asset
    case let .url(primary, fallbacks, headers):
      guard hasNetworkPath || primary.isFileURL else {
        throw FKMediaError.networkUnavailable
      }

      let candidates = [primary] + fallbacks
      let maxAttempts = max(1, configuration.maxRetryCount)
      var lastError: Error?

      for (index, candidate) in candidates.enumerated() {
        for attempt in 0..<maxAttempts {
          do {
            var resolved = candidate
            if let resourceLoader, !candidate.isFileURL {
              resolved = try await resourceLoader.resolveURL(
                for: FKMediaItem(id: "resolve", source: source),
                currentURL: candidate
              )
            }

            let asset = makeAsset(url: resolved, headers: headers)
            if resolved.isFileURL {
              return asset
            }

            try await loadPlayable(asset: asset, timeout: configuration.readTimeout)
            return asset
          } catch {
            lastError = error
            let hasMoreAttempts = attempt < maxAttempts - 1
            let hasMoreCandidates = index < candidates.count - 1
            guard hasMoreAttempts || hasMoreCandidates else { break }

            let delay = configuration.retryBackoffBase * pow(2.0, Double(attempt + index))
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            if hasMoreAttempts { continue }
            break
          }
        }
      }

      throw FKMediaErrorMapper.map(lastError ?? FKMediaError.networkUnavailable, engine: .avFoundation)
    }
  }

  // MARK: - Private

  private func startMonitoring() {
    let monitor = NWPathMonitor()
    monitor.pathUpdateHandler = { [weak self] path in
      guard let self else { return }
      guard path.status == .satisfied else {
        self.isReachable = false
        return
      }
      if !self.configuration.allowsCellularAccess,
         path.usesInterfaceType(.cellular),
         !path.usesInterfaceType(.wifi),
         !path.usesInterfaceType(.wiredEthernet) {
        self.isReachable = false
        return
      }
      self.isReachable = true
    }
    monitor.start(queue: monitorQueue)
    pathMonitor = monitor
  }

  private func loadPlayable(asset: AVURLAsset, timeout: TimeInterval) async throws {
    try await withLoadTimeout(seconds: timeout) {
      try await self.loadPlayableValues(asset: asset)
    }
  }

  private func loadPlayableValues(asset: AVURLAsset) async throws {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      asset.loadValuesAsynchronously(forKeys: ["playable"]) {
        var error: NSError?
        let status = asset.statusOfValue(forKey: "playable", error: &error)
        switch status {
        case .loaded:
          if asset.isPlayable {
            continuation.resume()
          } else {
            continuation.resume(throwing: FKMediaError.engineFailed(engine: .avFoundation, message: "Asset is not playable"))
          }
        case .failed:
          continuation.resume(throwing: error ?? FKMediaError.networkUnavailable)
        case .cancelled:
          continuation.resume(throwing: FKMediaError.cancelled)
        default:
          continuation.resume(throwing: FKMediaError.engineFailed(engine: .avFoundation, message: "Unknown asset load status"))
        }
      }
    }
  }

  private func withLoadTimeout(
    seconds: TimeInterval,
    operation: @escaping @Sendable () async throws -> Void
  ) async throws {
    guard seconds > 0 else {
      try await operation()
      return
    }

    try await withThrowingTaskGroup(of: Void.self) { group in
      group.addTask { try await operation() }
      group.addTask {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        throw FKMediaError.engineFailed(engine: .avFoundation, message: "Asset load timed out")
      }
      _ = try await group.next()
      group.cancelAll()
    }
  }
}
