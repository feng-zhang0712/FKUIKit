import UIKit
import FKCoreKit

/// End-to-end interactive demo for FKLogger.
/// Each action is organized by feature block for copy-ready usage.
final class FKLoggerExampleViewController: UIViewController {
  // MARK: - UI

  private let scrollView = UIScrollView()
  private let stackView = UIStackView()
  private let outputView = UITextView()

  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKLogger"
    view.backgroundColor = .systemBackground
    buildLayout()
    appendOutput("FKLogger example loaded.")
  }

  // MARK: - Layout

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
      ("1) 5 Level Log Printing", #selector(demoLogLevels)),
      ("2) Basic Global Configuration", #selector(demoBasicGlobalConfiguration)),
      ("3) Print Model / Array / Dictionary", #selector(demoDumpComplexData)),
      ("4) File Logging Enable & Management", #selector(demoFileLogging)),
      ("5) Custom Log Format", #selector(demoCustomLogFormat)),
      ("6) Environment Control (Debug/Release)", #selector(demoEnvironmentControl)),
      ("7) Crash Log Capture", #selector(demoCrashCapture)),
      ("8) Clear & Export Logs", #selector(demoClearAndExportLogs)),
      ("Clear Persisted Logs", #selector(clearPersistedLogs)),
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
      scrollView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.5),

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

  // MARK: - 1) 5 Level Log Printing

  @objc private func demoLogLevels() {
    FKLogV("Verbose sample from logger demo", metadata: ["scene": "level_demo"])
    FKLogD("Debug sample from logger demo", metadata: ["scene": "level_demo"])
    FKLogI("Info sample from logger demo", metadata: ["scene": "level_demo"])
    FKLogW("Warning sample from logger demo", metadata: ["scene": "level_demo"])
    FKLogE("Error sample from logger demo", metadata: ["scene": "level_demo"])
    appendOutput("Printed all 5 levels.")
  }

  // MARK: - 2) Basic Global Configuration

  @objc private func demoBasicGlobalConfiguration() {
    FKLogger.shared.updateConfig { config in
      // Keep config minimal and practical for most apps.
      config.isEnabled = true
      config.enabledLevels = Set(FKLogLevel.allCases)
      config.prefix = "[FKLoggerDemo]"
      config.includesTimestamp = true
      config.includesFileName = true
      config.includesFunctionName = true
      config.includesLineNumber = true
      config.usesColorizedConsole = true
      config.usesEmoji = true
    }
    FKLogI("Basic global configuration applied.")
    appendOutput("Applied basic global configuration.")
  }

  // MARK: - 3) Print Model / Array / Dictionary

  @objc private func demoDumpComplexData() {
    let model = DemoUser(id: 101, name: "Frank", tags: ["iOS", "Swift", "OpenSource"])
    let array = ["alpha", "beta", "gamma"]
    let dictionary: [String: Any] = [
      "feature": "logger",
      "enabled": true,
      "retry": 2,
      "roles": ["owner", "maintainer"],
    ]

    FKLogger.shared.dumpEncodable(model, level: .debug)
    FKLogger.shared.dumpValue(array, level: .debug)
    FKLogger.shared.dumpValue(dictionary, level: .debug)
    appendOutput("Dumped model, array, and dictionary.")
  }

  // MARK: - 4) File Logging Enable & Management

  @objc private func demoFileLogging() {
    FKLogger.shared.updateConfig { config in
      config.persistsToFile = true
      config.rotatesDaily = true
      config.maxFileSizeInBytes = 2 * 1024 * 1024
      config.maxStorageSizeInBytes = 20 * 1024 * 1024
    }

    FKLogI("File logging enabled.")
    let files = FKLogger.shared.allLogFiles()
    appendOutput("File logging enabled. Current log files: \(files.count)")
    files.forEach { appendOutput(" - \($0.lastPathComponent)") }
  }

  // MARK: - 5) Custom Log Format

  @objc private func demoCustomLogFormat() {
    FKLogger.shared.updateConfig { config in
      // Demonstrate a cleaner compact format.
      config.prefix = "[Checkout]"
      config.includesTimestamp = true
      config.includesFileName = false
      config.includesFunctionName = false
      config.includesLineNumber = false
      config.usesEmoji = true
      config.usesColorizedConsole = true
    }
    FKLogI("Custom compact format activated.", metadata: ["module": "payment"])
    appendOutput("Applied custom format (prefix and source fields adjusted).")
  }

  // MARK: - 6) Environment Control (Debug/Release)

  @objc private func demoEnvironmentControl() {
    #if DEBUG
    FKLogI("Current build: DEBUG. Logging is enabled by default.")
    appendOutput("Environment = DEBUG (default logger is active).")
    #else
    FKLogI("Current build: RELEASE. This line is usually disabled by default config.")
    appendOutput("Environment = RELEASE (default logger is disabled).")
    #endif
  }

  // MARK: - 7) Crash Log Capture

  @objc private func demoCrashCapture() {
    // Install once during app startup in real apps.
    FKLogger.shared.installCrashCapture()

    // Record a custom exception-like event without crashing the app.
    FKLogger.shared.captureException(
      name: "DemoBusinessError",
      reason: "Order amount is invalid",
      metadata: ["module": "checkout", "action": "submit_order"]
    )

    // Record one network diagnostic event.
    var request = URLRequest(url: URL(string: "https://api.example.com/orders")!)
    request.httpMethod = "POST"
    let response = HTTPURLResponse(
      url: request.url!,
      statusCode: 500,
      httpVersion: "HTTP/1.1",
      headerFields: nil
    )
    FKLogger.shared.captureNetwork(
      request: request,
      response: response,
      data: Data("server error".utf8),
      error: NSError(domain: "demo.network", code: 500)
    )

    appendOutput("Crash capture installed and custom crash/network logs recorded.")
  }

  // MARK: - 8) Clear & Export Logs

  @objc private func demoClearAndExportLogs() {
    guard let exportURL = FKLogger.shared.exportLogArchive() else {
      appendOutput("No log archive to export.")
      return
    }

    let activity = UIActivityViewController(activityItems: [exportURL], applicationActivities: nil)
    if let popover = activity.popoverPresentationController {
      popover.sourceView = view
      popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
    }
    present(activity, animated: true)
    appendOutput("Prepared log archive for sharing: \(exportURL.lastPathComponent)")
  }

  @objc private func clearOutput() {
    outputView.text = ""
    appendOutput("On-screen output cleared.")
  }

  @objc private func clearPersistedLogs() {
    FKLogger.shared.clearLogFiles()
    appendOutput("Persisted log files clear request submitted.")
  }

  // MARK: - Utility

  /// Appends one line into the on-screen output view.
  /// This helper keeps all UIKit operations on the main actor.
  private nonisolated func appendOutput(_ message: String) {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let line = "[\(DateFormatter.loggerDemoFormatter.string(from: Date()))] \(message)\n"
      self.outputView.text.append(line)
      let range = NSRange(location: max(self.outputView.text.count - 1, 0), length: 1)
      self.outputView.scrollRangeToVisible(range)
    }
  }
}

private struct DemoUser: Encodable {
  let id: Int
  let name: String
  let tags: [String]
}

private extension DateFormatter {
  /// Shared formatter for compact demo timestamps.
  static let loggerDemoFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return formatter
  }()
}
