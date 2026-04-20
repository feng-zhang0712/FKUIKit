import UIKit
import FKCoreKit

/// End-to-end interactive demo for FKUtils.
///
/// This sample is copy-ready for production projects:
/// - Uses only static FKUtils APIs
/// - Includes defensive checks and error-tolerant handling
/// - Demonstrates main-thread-safe UI updates
final class FKUtilsExampleViewController: UIViewController {
  // MARK: - UI

  private let scrollView = UIScrollView()
  private let stackView = UIStackView()
  private let outputView = UITextView()
  private let demoImageView = UIImageView()
  private let sampleCardView = UIView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKUtils"
    view.backgroundColor = .systemBackground
    buildLayout()
    appendOutput("FKUtils demo initialized.")
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

    demoImageView.translatesAutoresizingMaskIntoConstraints = false
    demoImageView.contentMode = .scaleAspectFit
    demoImageView.backgroundColor = .tertiarySystemBackground
    demoImageView.layer.cornerRadius = 8
    demoImageView.clipsToBounds = true

    sampleCardView.translatesAutoresizingMaskIntoConstraints = false
    sampleCardView.backgroundColor = .systemTeal
    sampleCardView.layer.cornerRadius = 10

    let actions: [(String, Selector)] = [
      ("1) Date: Format + Timestamp + Relative", #selector(demoDateUtilities)),
      ("2) Regex: Phone/Email/ID/Password", #selector(demoRegexUtilities)),
      ("3) Number: Grouping + Decimal Ops", #selector(demoNumberUtilities)),
      ("4) String: Trim + Mask + Encoding", #selector(demoStringUtilities)),
      ("5) Device: Model + App + Disk", #selector(demoDeviceUtilities)),
      ("6) UI: Hex + Adaptation + Main Thread", #selector(demoUIUtilities)),
      ("7) Collection: Safe Access + JSON", #selector(demoCollectionUtilities)),
      ("8) Image: Compress + Convert + Rounded", #selector(demoImageUtilities)),
      ("9) Common: Jump + Vibration + Null Check", #selector(demoCommonUtilities)),
      ("Clear Output", #selector(clearOutput)),
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
    view.addSubview(sampleCardView)
    view.addSubview(demoImageView)
    view.addSubview(outputView)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      scrollView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.36),

      stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
      stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
      stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
      stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

      sampleCardView.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 8),
      sampleCardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      sampleCardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      sampleCardView.heightAnchor.constraint(equalToConstant: 44),

      demoImageView.topAnchor.constraint(equalTo: sampleCardView.bottomAnchor, constant: 8),
      demoImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      demoImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      demoImageView.heightAnchor.constraint(equalToConstant: 90),

      outputView.topAnchor.constraint(equalTo: demoImageView.bottomAnchor, constant: 8),
      outputView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      outputView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      outputView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])
  }

  // MARK: - 1) Date

  /// Demonstrates date formatting, timestamp conversion, and relative time.
  @objc private func demoDateUtilities() {
    let now = Date()
    let standard = FKUtils.DateTime.string(from: now, format: "yyyy-MM-dd HH:mm:ss")
    let timestamp = FKUtils.DateTime.timestamp(from: now)
    let restored = FKUtils.DateTime.date(fromTimestamp: timestamp)
    let restoredText = FKUtils.DateTime.string(from: restored, format: "yyyy-MM-dd HH:mm:ss")
    let twoHoursAgo = FKUtils.DateTime.add(DateComponents(hour: -2), to: now) ?? now
    let relative = FKUtils.DateTime.relativeDescription(for: twoHoursAgo, reference: now)
    let isValid = FKUtils.DateTime.isValidDate("2026-04-20", format: "yyyy-MM-dd")

    appendOutput("Date string: \(standard)")
    appendOutput("Timestamp: \(timestamp)")
    appendOutput("Restored date: \(restoredText)")
    appendOutput("Relative time: \(relative)")
    appendOutput("Date validation: \(isValid)")
  }

  // MARK: - 2) Regex

  /// Demonstrates high-frequency regex validation scenarios.
  @objc private func demoRegexUtilities() {
    appendOutput("Phone valid: \(FKUtils.Regex.isValidPhone("13800138000"))")
    appendOutput("Email valid: \(FKUtils.Regex.isValidEmail("dev@example.com"))")
    appendOutput("ID valid: \(FKUtils.Regex.isValidIDCard("110101199001011234"))")
    appendOutput("Strong password: \(FKUtils.Regex.isStrongPassword("Aa@12345"))")

    let extracted = FKUtils.Regex.extract("IDs: A-10 B-20", pattern: #"[A-Z]-\d+"#)
    appendOutput("Extracted groups: \(extracted)")
  }

  // MARK: - 3) Number

  /// Demonstrates amount formatting and decimal processing.
  @objc private func demoNumberUtilities() {
    let amount = Decimal(string: "1234567.8912") ?? 0
    let grouped = FKUtils.Number.formatAmount(amount, minimumFractionDigits: 2, maximumFractionDigits: 2)
    let rounded = FKUtils.Number.rounded(amount, scale: 2)
    let truncated = FKUtils.Number.truncated(amount, scale: 2)
    let percent = FKUtils.Number.formatPercent(0.1265, fractionDigits: 2)

    appendOutput("Grouped amount: \(grouped)")
    appendOutput("Rounded: \(rounded)")
    appendOutput("Truncated: \(truncated)")
    appendOutput("Percent: \(percent)")
  }

  // MARK: - 4) String

  /// Demonstrates string trimming, masking, and encoding utilities.
  @objc private func demoStringUtilities() {
    let trimmed = FKUtils.String.trim("  hello FKUtils \n")
    let maskedPhone = FKUtils.String.maskPhone("13800138000")
    let maskedEmail = FKUtils.String.maskEmail("john.doe@example.com")
    let encoded = FKUtils.String.base64Encode("FKUtils")
    let decoded = FKUtils.String.base64Decode(encoded) ?? "decode failed"
    let escaped = FKUtils.String.htmlEscape("<title>FK</title>")
    let unescaped = FKUtils.String.htmlUnescape(escaped)

    appendOutput("Trimmed: \(trimmed)")
    appendOutput("Masked phone: \(maskedPhone)")
    appendOutput("Masked email: \(maskedEmail)")
    appendOutput("Base64 decoded: \(decoded)")
    appendOutput("HTML unescaped: \(unescaped)")
  }

  // MARK: - 5) Device

  /// Demonstrates device/app metadata and disk status acquisition.
  @objc private func demoDeviceUtilities() {
    let model = FKUtils.Device.modelIdentifier()
    let appVersion = FKUtils.Device.appVersion()
    let build = FKUtils.Device.appBuild()
    let disk = FKUtils.Device.diskSpace()

    appendOutput("Device model: \(model)")
    appendOutput("App version/build: \(appVersion) (\(build))")
    appendOutput("Disk free/total: \(disk.free) / \(disk.total)")

    FKUtils.Device.networkStatus { [weak self] status in
      self?.appendOutput("Network status: \(status)")
    }
  }

  // MARK: - 6) UI

  /// Demonstrates color conversion, adaptive UI, and main-thread-safe execution.
  @objc private func demoUIUtilities() {
    let color = FKUtils.UI.color(hex: "#3366FF")
    let hex = FKUtils.UI.hex(from: color)
    let adaptiveFont = FKUtils.UI.adaptiveFont(size: 16, weight: .medium)

    sampleCardView.backgroundColor = color
    sampleCardView.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
    _ = FKUtils.UI.addGradient(to: sampleCardView, colors: [color.withAlphaComponent(0.7), .systemPurple])
    FKUtils.UI.applyShadow(to: sampleCardView)

    FKUtils.UI.runOnMain { [weak self] in
      guard let self else { return }
      self.outputView.font = adaptiveFont
      let screenshot = FKUtils.UI.screenshot(of: self.sampleCardView)
      self.demoImageView.image = screenshot
      self.appendOutput("Color hex round-trip: \(hex)")
      self.appendOutput("Adaptive font size: \(adaptiveFont.pointSize)")
      self.appendOutput("Main-thread screenshot updated.")
    }
  }

  // MARK: - 7) Collection

  /// Demonstrates safe collection usage and JSON conversion.
  @objc private func demoCollectionUtilities() {
    struct DemoUser: Decodable {
      let id: Int
      let name: String
    }

    let values = [1, 2, 2, 3, 3, 4]
    let unique = FKUtils.Collection.unique(values)
    let safeValue = values[safe: 99]

    let payload: [String: Any] = ["id": 7, "name": "FK"]
    let json = FKUtils.Collection.jsonString(from: payload) ?? "{}"
    let user = FKUtils.Collection.decode(DemoUser.self, from: payload)

    appendOutput("Unique values: \(unique)")
    appendOutput("Safe array access at 99: \(String(describing: safeValue))")
    appendOutput("JSON payload: \(json)")
    appendOutput("Decoded user: \(String(describing: user?.name))")
  }

  // MARK: - 8) Image

  /// Demonstrates image compression, conversion, and rounded-corner rendering.
  @objc private func demoImageUtilities() {
    // Generate a deterministic image to keep this demo self-contained.
    let raw = FKUtils.Image.solidColor(.systemOrange, size: CGSize(width: 120, height: 120))
    let rounded = FKUtils.Image.rounded(raw, radius: 20)
    demoImageView.image = rounded

    let compressedBytes = FKUtils.Image.compress(rounded, maxBytes: 12 * 1024)?.count ?? 0
    let base64 = FKUtils.Image.base64(from: rounded, compressionQuality: 0.8) ?? ""
    let restored = FKUtils.Image.image(fromBase64: base64)

    appendOutput("Compressed bytes: \(compressedBytes)")
    appendOutput("Base64 length: \(base64.count)")
    appendOutput("Restored image success: \(restored != nil)")
  }

  // MARK: - 9) Common

  /// Demonstrates app jump APIs, vibration, and null-safe checks.
  @objc private func demoCommonUtilities() {
    let docs = FKUtils.Common.documentsDirectory().path
    let nilCheck = FKUtils.Common.isNilOrEmpty("   ")
    let intValue = FKUtils.Common.toInt("42") ?? -1
    let safeResult = FKUtils.Common.safe { try riskyDivision(10, by: 0) }

    appendOutput("Documents path: \(docs)")
    appendOutput("Nil or empty check: \(nilCheck)")
    appendOutput("String->Int conversion: \(intValue)")
    appendOutput("Safe execution result: \(safeResult)")

    // Vibration is side-effect only; suitable for user-triggered interaction.
    FKUtils.Common.vibrate()

    // Keep external jumps opt-in and explicit in demos.
    let alert = UIAlertController(
      title: "Open System Settings?",
      message: "This demonstrates FKUtils.Common.openSettings().",
      preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    alert.addAction(UIAlertAction(title: "Open", style: .default, handler: { _ in
      FKUtils.Common.openSettings()
    }))
    present(alert, animated: true)
  }

  // MARK: - Helpers

  @objc private func clearOutput() {
    outputView.text = ""
    appendOutput("Output cleared.")
  }

  /// Appends one log line on screen in a thread-safe way.
  private nonisolated func appendOutput(_ message: String) {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let line = "[\(DateFormatter.fkDemo.string(from: Date()))] \(message)\n"
      self.outputView.text.append(line)
      let range = NSRange(location: max(self.outputView.text.count - 1, 0), length: 1)
      self.outputView.scrollRangeToVisible(range)
    }
  }

  /// A throwable function used to demonstrate FKUtils.Common.safe.
  private func riskyDivision(_ lhs: Int, by rhs: Int) throws -> Int {
    enum DivisionError: Error { case divideByZero }
    guard rhs != 0 else { throw DivisionError.divideByZero }
    return lhs / rhs
  }
}

private extension DateFormatter {
  static let fkDemo: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return formatter
  }()
}
