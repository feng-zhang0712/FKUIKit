import UIKit
import FKUIKit
#if canImport(SwiftUI)
import SwiftUI
#endif

/// Full-scenario demo entry for FKTopNotification (UIKit main list).
final class FKTopNotificationExamplesHubViewController: UITableViewController {
  private struct DemoItem {
    let title: String
    let subtitle: String
    let action: () -> Void
  }

  /// Progress notification handle used for manual dismissal and live updates.
  private var progressHandle: FKTopNotificationHandle?
  /// Timer used to simulate real-time download progress updates.
  private var progressTimer: Timer?
  /// Handle used for the manual dismissal demo.
  private var manualHandle: FKTopNotificationHandle?

  private lazy var items: [DemoItem] = [
    DemoItem(title: "Basic Normal Style", subtitle: "Show the normal preset style") { [weak self] in
      self?.showBasicNormal()
    },
    DemoItem(title: "Success Notification", subtitle: "Show the success preset style") { [weak self] in
      FKTopNotification.show("Operation completed", style: .success)
    },
    DemoItem(title: "Error Notification", subtitle: "Show the error preset style") { [weak self] in
      FKTopNotification.show("Request failed, please try again later", style: .error)
    },
    DemoItem(title: "Warning Notification", subtitle: "Show the warning preset style") { [weak self] in
      FKTopNotification.show("The current network is unstable", style: .warning)
    },
    DemoItem(title: "Info Notification", subtitle: "Show the info preset style") { [weak self] in
      FKTopNotification.show("A new version is available", style: .info)
    },
    DemoItem(title: "Notification with Subtitle", subtitle: "Display title + subtitle") { [weak self] in
      self?.showWithSubtitle()
    },
    DemoItem(title: "Notification with Action Button", subtitle: "Demonstrate action callback") { [weak self] in
      self?.showWithAction()
    },
    DemoItem(title: "Custom Color Notification", subtitle: "Custom background, text color, and corner radius") { [weak self] in
      self?.showCustomColor()
    },
    DemoItem(title: "Custom Icon Notification", subtitle: "Replace the default leading icon") { [weak self] in
      self?.showCustomIcon()
    },
    DemoItem(title: "Fully Custom View Notification", subtitle: "Pass any UIView as content") { [weak self] in
      self?.showCustomView()
    },
    DemoItem(title: "Progress Notification (Live Update)", subtitle: "Simulate download progress from 0% to 100%") { [weak self] in
      self?.showProgressNotification()
    },
    DemoItem(title: "Queue Demonstration", subtitle: "Trigger multiple notifications and verify queue behavior") { [weak self] in
      self?.showQueueDemo()
    },
    DemoItem(title: "High-Priority Preemption Demo", subtitle: "Critical notification interrupts normal notifications") { [weak self] in
      self?.showPriorityPreemptionDemo()
    },
    DemoItem(title: "Swipe-to-Dismiss Demo", subtitle: "Dismiss the notification by swiping upward") { [weak self] in
      self?.showSwipeDismissDemo()
    },
    DemoItem(title: "Manual Dismiss Demo", subtitle: "Show first, then call handle.hide() manually") { [weak self] in
      self?.showManualDismissDemo()
    },
    DemoItem(title: "Custom Duration Demo", subtitle: "Show short and long display durations") { [weak self] in
      self?.showCustomDurationDemo()
    },
    DemoItem(title: "Notification with Sound", subtitle: "Play a system sound on presentation") { [weak self] in
      self?.showSoundDemo()
    },
    DemoItem(title: "Apply Global Configuration", subtitle: "Set global style defaults and apply immediately") { [weak self] in
      self?.applyGlobalConfig()
    },
    DemoItem(title: "Reset Global Configuration", subtitle: "Restore default global configuration") { [weak self] in
      self?.resetGlobalConfig()
    },
    DemoItem(title: "SwiftUI Notification Demo", subtitle: "Open standalone SwiftUI demo page") { [weak self] in
      self?.openSwiftUIDemo()
    },
    DemoItem(title: "Dark Mode Adaptation Demo", subtitle: "Switch Light / Dark to preview adaptive styles") { [weak self] in
      self?.showDarkModeDemo()
    },
    DemoItem(title: "Rotation Adaptation Demo", subtitle: "Rotate the device after showing a notification") { [weak self] in
      self?.showRotationDemo()
    },
    DemoItem(title: "Dynamic Island / Notch Adaptation Demo", subtitle: "Top safe area automatically avoids system regions") { [weak self] in
      self?.showNotchSafeAreaDemo()
    },
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKTopNotification"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
    tableView.rowHeight = 68
  }

