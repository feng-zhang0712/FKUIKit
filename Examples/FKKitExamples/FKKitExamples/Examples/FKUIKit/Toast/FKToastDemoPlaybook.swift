import UIKit
import FKUIKit

/// Centralized demo trigger methods shared by UIKit and SwiftUI.
enum FKToastDemoPlaybook {
  /// Demonstrates top/center/bottom placement and style variants.
  static func showBasicPlacementAndStyle() {
    FKToast.show("Top info toast", configuration: .init(kind: .toast, style: .info, position: .top))
    FKToast.show("Center success toast", configuration: .init(kind: .toast, style: .success, position: .center))
    FKToast.show("Bottom warning toast", configuration: .init(kind: .toast, style: .warning, position: .bottom))
    FKToast.show("Bottom error toast", configuration: .init(kind: .toast, style: .error, position: .bottom))
  }

  /// Shows a multiline message to verify wrapping behavior.
  static func showLongMultilineToast() {
    FKToast.show(
      "This is a multiline toast message used to validate wrapping, dynamic type scaling, and readability across narrow screens."
    )
  }

  /// Shows a toast with a custom icon override.
  static func showCustomIconToast() {
    var config = FKToastConfiguration(kind: .toast, style: .info)
    config.animationStyle = .scale
    config.symbolSet = .init(success: "checkmark.seal.fill")
    FKToast.show("Custom icon toast", icon: UIImage(systemName: "bolt.fill"), configuration: config)
  }

  /// Shows a toast with fully custom UIKit content.
  static func showCustomViewToast() {
    let row = UIStackView()
    row.axis = .horizontal
    row.spacing = 8
    let badge = UILabel()
    badge.text = "LIVE"
    badge.font = .preferredFont(forTextStyle: .caption1)
    badge.textColor = .white
    badge.backgroundColor = .systemRed
    badge.layer.cornerRadius = 6
    badge.layer.masksToBounds = true
    badge.textAlignment = .center
    badge.widthAnchor.constraint(equalToConstant: 42).isActive = true
    let text = UILabel()
    text.font = .preferredFont(forTextStyle: .subheadline)
    text.textColor = .white
    text.text = "Realtime stream connected."
    row.addArrangedSubview(badge)
    row.addArrangedSubview(text)
    FKToast.show(customView: row, configuration: .init(kind: .toast, style: .normal))
  }

  /// Pushes multiple requests quickly to show queue sequencing.
  static func burstQueueDemo() {
    for index in 1...6 {
      FKToast.show("Queue message #\(index)", style: .info, kind: .snackbar)
    }
  }

  /// Shows deduplication/coalesce behavior by repeating same message.
  static func dedupeCoalesceDemo() {
    var config = FKToastConfiguration(kind: .snackbar, style: .warning, duration: 2.2)
    config.queue.arrivalPolicy = .coalesce
    config.queue.deduplicationWindow = 4
    for _ in 0..<4 {
      FKToast.show("Network is unstable", configuration: config)
    }
  }

  /// Compares interruption behavior with and without requeueing previous request.
  static func interruptionComparison() {
    var base = FKToastConfiguration(kind: .snackbar, style: .info, duration: 5)
    base.queue.arrivalPolicy = .queue
    FKToast.show("Low priority task running...", configuration: base)

    var interruptRestore = FKToastConfiguration(kind: .snackbar, style: .error, priority: .critical, duration: 2)
    interruptRestore.queue.arrivalPolicy = .interruptAndRequeueCurrent
    FKToast.show("Critical alert with restore", configuration: interruptRestore)

    var interruptReplace = FKToastConfiguration(kind: .snackbar, style: .warning, priority: .critical, duration: 2)
    interruptReplace.queue.arrivalPolicy = .replaceCurrent
    FKToast.show("Critical alert without restore", configuration: interruptReplace)
  }

  /// Shows loading HUD with optional interaction blocking.
  static func showHUDLoading(blocking: Bool) {
    FKHUD.showLoading("Fetching profile…", interceptTouches: blocking, timeout: 10)
  }

