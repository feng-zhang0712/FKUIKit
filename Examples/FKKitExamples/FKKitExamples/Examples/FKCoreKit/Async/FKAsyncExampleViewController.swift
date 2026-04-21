import UIKit
import FKCoreKit

/// End-to-end interactive demo for FKAsync.
/// All sections are intentionally small and copy-ready for production apps.
final class FKAsyncExampleViewController: UIViewController, UISearchBarDelegate, UIScrollViewDelegate {
  // MARK: - FKAsync Components

  /// Shared async hub for main/background dispatch and task orchestration.
  private let async = FKAsync.shared

  /// Debouncer for search text changes.
  private let searchDebouncer = FKDebouncer(interval: 0.35, queue: .main)

  /// Throttler for scroll and button high-frequency events.
  private let eventThrottler = FKThrottler(interval: 0.5, queue: .main)

  /// Cancelable delayed work holder.
  private let delayedWork = FKCancellableDelayedWork(queue: .main)

  /// Dedicated executors for serial and concurrent demo blocks.
  private let serialExecutor = FKAsyncSerialExecutor(label: "com.fkkit.examples.async.serial")
  private let concurrentExecutor = FKAsyncConcurrentExecutor(label: "com.fkkit.examples.async.concurrent")

  // MARK: - UI