  deinit {
    progressTimer?.invalidate()
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    items.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let item = items[indexPath.row]
    var config = cell.defaultContentConfiguration()
    config.text = item.title
    config.secondaryText = item.subtitle
    config.secondaryTextProperties.color = .secondaryLabel
    config.secondaryTextProperties.numberOfLines = 2
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    items[indexPath.row].action()
  }

  // MARK: - Scenario Implementations

  private func showBasicNormal() {
    // Basic normal style with a one-line API call.
    FKTopNotification.show("This is a normal notification", style: .normal)
  }

  private func showWithSubtitle() {
    // Title + subtitle, suitable for explanatory feedback.
    FKTopNotification.show(
      title: "Upload completed",
      subtitle: "The file has been synced to the cloud and can be viewed in history",
      configuration: .init(style: .success)
    )
  }

  private func showWithAction() {
    // Action button demo for quick actions like opening details.
    let config = FKTopNotificationConfiguration(
      style: .info,
      duration: 5,
      action: .init(title: "VIEW", titleColor: .white)
    )
    FKTopNotification.show(
      title: "You have 1 new message",
      subtitle: "Tap the button on the right to open the message center",
      configuration: config,
      onAction: { [weak self] in
        self?.showSimpleAlert(title: "Action Callback", message: "You tapped the action button.")
      }
    )
  }

  private func showCustomColor() {
    // Custom visual style: color, corner radius, and shadow can follow brand design.
    var config = FKTopNotificationConfiguration(style: .normal, duration: 3)
    config.backgroundColor = .systemIndigo
    config.textColor = .white
    config.subtitleColor = UIColor(white: 1, alpha: 0.85)
    config.cornerRadius = 18
    config.showsShadow = true
    FKTopNotification.show(
      title: "Brand-themed notification",
      subtitle: "Custom background color and corner radius applied",
      configuration: config
    )
  }

  private func showCustomIcon() {
    // Custom icon demo: replace the default icon with a business-specific icon.
    FKTopNotification.show(
      title: "Membership benefits updated",
      subtitle: "Tap to view the latest benefit details",
      icon: UIImage(systemName: "crown.fill"),
      configuration: .init(style: .warning)
    )
  }

  private func showCustomView() {
    // Fully custom UIView demo for complex layouts or rich content.
    let hStack = UIStackView()
    hStack.axis = .horizontal
    hStack.spacing = 8
    hStack.alignment = .center

    let dot = UIView()
    dot.translatesAutoresizingMaskIntoConstraints = false
    dot.backgroundColor = .systemGreen
    dot.layer.cornerRadius = 4
    dot.widthAnchor.constraint(equalToConstant: 8).isActive = true
    dot.heightAnchor.constraint(equalToConstant: 8).isActive = true

    let label = UILabel()
    label.text = "Realtime connection restored (custom UIView)"
    label.textColor = .white
    label.font = .preferredFont(forTextStyle: .subheadline)

    hStack.addArrangedSubview(dot)
    hStack.addArrangedSubview(label)

    FKTopNotification.show(customView: hStack, configuration: .init(style: .normal))
  }

