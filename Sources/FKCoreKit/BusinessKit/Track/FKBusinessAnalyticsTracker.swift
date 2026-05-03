import Foundation

private final class FKAnalyticsCommonParametersProviderBox: @unchecked Sendable {
  let value: (any FKAnalyticsCommonParametersProviding)?
  init(_ value: (any FKAnalyticsCommonParametersProviding)?) { self.value = value }
}

private final class FKAnalyticsUploaderBox: @unchecked Sendable {
  let value: (any FKAnalyticsUploading)?
  init(_ value: (any FKAnalyticsUploading)?) { self.value = value }
}

/// Default implementation of ``FKBusinessTracking`` with file-backed buffering and batched uploads.
public final class FKBusinessAnalyticsTracker: FKBusinessTracking, @unchecked Sendable {
  /// Supplies runtime analytics configuration values.
  private let configurationProvider: @Sendable () -> FKBusinessKitConfiguration
  /// Supplies app/device fields for common event parameters.
  private let infoProvider: FKBusinessInfoProviding

  /// Serial queue used to protect tracker state and persistence operations.
  private let queue = DispatchQueue(label: "com.fkkit.business.analytics", qos: .utility)
  /// Persistent event store.
  private let store: FKAnalyticsEventStoring

  /// Optional provider for extra common parameters.
  private var commonProvider: FKAnalyticsCommonParametersProviding?
  /// Optional batch uploader.
  private var uploader: FKAnalyticsUploading?
  /// Periodic flush timer.
  private var timer: DispatchSourceTimer?
  /// Indicates whether a flush task is currently running.
  private var isFlushing = false

  /// Creates an analytics tracker with default file-backed buffering.
  ///
  /// - Parameters:
  ///   - configurationProvider: Supplies runtime configuration (batch size, retry, interval).
  ///   - infoProvider: Supplies app/device info for common parameter injection.
  public init(
    configurationProvider: @escaping @Sendable () -> FKBusinessKitConfiguration,
    infoProvider: FKBusinessInfoProviding
  ) {
    self.configurationProvider = configurationProvider
    self.infoProvider = infoProvider
    store = FKAnalyticsFileStore(appID: infoProvider.bundleID)
  }

  /// Internal initializer for tests or custom buffering strategies.
  ///
  /// - Parameters:
  ///   - configurationProvider: Configuration provider.
  ///   - infoProvider: App/device info provider.
  ///   - store: Event store implementation.
  init(
    configurationProvider: @escaping @Sendable () -> FKBusinessKitConfiguration,
    infoProvider: FKBusinessInfoProviding,
    store: FKAnalyticsEventStoring
  ) {
    self.configurationProvider = configurationProvider
    self.infoProvider = infoProvider
    self.store = store
  }

  /// Installs or removes additional common parameters provider.
  public func setCommonParametersProvider(_ provider: FKAnalyticsCommonParametersProviding?) {
    let box = FKAnalyticsCommonParametersProviderBox(provider)
    queue.async { [weak self] in
      self?.commonProvider = box.value
    }
  }

  /// Installs or removes batch uploader.
  public func setUploader(_ uploader: FKAnalyticsUploading?) {
    let box = FKAnalyticsUploaderBox(uploader)
    queue.async { [weak self] in
      self?.uploader = box.value
    }
  }

  /// Enqueues a page-view event.
  public func trackPageView(_ page: String, parameters: [String: String]?) {
    enqueue(type: .pageView, name: page, parameters: parameters)
  }

  /// Enqueues a click event.
  public func trackClick(_ element: String, page: String?, parameters: [String: String]?) {
    var params = parameters ?? [:]
    if let page { params["page"] = page }
    enqueue(type: .click, name: element, parameters: params)
  }

  /// Enqueues a custom analytics event.
  public func trackEvent(_ name: String, parameters: [String: String]?) {
    enqueue(type: .custom, name: name, parameters: parameters)
  }

  /// Async wrapper for event flush.
  @available(iOS 13.0, *)
  public func flush() async {
    await withCheckedContinuation { cont in
      flush(completion: cont.resume)
    }
  }

  /// Flushes buffered analytics events immediately.
  ///
  /// - Parameter completion: Completion callback called when flush ends or is skipped.
  public func flush(completion: (@Sendable () -> Void)?) {
    queue.async { [weak self] in
      guard let self else { completion?(); return }
      self.flushLocked(completion: completion)
    }
  }

  /// Creates and stores one event record asynchronously.
  ///
  /// - Parameters:
  ///   - type: Event type.
  ///   - name: Event name.
  ///   - parameters: Event parameters.
  private func enqueue(type: FKAnalyticsEventType, name: String, parameters: [String: String]?) {
    queue.async { [weak self] in
      guard let self else { return }
      let merged = self.mergeCommonParameters(parameters ?? [:])
      let event = FKAnalyticsEvent(type: type, name: name, parameters: merged)
      self.store.append(event: event)

      self.ensureTimer()

      let config = self.configurationProvider()
      if self.store.count >= config.analyticsMaxBatchSize {
        self.flushLocked(completion: nil)
      }
    }
  }

  /// Merges global common parameters with per-event input values.
  ///
  /// - Parameter input: Event-specific parameters.
  /// - Returns: Merged parameter dictionary.
  private func mergeCommonParameters(_ input: [String: String]) -> [String: String] {
    var params = input
    params["bundle_id"] = infoProvider.bundleID
    params["app_version"] = infoProvider.appVersion
    params["build"] = infoProvider.buildNumber
    params["os"] = "iOS"
    params["os_version"] = infoProvider.systemVersion
    params["device_model"] = infoProvider.deviceModelIdentifier
    params["channel"] = infoProvider.channel
    params["env"] = infoProvider.environment.rawValue
    if let extra = commonProvider?.commonParameters() {
      for (k, v) in extra where params[k] == nil {
        params[k] = v
      }
    }
    return params
  }

