import FKCoreKit
import UIKit

/// Interactive and copy-ready demo for FKPermissions.
/// Every action maps to one practical permission flow.
final class FKPermissionsExampleViewController: UIViewController {
  // MARK: - UI

  private let scrollView = UIScrollView()
  private let stackView = UIStackView()
  private let outputView = UITextView()

  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKPermissions"
    view.backgroundColor = .systemBackground
    buildLayout()
    appendOutput("FKPermissions example loaded.")
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
      ("1) Check Current Status (Camera)", #selector(demoCheckCurrentStatus)),
      ("2) Request Camera (async/await)", #selector(demoRequestCamera)),
      ("3) Request Photo Library Read", #selector(demoRequestPhotoRead)),
      ("4) Request Microphone", #selector(demoRequestMicrophone)),
      ("5) Request Location When In Use", #selector(demoRequestLocationWhenInUse)),
      ("6) Request Location Always", #selector(demoRequestLocationAlways)),
      ("7) Request Notifications (closure)", #selector(demoRequestNotificationsWithClosure)),
      ("8) Request Multiple Permissions in Batch", #selector(demoBatchRequest)),
      ("9) Jump to App Settings", #selector(demoOpenSettings)),
      ("10) Check Denied Handling (Camera)", #selector(demoHandleDeniedCase)),
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

  // MARK: - 1) Check current permission status

  /// Checks status only and never triggers a system prompt.
  @objc private func demoCheckCurrentStatus() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let status = await FKPermissions.shared.status(for: .camera)
      self.appendOutput("Camera current status: \(status)")
    }
  }

  // MARK: - 2) Request single permission (Camera)

  /// Demonstrates async/await request flow for camera.
  @objc private func demoRequestCamera() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let prePrompt = FKPermissionPrePrompt(
        title: "Camera Access Needed",
        message: "Camera is required to scan QR codes securely."
      )
      let result = await FKPermissions.shared.request(.camera, prePrompt: prePrompt)
      self.handleResult(result, featureName: "Camera")
    }
  }

  // MARK: - 3) Request single permission (Photo)

  @objc private func demoRequestPhotoRead() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let result = await FKPermissions.shared.request(.photoLibraryRead)
      self.handleResult(result, featureName: "Photo Library Read")
    }
  }

  // MARK: - 4) Request single permission (Microphone)

  @objc private func demoRequestMicrophone() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let result = await FKPermissions.shared.request(.microphone)
      self.handleResult(result, featureName: "Microphone")
    }
  }

  // MARK: - 5) Location permission (when in use)

  @objc private func demoRequestLocationWhenInUse() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let result = await FKPermissions.shared.request(.locationWhenInUse)
      self.handleResult(result, featureName: "Location When In Use")
    }
  }

  // MARK: - 6) Location permission (always)