  private func showProgressNotification() {
    // Progress notification: show first, then update continuously via handle.updateProgress.
    progressTimer?.invalidate()
    var value: Float = 0
    var config = FKTopNotificationConfiguration(style: .info, priority: .high, duration: 0)
    config.progressTintColor = .systemBlue
    config.progressTrackColor = UIColor(white: 1, alpha: 0.24)
    progressHandle = FKTopNotification.show(
      title: "Downloading...",
      subtitle: "Fetching resource package, please wait",
      configuration: config,
      progress: 0
    )

    progressTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] timer in
      value += 0.03
      self?.progressHandle?.updateProgress(value)
      if value >= 1 {
        timer.invalidate()
        self?.progressHandle?.hide()
        FKTopNotification.show("Download completed", style: .success)
      }
    }
  }

  private func showQueueDemo() {
    // Queue demonstration: rapid triggers are presented sequentially.
    let texts = ["Step 1: Validating", "Step 2: Uploading", "Step 3: Writing database", "Step 4: Done"]
    for (index, text) in texts.enumerated() {
      let style: FKTopNotificationStyle = index == texts.count - 1 ? .success : .info
      FKTopNotification.show(title: text, configuration: .init(style: style, duration: 1.4))
    }
  }

  private func showPriorityPreemptionDemo() {
    // Priority preemption: critical notification takes precedence.
    FKTopNotification.show(title: "Normal task in progress...", configuration: .init(style: .normal, priority: .low, duration: 5))
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
      FKTopNotification.show(title: "Critical alert: Service connection interrupted", configuration: .init(style: .error, priority: .critical, duration: 3.5))
    }
  }

  private func showSwipeDismissDemo() {
    // Swipe-to-dismiss demo: swipe the card upward to dismiss.
    var config = FKTopNotificationConfiguration(style: .info, duration: 8)
    config.swipeToDismiss = true
    config.tapToDismiss = false
    FKTopNotification.show(
      title: "Swipe up this notification to dismiss",
      subtitle: "This scenario verifies gesture-based dismissal",
      configuration: config
    )
  }

  private func showManualDismissDemo() {
    // Manual dismiss demo: keep the handle and call hide() later.
    manualHandle = FKTopNotification.show(
      title: "This notification will be dismissed manually in 2 seconds",
      subtitle: "Demonstrates proactive control via handle.hide()",
      configuration: .init(style: .warning, duration: 0)
    )
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
      self?.manualHandle?.hide()
    }
  }

  private func showCustomDurationDemo() {
    // Custom duration demo: show a short notice, then a longer one.
    FKTopNotification.show(title: "Short notice (0.8s)", configuration: .init(style: .normal, duration: 0.8))
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      FKTopNotification.show(title: "Long notice (4s)", configuration: .init(style: .info, duration: 4))
    }
  }

  private func showSoundDemo() {
    // Sound demo: play a system sound when notification is presented.
    let config = FKTopNotificationConfiguration(style: .success, sound: .default)
    FKTopNotification.show(
      title: "Payment successful",
      subtitle: "A system sound was played",
      configuration: config
    )
  }

  private func applyGlobalConfig() {
    // Global configuration demo: set app-wide default style values.
    var global = FKTopNotificationConfiguration(style: .info)
    global.duration = 2.8
    global.animationDuration = 0.24
    global.animationStyle = .slide
    global.cornerRadius = 16
    global.outerInsets = .init(top: 12, leading: 12, bottom: 0, trailing: 12)
    FKTopNotification.defaultConfiguration = global
    FKTopNotification.show("Global configuration applied. Upcoming notifications will follow this style", style: .info)
  }

  private func resetGlobalConfig() {
    // Reset global configuration to component defaults.
    FKTopNotification.defaultConfiguration = FKTopNotificationConfiguration()
    FKTopNotification.show("Global configuration reset to defaults", style: .normal)
  }

  private func openSwiftUIDemo() {
    // Open standalone SwiftUI demo page.
    navigationController?.pushViewController(FKTopNotificationSwiftUIHostViewController(), animated: true)
  }

  private func showDarkModeDemo() {
    // Dark mode demo: switch appearance and preview adaptive notification colors.
    let alert = UIAlertController(title: "Dark Mode Demo", message: "Select page appearance mode", preferredStyle: .actionSheet)
    alert.addAction(UIAlertAction(title: "Follow System", style: .default) { [weak self] _ in
      self?.overrideUserInterfaceStyle = .unspecified
      FKTopNotification.show("Using system appearance mode", style: .normal)
    })
    alert.addAction(UIAlertAction(title: "Light Mode", style: .default) { [weak self] _ in
      self?.overrideUserInterfaceStyle = .light
      FKTopNotification.show("Switched to light mode", style: .info)
    })
    alert.addAction(UIAlertAction(title: "Dark Mode", style: .default) { [weak self] _ in
      self?.overrideUserInterfaceStyle = .dark
      FKTopNotification.show("Switched to dark mode", style: .info)
    })
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    present(alert, animated: true)
  }

  private func showRotationDemo() {
    // Rotation adaptation demo: rotate the device after showing the notification.
    FKTopNotification.show(
      title: "Rotate the device to preview adaptation",
      subtitle: "The notification uses Auto Layout and adapts to orientation and safe areas",
      configuration: .init(style: .info, duration: 6)
    )
  }

  private func showNotchSafeAreaDemo() {
    // Notch / Dynamic Island adaptation demo: avoids system regions via safe area.
    var config = FKTopNotificationConfiguration(style: .normal, duration: 4)
    config.outerInsets = .init(top: 2, leading: 12, bottom: 0, trailing: 12)
    FKTopNotification.show(
      title: "Safe-area adaptation verification",
      subtitle: "On notch/Dynamic Island devices, top system regions are avoided automatically",
      configuration: config
    )
  }

  private func showSimpleAlert(title: String, message: String) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
  }
}

