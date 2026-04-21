import UIKit
import FKCoreKit

/// End-to-end interactive demo for FKBusinessKit.
///
/// This screen is intentionally copy-ready:
/// - Each button maps to a production-aligned business scenario
/// - All operations are non-blocking and thread-safe
/// - Both async/await and closure styles are demonstrated
final class FKBusinessKitExampleViewController: UIViewController {
  // MARK: - Dependencies

  private let kit = FKBusinessKit.shared

  // MARK: - Observation Tokens

  private var lifecycleToken: FKBusinessObservationToken?
  private var languageToken: FKBusinessObservationToken?

  // MARK: - UI

  private let scrollView = UIScrollView()
  private let stackView = UIStackView()
  private let outputView = UITextView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKBusinessKit"
    view.backgroundColor = .systemBackground
    buildLayout()
    setupDemoIntegrations()
    appendOutput("FKBusinessKit demo initialized.")
  }

  deinit {
    // Always invalidate tokens to avoid stale callbacks.
    lifecycleToken?.invalidate()
    languageToken?.invalidate()
  }

  // MARK: - Setup

  private func setupDemoIntegrations() {
    // Configure common business context.
    kit.updateConfiguration { config in
      config.channel = "Examples"
      config.defaultLanguageCode = "en"
      config.analyticsFlushInterval = 5
      config.analyticsMaxBatchSize = 10
      config.analyticsMaxRetryCount = 2
    }

    // Plug in a demo uploader to make "flush" observable.
    kit.track.setUploader(DemoAnalyticsUploader(logger: { [weak self] line in
      self?.appendOutput(line)
    }))

    // Provide extra common parameters.
    kit.track.setCommonParametersProvider(DemoAnalyticsCommonParamsProvider())

    // Observe lifecycle transitions (foreground/background).
    lifecycleToken = kit.lifecycle.observe { [weak self] state in
      self?.appendOutput("Lifecycle state: \(state.rawValue)")
      if state == .background {
        // Best practice: flush analytics when entering background.
        self?.kit.track.flush(completion: nil)
      }
    }

    // Observe language changes to refresh UI text.
    languageToken = kit.i18n.observeLanguageChange { [weak self] code in
      self?.appendOutput("Language changed: \(code)")
    }

    // Register a couple of demo routes.
    kit.deeplink.register(
      FKDeeplinkRoute(
        id: "product",
        host: "example.com",
        pathPattern: "/product/*"
      ) { [weak self] context in
        self?.appendOutput("✅ Route matched: product, params=\(context.parameters)")
        return true
      }
    )
    kit.deeplink.register(
      FKDeeplinkRoute(
        id: "promo",
        host: "example.com",
        pathPattern: "/promo/*"
      ) { [weak self] context in
        self?.appendOutput("✅ Route matched: promo, params=\(context.parameters)")
        return true
      }
    )
  }

  private func buildLayout() {
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .vertical
    stackView.spacing = 8

    outputView.translatesAutoresizingMaskIntoConstraints = false
    outputView.isEditable = false
    outputView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    outputView.backgroundColor = .secondarySystemBackground
    outputView.layer.cornerRadius = 8

    let actions: [(String, Selector)] = [
      ("1) App Info (Bundle/Version/Build/Device/OS/Screen)", #selector(demoAppAndDeviceInfo)),
      ("2) Version Check (closure) + Prompt Logic", #selector(demoVersionCheckClosure)),
      ("3) Version Check (async/await) + Prompt Logic", #selector(demoVersionCheckAsync)),
      ("4) Track: Page Exposure + Click + Custom Event", #selector(demoTracking)),
      ("5) Track: Flush Now (closure + async)", #selector(demoTrackingFlush)),
      ("6) I18n: Switch Language + Localized String", #selector(demoI18n)),
      ("7) Lifecycle: Show Current State", #selector(demoLifecycleState)),
      ("8) Deeplink/Universal Link: Parse + Route", #selector(demoDeeplinkRouting)),
      ("9) Business Utils: Time + Number Formatting", #selector(demoFormatters)),
      ("10) Masking: Phone / ID / Email", #selector(demoMasking)),
      ("11) Alert Manager: Present Once (De-dup)", #selector(demoAlertOnce)),
      ("12) Startup Tasks: Priority + Delay (async)", #selector(demoStartupTasks)),
      ("Clear On-screen Output", #selector(clearOutput)),
    ]

    for (title, selector) in actions {
      let button = UIButton(type: .system)
      button.setTitle(title, for: .normal)
      button.contentHorizontalAlignment = .left
      button.addTarget(self, action: selector, for: .touchUpInside)
      stackView.addArrangedSubview(button)
    }

    view.addSubview(scrollView)
    scrollView.addSubview(stackView)
    view.addSubview(outputView)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      scrollView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.52),

      stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
      stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
      stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
      stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

      outputView.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 8),
      outputView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      outputView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      outputView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])
  }

  // MARK: - 1) App & Device Info

  @objc private func demoAppAndDeviceInfo() {
    let meta = kit.version.appMetadata()
    appendOutput("BundleID: \(kit.info.bundleID)")
    appendOutput("App version: \(kit.info.appVersion) (metadata=\(meta.version))")
    appendOutput("Build: \(kit.info.buildNumber) (metadata=\(meta.build))")
    appendOutput("Environment: \(kit.info.environment.rawValue)")
    appendOutput("Channel: \(kit.info.channel)")
    appendOutput("Device model: \(kit.info.deviceModelIdentifier)")
    appendOutput("System version: iOS \(kit.info.systemVersion)")
    appendOutput("Screen size: \(Int(kit.info.screenSize.width))x\(Int(kit.info.screenSize.height))")
  }

  // MARK: - 2) Version Check (Closure)

  /// Demonstrates version comparison and prompt logic using closure callbacks.
  @objc private func demoVersionCheckClosure() {
    let provider = DemoRemoteVersionProvider(mode: .optionalUpdate)
    appendOutput("➡️ Version check (closure) started.")

    kit.version.checkForUpdate(using: provider) { [weak self] result in
      guard let self else { return }
      switch result {
      case let .success(check):
        self.appendOutput("✅ Version check result: \(check.decision)")
        self.kit.version.presentUpdatePromptIfNeeded(result: check, presenter: self)
      case let .failure(error):
        self.appendOutput("❌ Version check failed: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - 3) Version Check (Async/Await)

  /// Demonstrates version comparison and prompt logic using async/await.
  @objc private func demoVersionCheckAsync() {
    appendOutput("➡️ Version check (async/await) started.")
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        // Toggle between `.forceUpdate` and `.optionalUpdate` to verify prompt behavior.
        let provider = DemoRemoteVersionProvider(mode: .forceUpdate)
        let check = try await self.kit.version.checkForUpdate(using: provider)
        self.appendOutput("✅ Version check result: \(check.decision)")
        self.kit.version.presentUpdatePromptIfNeeded(result: check, presenter: self)
      } catch let error as FKBusinessError {
        self.appendOutput("❌ Version check failed: \(error.localizedDescription)")
      } catch {
        self.appendOutput("❌ Version check failed: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - 4) Global Event Tracking

  @objc private func demoTracking() {
    // All tracking APIs are non-blocking and safe to call from any thread.
    kit.track.trackPageView("Home", parameters: ["source": "tab"])
    kit.track.trackClick("BuyButton", page: "Product", parameters: ["sku": "123"])
    kit.track.trackEvent("checkout_submit", parameters: ["step": "pay"])
    appendOutput("✅ Track events queued (page/click/custom).")
  }

  // MARK: - 5) Tracking Flush

  @objc private func demoTrackingFlush() {
    appendOutput("➡️ Flush analytics (closure) started.")
    kit.track.flush { [weak self] in
      self?.appendOutput("✅ Flush (closure) completed.")
    }

    appendOutput("➡️ Flush analytics (async) started.")
    Task { [weak self] in
      await self?.kit.track.flush()
      self?.appendOutput("✅ Flush (async) completed.")
    }
  }

  // MARK: - 6) Multi-language I18n

  @objc private func demoI18n() {
    let current = kit.i18n.currentLanguageCode
    let next = current.lowercased().hasPrefix("zh") ? "en" : "zh-Hans"
    kit.i18n.setLanguageCode(next)

    // If Localizable.strings is missing, iOS returns the key itself; this is still runnable.
    let key = "businesskit_demo_title"
    let localized = kit.i18n.localized(key, table: nil)
    appendOutput("Localized string for \"\(key)\": \(localized)")
    appendOutput("Tip: add `en.lproj/Localizable.strings` and `zh-Hans.lproj/Localizable.strings` to see real translations.")
  }

  // MARK: - 7) Lifecycle

  @objc private func demoLifecycleState() {
    appendOutput("Current lifecycle state: \(kit.lifecycle.state.rawValue)")
  }

  // MARK: - 8) Deeplink / Universal Link

  @objc private func demoDeeplinkRouting() {
    let urls: [URL] = [
      URL(string: "https://example.com/product/123?ref=ad&from=universalLink")!,
      URL(string: "https://example.com/promo/spring?coupon=OFF10")!,
      URL(string: "https://example.com/unknown/path?a=1")!,
    ]

    for url in urls {
      let handled = kit.deeplink.route(url, source: .universalLink)
      appendOutput("Route \(url.absoluteString) -> handled=\(handled)")
    }
  }

  // MARK: - 9) Business Formatters

  @objc private func demoFormatters() {
    let now = Date()
    let earlier = now.addingTimeInterval(-135)
    let relative = kit.utils.time.relativeDescription(from: earlier, now: now)
    appendOutput("Relative time: \(relative)")

    let fixed = kit.utils.time.format(date: now, format: "yyyy-MM-dd HH:mm:ss", locale: nil)
    appendOutput("Formatted time: \(fixed)")

    let amount = kit.utils.number.formatAmount(Decimal(string: "1234567.89") ?? 0, fractionDigits: 2)
    appendOutput("Amount: \(amount)")

    let compact = kit.utils.number.formatCompact(12_345_678, fractionDigits: 1)
    appendOutput("Compact number: \(compact)")
  }

  // MARK: - 10) Masking

  @objc private func demoMasking() {
    let phone = kit.utils.mask.maskPhone("13800138000")
    let id = kit.utils.mask.maskIDCard("110101199001011234")
    let email = kit.utils.mask.maskEmail("name@example.com")
    appendOutput("Mask phone: \(phone)")
    appendOutput("Mask ID: \(id)")
    appendOutput("Mask email: \(email)")
  }

  // MARK: - 11) Alert De-duplication

  @objc private func demoAlertOnce() {
    kit.utils.alerts.presentOnce(
      id: "businesskit_demo_alert",
      title: "One-time Alert",
      message: "This alert is de-duplicated by id. Tap the button again to verify it won't show twice simultaneously.",
      actions: [
        FKAlertAction(title: "OK", style: .default, handler: nil),
      ],
      presenter: self
    )
  }

  // MARK: - 12) Startup Tasks

  @objc private func demoStartupTasks() {
    // Register a couple of tasks to simulate launch optimization patterns.
    kit.utils.startup.register(
      FKStartupTask(id: "startup_high", priority: .high, delay: 0) { [weak self] in
        self?.appendOutput("✅ Startup task HIGH executed.")
      }
    )
    kit.utils.startup.register(
      FKStartupTask(id: "startup_low_delayed", priority: .low, delay: 1.0) { [weak self] in
        self?.appendOutput("✅ Startup task LOW (delayed) executed.")
      }
    )

    appendOutput("➡️ Running startup tasks (async).")
    Task { [weak self] in
      await self?.kit.utils.startup.runAll()
      self?.appendOutput("✅ Startup tasks finished.")
    }
  }

  // MARK: - Helpers

  @objc private func clearOutput() {
    outputView.text = ""
    appendOutput("On-screen output cleared.")
  }

  /// Appends one line into the on-screen log.
  ///
  /// This helper is thread-safe: callers may invoke it from any queue.
  private nonisolated func appendOutput(_ message: String) {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let line = "[\(DateFormatter.businessDemoFormatter.string(from: Date()))] \(message)\n"
      self.outputView.text.append(line)
      let range = NSRange(location: max(self.outputView.text.count - 1, 0), length: 1)
      self.outputView.scrollRangeToVisible(range)
    }
  }
}

// MARK: - Demo Collaborators

/// Demo remote version provider that simulates a backend response.
private final class DemoRemoteVersionProvider: FKRemoteVersionProviding {
  enum Mode {
    case upToDate
    case optionalUpdate
    case forceUpdate
  }

  private let mode: Mode

  init(mode: Mode) {
    self.mode = mode
  }

  @available(iOS 13.0, *)
  func fetchRemoteVersion() async throws -> FKRemoteVersionInfo {
    // Simulate network latency without blocking the main thread.
    try await Task.sleep(nanoseconds: 250_000_000)

    switch mode {
    case .upToDate:
      return FKRemoteVersionInfo(
        version: FKBusinessKit.shared.info.appVersion,
        releaseNotes: "You are up to date.",
        updateURL: URL(string: "https://apps.apple.com")
      )
    case .optionalUpdate:
      return FKRemoteVersionInfo(
        version: "99.0.0",
        releaseNotes: "Optional update: new features and improvements.",
        updateURL: URL(string: "https://apps.apple.com"),
        isForceUpdate: false
      )
    case .forceUpdate:
      return FKRemoteVersionInfo(
        version: "99.0.0",
        releaseNotes: "Forced update: critical fixes are required.",
        updateURL: URL(string: "https://apps.apple.com"),
        isForceUpdate: true
      )
    }
  }
}

/// Demo analytics common parameters provider.
private final class DemoAnalyticsCommonParamsProvider: FKAnalyticsCommonParametersProviding {
  func commonParameters() -> [String: String] {
    [
      "user_id": "1001",
      "region": "US",
      "source": "FKBusinessKitExample",
    ]
  }
}

/// Demo uploader that randomly fails to showcase retry behavior.
private final class DemoAnalyticsUploader: FKAnalyticsUploading {
  /// Async-safe counter used to simulate intermittent upload failures.
  private actor CallCounter {
    private var value = 0

    func increment() -> Int {
      value += 1
      return value
    }
  }

  private let logger: (String) -> Void
  private let counter = CallCounter()

  init(logger: @escaping (String) -> Void) {
    self.logger = logger
  }

  @available(iOS 13.0, *)
  func upload(batch: [FKAnalyticsEvent]) async throws {
    // Simulate I/O latency.
    try await Task.sleep(nanoseconds: 200_000_000)

    let current = await counter.increment()

    // Fail every 3rd call to demonstrate retry + drop behavior.
    if current % 3 == 0 {
      logger("⚠️ Demo uploader: simulated failure for batch size=\(batch.count)")
      throw NSError(domain: "demo.analytics", code: -1, userInfo: [NSLocalizedDescriptionKey: "Simulated upload failure"])
    }

    logger("✅ Demo uploader: uploaded batch size=\(batch.count)")
  }
}

private extension DateFormatter {
  static let businessDemoFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return formatter
  }()
}