  private let scrollView = UIScrollView()
  private let stackView = UIStackView()
  private let searchBar = UISearchBar()
  private let throttleTapButton = UIButton(type: .system)
  private let demoScrollView = UIScrollView()
  private let logView = UITextView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKAsync"
    view.backgroundColor = .systemBackground
    buildLayout()
    appendLog("FKAsync demo initialized.")
  }

  deinit {
    // Cancel pending delayed/debounced tasks when the screen leaves memory.
    delayedWork.cancel()
    searchDebouncer.cancelPending()
  }

  // MARK: - UI Setup

  private func buildLayout() {
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .vertical
    stackView.spacing = 8

    searchBar.placeholder = "Debounce demo: type to trigger delayed search"
    searchBar.delegate = self

    throttleTapButton.setTitle("Throttle Button Tap", for: .normal)
    throttleTapButton.contentHorizontalAlignment = .left
    throttleTapButton.addTarget(self, action: #selector(runThrottleButtonDemo), for: .touchUpInside)

    // Scroll view used to demonstrate throttled scroll callbacks.
    demoScrollView.delegate = self
    demoScrollView.backgroundColor = .secondarySystemBackground
    demoScrollView.layer.cornerRadius = 8
    demoScrollView.heightAnchor.constraint(equalToConstant: 120).isActive = true
    let content = UIView()
    content.translatesAutoresizingMaskIntoConstraints = false
    content.backgroundColor = .clear
    demoScrollView.addSubview(content)
    NSLayoutConstraint.activate([
      content.topAnchor.constraint(equalTo: demoScrollView.contentLayoutGuide.topAnchor),
      content.leadingAnchor.constraint(equalTo: demoScrollView.contentLayoutGuide.leadingAnchor),
      content.trailingAnchor.constraint(equalTo: demoScrollView.contentLayoutGuide.trailingAnchor),
      content.bottomAnchor.constraint(equalTo: demoScrollView.contentLayoutGuide.bottomAnchor),
      content.widthAnchor.constraint(equalTo: demoScrollView.frameLayoutGuide.widthAnchor),
      content.heightAnchor.constraint(equalToConstant: 500),
    ])

    // Add some visual blocks so scrolling feels natural.
    for i in 0..<8 {
      let row = UIView()
      row.translatesAutoresizingMaskIntoConstraints = false
      row.backgroundColor = i % 2 == 0 ? .systemBlue.withAlphaComponent(0.15) : .systemGreen.withAlphaComponent(0.15)
      row.layer.cornerRadius = 6
      content.addSubview(row)
      NSLayoutConstraint.activate([
        row.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 12),
        row.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -12),
        row.heightAnchor.constraint(equalToConstant: 48),
        row.topAnchor.constraint(equalTo: content.topAnchor, constant: CGFloat(12 + i * 60)),
      ])
    }

    let actions: [(String, Selector)] = [
      // Safe Main Thread Execution
      ("Safe Main Thread Execution", #selector(runMainThreadSafetyDemo)),
      // Background Thread Tasks
      ("Background Thread Tasks", #selector(runBackgroundDemo)),
      // Cancelable Delay Tasks
      ("Schedule Delay Task (2s)", #selector(scheduleDelayTask)),
      ("Cancel Delay Task", #selector(cancelDelayTask)),
      // Dispatch Group
      ("Dispatch Group (Multi Tasks)", #selector(runDispatchGroupDemo)),
      // Serial & Concurrent Async Tasks
      ("Serial Async Tasks", #selector(runSerialTasksDemo)),
      ("Concurrent Async Tasks", #selector(runConcurrentTasksDemo)),
      ("Executor Demo (Serial/Concurrent)", #selector(runExecutorDemo)),
      // Check Current Thread
      ("Check Current Thread", #selector(checkCurrentThread)),
      ("Clear Logs", #selector(clearLogs)),
    ]

    for action in actions {
      let button = UIButton(type: .system)
      button.setTitle(action.0, for: .normal)
      button.contentHorizontalAlignment = .left
      button.addTarget(self, action: action.1, for: .touchUpInside)
      stackView.addArrangedSubview(button)
    }

    logView.isEditable = false
    logView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    logView.backgroundColor = .secondarySystemBackground
    logView.layer.cornerRadius = 8
    logView.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(scrollView)
    scrollView.addSubview(stackView)
    view.addSubview(logView)

    // Functional blocks in display order.
    stackView.addArrangedSubview(searchBar)
    stackView.addArrangedSubview(throttleTapButton)
    stackView.addArrangedSubview(demoScrollView)

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

      logView.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 8),
      logView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      logView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      logView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])
  }

  // MARK: - 1) Safe Main Thread Execution

  @objc private func runMainThreadSafetyDemo() {
    async.asyncBackground { [weak self] in
      guard let self else { return }
      // Simulate work off the main thread.
      Thread.sleep(forTimeInterval: 0.15)

      // Safely switch to main for UI updates.
      self.async.runOnMain { [weak self] in
        self?.appendLog("✅ runOnMain executed on main: \(Thread.isMainThread)")
      }
    }
  }

  // MARK: - 2) Background Thread Tasks

  @objc private func runBackgroundDemo() {
    appendLog("➡️ Background task submitted.")
    async.asyncGlobal(qos: .userInitiated) { [weak self] in
      let sum = (1...50_000).reduce(0, +)
      self?.async.runOnMain { [weak self] in
        self?.appendLog("✅ Background result = \(sum)")
      }
    }
  }

  // MARK: - 3) Cancelable Delay Tasks

  @objc private func scheduleDelayTask() {
    appendLog("➡️ Delay task scheduled (2 seconds).")
    delayedWork.schedule(after: 2.0) { [weak self] in
      self?.appendLog("✅ Delayed work fired.")
    }
  }

  @objc private func cancelDelayTask() {
    delayedWork.cancel()
    appendLog("⛔️ Delayed work cancelled.")
  }

  // MARK: - 4) Debounce Usage (Search Bar)

  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    // Only execute when typing pauses for the configured interval.
    searchDebouncer.signal { [weak self] in
      self?.appendLog("🔍 Debounced search trigger: \"\(searchText)\"")
    }
  }

  // MARK: - 5) Throttle Usage (Scroll/Button)

  @objc private func runThrottleButtonDemo() {
    eventThrottler.throttle { [weak self] in
      self?.appendLog("🟠 Throttled button action executed.")
    }
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard scrollView === demoScrollView else { return }
    // Capture UI state on the main actor before entering a Sendable closure.
    let offset = Int(scrollView.contentOffset.y)
    eventThrottler.throttle { [weak self] in
      self?.appendLog("🟣 Throttled scroll callback: y=\(offset)")
    }
  }

  // MARK: - 6) Dispatch Group (Multi Tasks)

  @objc private func runDispatchGroupDemo() {
    appendLog("➡️ DispatchGroup demo started.")
    let group = FKAsyncTaskGroup()

    for idx in 1...3 {
      group.enter()
      async.asyncGlobal(qos: .utility) {
        Thread.sleep(forTimeInterval: 0.2 * Double(idx))
        group.leave()
      }
    }

    group.notify(queue: DispatchQueue.main) { [weak self] in
      self?.appendLog("✅ DispatchGroup finished all tasks.")
    }
  }

  // MARK: - 7) Serial & Concurrent Async Tasks

  @objc private func runSerialTasksDemo() {
    appendLog("➡️ Serial tasks started.")
    async.runSerial(
      [
        { [weak self] in self?.appendLog("1️⃣ Serial task A") },
        { [weak self] in self?.appendLog("2️⃣ Serial task B") },
        { [weak self] in self?.appendLog("3️⃣ Serial task C") },
      ],
      on: FKAsyncQueues.serial(label: "com.fkkit.examples.async.serial.demo"),
      notifyQueue: .main
    ) { [weak self] in
      self?.appendLog("✅ Serial tasks completed.")
    }
  }

  @objc private func runConcurrentTasksDemo() {
    appendLog("➡️ Concurrent tasks started.")
    async.runConcurrent(
      [
        { [weak self] in self?.appendLog("🧩 Concurrent task A") },
        { [weak self] in self?.appendLog("🧩 Concurrent task B") },
        { [weak self] in self?.appendLog("🧩 Concurrent task C") },
      ],
      qos: .userInitiated,
      notifyQueue: .main
    ) { [weak self] in
      self?.appendLog("✅ Concurrent tasks completed.")
    }
  }

  @objc private func runExecutorDemo() {
    appendLog("➡️ Executor demo started.")
    serialExecutor.async { [weak self] in
      self?.appendLog("🔹 SerialExecutor task #1")
    }
    serialExecutor.async { [weak self] in
      self?.appendLog("🔹 SerialExecutor task #2")
    }
    concurrentExecutor.async { [weak self] in
      self?.appendLog("🔸 ConcurrentExecutor task #1")
    }
    concurrentExecutor.async { [weak self] in
      self?.appendLog("🔸 ConcurrentExecutor task #2")
    }
  }

  // MARK: - 8) Check Current Thread

  @objc private func checkCurrentThread() {
    appendLog("ℹ️ FKAsync.isMainThread = \(FKAsync.isMainThread)")
    async.asyncBackground { [weak self] in
      self?.appendLog("ℹ️ On background, currentIsMainThread = \(FKAsync.currentIsMainThread())")
    }
  }

  // MARK: - Utility

  @objc private func clearLogs() {
    // Always mutate UIKit state on the main actor.
    Task { @MainActor [weak self] in
      self?.logView.text = ""
    }
  }

  /// Appends one timestamped line to the log output area.
  ///
  /// This method is intentionally **thread-safe**: callers may invoke it from any queue.
  private nonisolated func appendLog(_ message: String) {
    Task { @MainActor [weak self] in
      self?.appendLogOnMain(message)
    }
  }

  /// Main-actor implementation of logging UI updates.
  @MainActor
  private func appendLogOnMain(_ message: String) {
    let prefix = DateFormatter.fkAsyncLogFormatter.string(from: Date())
    let line = "[\(prefix)] \(message)\n"
    logView.text.append(line)
    let range = NSRange(location: max(logView.text.count - 1, 0), length: 1)
    logView.scrollRangeToVisible(range)
  }
}

private extension DateFormatter {
  /// Shared formatter for compact, human-friendly log timestamps.
  static let fkAsyncLogFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return formatter
  }()
}