// MARK: - SwiftUI Standalone Demo

final class FKTopNotificationSwiftUIHostViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "TopNotification SwiftUI"
    view.backgroundColor = .systemBackground
    #if canImport(SwiftUI)
    let host = UIHostingController(rootView: FKTopNotificationSwiftUIScreen())
    addChild(host)
    host.view.translatesAutoresizingMaskIntoConstraints = false
    host.view.backgroundColor = .clear
    view.addSubview(host.view)
    NSLayoutConstraint.activate([
      host.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    host.didMove(toParent: self)
    #else
    let label = UILabel()
    label.text = "SwiftUI unavailable."
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
    #endif
  }
}

#if canImport(SwiftUI)
private struct FKTopNotificationSwiftUICustomContent: View {
  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: "sparkles")
      Text("SwiftUI custom notification view")
        .font(.subheadline)
    }
    .foregroundStyle(.white)
    .padding(.vertical, 2)
  }
}

private struct FKTopNotificationSwiftUIScreen: View {
  var body: some View {
    ScrollView {
      VStack(spacing: 12) {
        Text("FKTopNotification SwiftUI Demo")
          .font(.headline)
          .frame(maxWidth: .infinity, alignment: .leading)

        Button("Show Success Notification") {
          FKTopNotification.show("Saved from SwiftUI", style: .success)
        }
        .buttonStyle(.borderedProminent)

        Button("Show Custom SwiftUI Content") {
          FKTopNotification.show(
            swiftUIView: FKTopNotificationSwiftUICustomContent(),
            configuration: .init(style: .info)
          )
        }
        .buttonStyle(.bordered)

        Button("Queue 3 Notifications") {
          FKTopNotification.show("Queue 1", style: .info)
          FKTopNotification.show("Queue 2", style: .warning)
          FKTopNotification.show("Queue 3", style: .success)
        }
        .buttonStyle(.bordered)
      }
      .padding(16)
    }
    .background(Color(uiColor: .systemGroupedBackground))
  }
}
#endif