  @objc private func demoRequestLocationAlways() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let result = await FKPermissions.shared.request(.locationAlways)
      self.handleResult(result, featureName: "Location Always")
    }
  }

  // MARK: - 7) Request single permission (Notification closure API)

  /// Demonstrates callback-based API for projects that are not fully async/await yet.
  @objc private func demoRequestNotificationsWithClosure() {
    FKPermissions.shared.request(.notifications) { [weak self] result in
      guard let self else { return }
      self.handleResult(result, featureName: "Notifications")
    }
  }

  // MARK: - 8) Request multiple permissions in batch

  @objc private func demoBatchRequest() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let results = await FKPermissions.shared.request([
        .camera,
        .photoLibraryRead,
        .microphone,
        .locationWhenInUse,
        .notifications,
      ])

      self.appendOutput("Batch request finished:")
      let orderedKinds: [FKPermissionKind] = [.camera, .photoLibraryRead, .microphone, .locationWhenInUse, .notifications]
      for kind in orderedKinds {
        let statusText = results[kind]?.status.description ?? "unknown"
        self.appendOutput(" - \(kind.displayName): \(statusText)")
      }
    }
  }

  // MARK: - 9) Jump to app system settings

  @objc private func demoOpenSettings() {
    let opened = FKPermissions.shared.openAppSettings()
    appendOutput(opened ? "Opened app settings." : "Failed to open app settings.")
  }

  // MARK: - 10) Handle permission denied case

  /// Typical production handling:
  /// - If denied/restricted, guide user to system settings.
  /// - If authorized, proceed to feature flow.
  @objc private func demoHandleDeniedCase() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let status = await FKPermissions.shared.status(for: .camera)
      switch status {
      case .denied, .restricted, .deviceDisabled:
        self.appendOutput("Camera unavailable (\(status)). Suggest opening settings.")
        self.presentDeniedAlert(
          title: "Camera Permission Required",
          message: "Please enable Camera access in Settings to continue."
        )
      case .authorized, .limited, .provisional, .ephemeral:
        self.appendOutput("Camera already granted. Continue feature flow.")
      case .notDetermined:
        let result = await FKPermissions.shared.request(.camera)
        self.handleResult(result, featureName: "Camera")
      }
    }
  }

  // MARK: - Helpers

  /// Handles result for all single-request examples in one place.
  private func handleResult(_ result: FKPermissionResult, featureName: String) {
    appendOutput("\(featureName) request result: \(result.status)")

    if let error = result.error {
      appendOutput("\(featureName) error: \(error)")
    }

    // Route denied-like states to a reusable alert.
    switch result.status {
    case .denied, .restricted, .deviceDisabled:
      presentDeniedAlert(
        title: "\(featureName) Permission Denied",
        message: "You can enable \(featureName) access in Settings."
      )
    case .notDetermined, .authorized, .limited, .provisional, .ephemeral:
      break
    }
  }

  /// Shows a reusable denied-state alert with a direct settings action.
  private func presentDeniedAlert(title: String, message: String) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    alert.addAction(
      UIAlertAction(title: "Open Settings", style: .default) { _ in
        _ = FKPermissions.shared.openAppSettings()
      }
    )
    present(alert, animated: true)
  }

  @objc private func clearOutput() {
    outputView.text = ""
    appendOutput("On-screen output cleared.")
  }

  /// Appends one line into the output area on the main actor.
  private nonisolated func appendOutput(_ message: String) {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let line = "[\(DateFormatter.permissionsDemoFormatter.string(from: Date()))] \(message)\n"
      self.outputView.text.append(line)
      let range = NSRange(location: max(self.outputView.text.count - 1, 0), length: 1)
      self.outputView.scrollRangeToVisible(range)
    }
  }
}

private extension FKPermissionKind {
  /// Human-readable names for log output.
  var displayName: String {
    switch self {
    case .camera: return "Camera"
    case .photoLibraryRead: return "Photo Library Read"
    case .photoLibraryAddOnly: return "Photo Library Add-Only"
    case .microphone: return "Microphone"
    case .locationWhenInUse: return "Location When In Use"
    case .locationAlways: return "Location Always"
    case .locationTemporaryFullAccuracy: return "Location Temporary Full Accuracy"
    case .notifications: return "Notifications"
    case .bluetooth: return "Bluetooth"
    case .calendar: return "Calendar"
    case .reminders: return "Reminders"
    case .mediaLibrary: return "Media Library"
    case .speechRecognition: return "Speech Recognition"
    case .appTracking: return "App Tracking"
    }
  }
}

private extension FKPermissionStatus {
  /// Explicit text output for status logs.
  var description: String {
    switch self {
    case .notDetermined: return "notDetermined"
    case .authorized: return "authorized"
    case .denied: return "denied"
    case .restricted: return "restricted"
    case .limited: return "limited"
    case .provisional: return "provisional"
    case .ephemeral: return "ephemeral"
    case .deviceDisabled: return "deviceDisabled"
    }
  }
}

private extension DateFormatter {
  /// Shared formatter for compact output timestamps.
  static let permissionsDemoFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return formatter
  }()
}