  /// Simulates determinate progress by updating HUD text from 0 to 100%.
  static func showHUDProgress() {
    Task { @MainActor in
      for step in stride(from: 0, through: 100, by: 20) {
        FKHUD.showProgress("Uploading", progress: Double(step) / 100)
        try? await Task.sleep(nanoseconds: 450_000_000)
      }
      FKHUD.showSuccess("Upload completed")
    }
  }
  
  static func showLiveHUDProgress() {
    Task { @MainActor in
      let totalDuration: TimeInterval = 5
      let identifier = await FKToast.showAndReturnID(
        builder: .init(
          content: .titleSubtitle(title: "Uploading", subtitle: "0%"),
          configuration: .init(kind: .hud, style: .info, duration: totalDuration, timeout: totalDuration, interceptTouches: true)
        )
      )
      scheduleProgressUpdate(id: identifier, progress: 20, after: 1)
      scheduleProgressUpdate(id: identifier, progress: 40, after: 2)
      scheduleProgressUpdate(id: identifier, progress: 60, after: 3)
      scheduleProgressUpdate(id: identifier, progress: 80, after: 4)
      scheduleProgressUpdate(id: identifier, progress: 100, after: 4.8)
    }
  }

  /// Shows success and failure HUD status with auto dismiss.
  static func showHUDEndStates() {
    FKHUD.showSuccess("Operation succeeded")
    FKHUD.showFailure("Operation failed")
  }

  /// Demonstrates blur and liquid-glass preferred visual effects with fallback.
  static func showVisualEffectDemo(liquidPreferred: Bool) {
    var configuration = FKToastConfiguration(kind: .snackbar, style: .info, duration: 4)
    configuration.backgroundVisualEffect = liquidPreferred ? .liquidGlassPreferred : .blur(style: .systemThinMaterial)
    configuration.visualEffectOpacity = 0.82
    configuration.disableVisualEffectInLowPowerMode = true
    configuration.fallbackToSolidColorWhenReduceTransparencyEnabled = true
    FKToast.show("Visual effect enabled. Low Power / Reduce Transparency will fallback automatically.", configuration: configuration)
  }

  /// Demonstrates top and bottom spacing around navigation bar and tab bar.
  static func showPlacementInsetsDemo() {
    var top = FKToastConfiguration(kind: .toast, style: .info, position: .top, duration: 2.5)
    top.topInsetWhenHasNavigationBar = 14
    top.topInsetFromSafeArea = 18
    FKToast.show("Top position adapts to navigation bar visibility.", configuration: top)

    var bottom = FKToastConfiguration(kind: .snackbar, style: .warning, position: .bottom, duration: 2.5)
    bottom.bottomInsetWhenHasTabBar = 14
    bottom.bottomInsetFromSafeArea = 16
    FKToast.show("Bottom position adapts to tab bar, safe area, and keyboard.", configuration: bottom)
  }

  /// Shows a snackbar with action and accessibility hooks.
  static func showActionSnackbar(announcementEnabled: Bool) {
    var config = FKToastConfiguration(kind: .snackbar, style: .info, duration: 6, action: .init(title: "Retry"))
    config.secondaryAction = .init(title: "Dismiss", accessibilityLabel: "Dismiss message")
    config.swipeToDismiss = true
    config.accessibilityAnnouncementEnabled = announcementEnabled
    FKToast.show(
      builder: .init(
        content: .message("Upload failed, tap Retry to continue."),
        configuration: config,
        actionHandler: {
          FKToast.show("Retry triggered", style: .success, kind: .toast)
        },
        secondaryActionHandler: {
          FKToast.clearAll(animated: true)
        }
      )
    )
  }

  private static func scheduleProgressUpdate(id: UUID, progress: Int, after delay: TimeInterval) {
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
      Task { @MainActor in
        _ = await FKToast.update(
          id,
          content: .titleSubtitle(title: "Uploading", subtitle: "\(progress)%")
        )
      }
    }
  }
}