  /// Ensures periodic flush timer is created once.
  private func ensureTimer() {
    guard timer == nil else { return }
    let t = DispatchSource.makeTimerSource(queue: queue)
    let interval = max(3, configurationProvider().analyticsFlushInterval)
    t.schedule(deadline: .now() + interval, repeating: interval)
    t.setEventHandler { [weak self] in
      self?.flushLocked(completion: nil)
    }
    t.resume()
    timer = t
  }

  /// Executes one flush cycle on current buffer state.
  ///
  /// - Parameter completion: Completion callback for this flush attempt.
  private func flushLocked(completion: (@Sendable () -> Void)?) {
    guard !isFlushing else { completion?(); return }
    guard let uploader else { completion?(); return }
    guard store.count > 0 else { completion?(); return }
    isFlushing = true

    let config = configurationProvider()
    let batch = store.peek(max: config.analyticsMaxBatchSize)

    Task(priority: .utility) { [weak self] in
      guard let self else { return }
      do {
        try await uploader.upload(batch: batch)
        self.queue.async {
          self.store.removeFirst(batch.count)
          self.isFlushing = false
          completion?()
        }
      } catch {
        self.queue.async {
          self.store.incrementRetry(for: batch.map(\.id))
          self.store.dropExceededRetry(maxRetry: config.analyticsMaxRetryCount)
          self.isFlushing = false
          completion?()
        }
      }
    }
  }
}

// MARK: - Storage

protocol FKAnalyticsEventStoring: AnyObject {
  /// Number of currently buffered events.
  var count: Int { get }
  /// Appends one event record.
  func append(event: FKAnalyticsEvent)
  /// Reads up to `max` events from the queue head.
  func peek(max: Int) -> [FKAnalyticsEvent]
  /// Removes first `n` events.
  func removeFirst(_ n: Int)
  /// Increments retry counters for specified event identifiers.
  func incrementRetry(for eventIDs: [String])
  /// Drops events whose retry count exceeds threshold.
  func dropExceededRetry(maxRetry: Int)
}

/// File-backed FIFO store for analytics events.
final class FKAnalyticsFileStore: FKAnalyticsEventStoring {
  /// On-disk event record format with retry metadata.
  private struct Record: Codable {
    /// Serialized analytics event payload.
    var event: FKAnalyticsEvent
    /// Current retry count for this event.
    var retryCount: Int
  }

  /// Lock protecting all record mutations and persistence.
  private let lock = NSLock()
  /// File location for serialized event records.
  private let fileURL: URL
  /// In-memory FIFO event records.
  private var records: [Record] = []

  /// Creates file-backed store in caches directory.
  ///
  /// - Parameter appID: Application identifier used in filename.
  init(appID: String) {
    let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    let base = dir.appendingPathComponent("FKBusinessKit", isDirectory: true)
    try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
    fileURL = base.appendingPathComponent("analytics-\(Self.sanitize(appID)).json")
    loadFromDisk()
  }

  /// Current buffered record count.
  var count: Int {
    lock.lock()
    let c = records.count
    lock.unlock()
    return c
  }

  /// Appends an event and persists updated buffer.
  func append(event: FKAnalyticsEvent) {
    lock.lock()
    records.append(Record(event: event, retryCount: 0))
    persistLocked()
    lock.unlock()
  }

  /// Returns first `max` events without removing them.
  func peek(max: Int) -> [FKAnalyticsEvent] {
    lock.lock()
    let slice = records.prefix(max).map(\.event)
    lock.unlock()
    return slice
  }

  /// Removes first `n` records and persists buffer.
  func removeFirst(_ n: Int) {
    lock.lock()
    if n >= records.count {
      records.removeAll()
    } else if n > 0 {
      records.removeFirst(n)
    }
    persistLocked()
    lock.unlock()
  }

  /// Increments retry count for matching event identifiers.
  func incrementRetry(for eventIDs: [String]) {
    guard !eventIDs.isEmpty else { return }
    let set = Set(eventIDs)
    lock.lock()
    for i in records.indices {
      if set.contains(records[i].event.id) {
        records[i].retryCount += 1
      }
    }
    persistLocked()
    lock.unlock()
  }

  /// Removes records that exceeded retry threshold.
  func dropExceededRetry(maxRetry: Int) {
    lock.lock()
    if maxRetry >= 0 {
      records.removeAll { $0.retryCount > maxRetry }
    }
    persistLocked()
    lock.unlock()
  }

  /// Loads persisted records from disk into memory.
  private func loadFromDisk() {
    lock.lock()
    defer { lock.unlock() }
    guard let data = try? Data(contentsOf: fileURL) else { return }
    if let decoded = try? JSONDecoder().decode([Record].self, from: data) {
      records = decoded
    }
  }

  /// Persists current in-memory records to disk.
  private func persistLocked() {
    let data = try? JSONEncoder().encode(records)
    try? data?.write(to: fileURL, options: [.atomic])
  }

  /// Sanitizes filename components for file-system safety.
  ///
  /// - Parameter input: Raw app identifier.
  /// - Returns: Sanitized filename segment.
  private static func sanitize(_ input: String) -> String {
    input.replacingOccurrences(of: "/", with: "_")
  }
}

