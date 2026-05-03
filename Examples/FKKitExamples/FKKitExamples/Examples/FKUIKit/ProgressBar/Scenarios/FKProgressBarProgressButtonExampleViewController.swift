import FKUIKit
import UIKit

/// Demonstrates ``FKProgressBar`` as a **progress button**: ``FKProgressBarInteractionMode/button``, custom titles, haptics, and minimum hit targets.
@MainActor
final class FKProgressBarProgressButtonDemoViewController: UIViewController {

  private let downloadBar = FKProgressBar()
  private let ringBar = FKProgressBar()
  private let logLabel = UILabel()
  private var downloadPumpWorkItem: DispatchWorkItem?
  private var simulatedDownloadProgress: CGFloat = 0
  private var isDownloadSequenceActive = false

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Progress as button"
    view.backgroundColor = .systemGroupedBackground

    var downloadConfig = FKProgressBarConfiguration()
    downloadConfig.label.placement = .centeredOnTrack
    downloadConfig.label.contentMode = .customTitleWhenIdle
    downloadConfig.label.customTitle = "Download"
    downloadConfig.interaction.interactionMode = .button
    downloadConfig.interaction.touchHaptic = .lightImpactOnTouchDown
    downloadConfig.interaction.minimumTouchTargetSize = CGSize(width: 44, height: 44)
    downloadConfig.layout.trackThickness = 10
    downloadConfig.label.font = .preferredFont(forTextStyle: .subheadline)
    downloadConfig.label.usesSemanticTextColor = true
    downloadConfig.accessibility.customHint = "Starts a mock download."
    downloadConfig.motion.playsIndeterminateAnimation = false
    downloadBar.configuration = downloadConfig
    // Finger taps reliably deliver touchUpInside; primaryActionTriggered covers accessibility / external keyboards.
    downloadBar.addTarget(self, action: #selector(onDownloadTapped), for: .touchUpInside)
    downloadBar.addTarget(self, action: #selector(onDownloadTapped), for: .primaryActionTriggered)
    downloadBar.translatesAutoresizingMaskIntoConstraints = false

    var ringConfig = FKProgressBarConfiguration()
    ringConfig.layout.variant = .ring
    ringConfig.layout.ringDiameter = 96
    ringConfig.layout.ringLineWidth = 5
    ringConfig.label.placement = .centeredOnTrack
    ringConfig.label.contentMode = .customTitleWithProgressSubtitle
    ringConfig.label.customTitle = "Sync"
    ringConfig.interaction.interactionMode = .button
    ringConfig.interaction.touchHaptic = .selectionChangedOnTouchDown
    ringConfig.interaction.minimumTouchTargetSize = CGSize(width: 48, height: 48)
    ringConfig.appearance.progressColor = .systemTeal
    ringBar.configuration = ringConfig
    ringBar.setProgress(0.12, animated: false)
    ringBar.addTarget(self, action: #selector(onRingTapped), for: .touchUpInside)
    ringBar.addTarget(self, action: #selector(onRingTapped), for: .primaryActionTriggered)
    ringBar.translatesAutoresizingMaskIntoConstraints = false

    // Center the ring and keep stroke overflow from overlapping the section copy above.
    let ringHost = UIView()
    ringHost.translatesAutoresizingMaskIntoConstraints = false
    ringHost.clipsToBounds = true
    ringHost.addSubview(ringBar)
    let ringSide = Self.ringControlSquareSide(configuration: ringConfig)
    NSLayoutConstraint.activate([
      ringBar.centerXAnchor.constraint(equalTo: ringHost.centerXAnchor),
      ringBar.centerYAnchor.constraint(equalTo: ringHost.centerYAnchor),
      ringBar.widthAnchor.constraint(equalToConstant: ringSide),
      ringBar.heightAnchor.constraint(equalToConstant: ringSide),
      ringHost.heightAnchor.constraint(equalToConstant: ringSide + 8),
    ])

    let sectionA = FKProgressBarExampleLayoutHelpers.makeSectionLabel("Linear + idle title")
    let capA = FKProgressBarExampleLayoutHelpers.makeCaptionLabel(
      "Tap Download: short indeterminate phase, then determinate progress to 100%. Title switches to percent while running. Uses primaryActionTriggered."
    )
    let cardA = FKProgressBarExampleLayoutHelpers.makeCardStack(arrangedSubviews: [sectionA, capA, downloadBar])

    let sectionB = FKProgressBarExampleLayoutHelpers.makeSectionLabel("Ring + two-line label")
    let capB = FKProgressBarExampleLayoutHelpers.makeCaptionLabel(
      "First line is fixed copy; second line follows the percent format. Tap to bump progress in small steps."
    )
    let ringTopSpacer = UIView()
    ringTopSpacer.translatesAutoresizingMaskIntoConstraints = false
    ringTopSpacer.heightAnchor.constraint(equalToConstant: 14).isActive = true
    let cardB = FKProgressBarExampleLayoutHelpers.makeCardStack(arrangedSubviews: [sectionB, capB, ringTopSpacer, ringHost])

    let enabledSwitch = UISwitch()
    enabledSwitch.isOn = true
    enabledSwitch.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      let on = enabledSwitch.isOn
      self.downloadBar.isEnabled = on
      self.ringBar.isEnabled = on
      self.appendLog(on ? "Controls enabled" : "Controls disabled (dimmed)")
    }, for: .valueChanged)
    let row = FKProgressBarExampleLayoutHelpers.makeLabeledRow(title: "Enabled", control: enabledSwitch)

    let reset = UIButton(type: .system)
    reset.setTitle("Reset download bar", for: .normal)
    reset.addAction(UIAction { [weak self] _ in
      self?.resetDownloadDemo()
    }, for: .touchUpInside)

    logLabel.translatesAutoresizingMaskIntoConstraints = false
    logLabel.font = .preferredFont(forTextStyle: .caption1)
    logLabel.textColor = .secondaryLabel
    logLabel.numberOfLines = 0
    logLabel.text = "Event log:\n—"

    let stack = UIStackView(arrangedSubviews: [cardA, cardB, row, reset, logLabel])
    stack.translatesAutoresizingMaskIntoConstraints = false
    stack.axis = .vertical
    stack.spacing = 16

    let scroll = UIScrollView()
    scroll.translatesAutoresizingMaskIntoConstraints = false
    scroll.alwaysBounceVertical = true
    scroll.addSubview(stack)

    view.addSubview(scroll)
    let g = view.safeAreaLayoutGuide
    NSLayoutConstraint.activate([
      scroll.topAnchor.constraint(equalTo: g.topAnchor, constant: 12),
      scroll.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 16),
      scroll.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -16),
      scroll.bottomAnchor.constraint(equalTo: g.bottomAnchor, constant: -12),

      stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
      stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
      stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
      stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
      stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor),

      downloadBar.heightAnchor.constraint(equalToConstant: 52),
    ])
  }

  /// Square side length that fits ring diameter + centered two-line label + insets (matches gallery-style sizing).
  private static func ringControlSquareSide(configuration c: FKProgressBarConfiguration) -> CGFloat {
    let d = CGFloat(c.layout.ringDiameter ?? 36)
    let ins = c.layout.contentInsets
    let strokeSlop = c.layout.ringLineWidth * 2 + 10
    let font = c.label.font
    let sample = c.label.customTitle.isEmpty ? "Sync\n100%" : "\(c.label.customTitle)\n100%"
    let h = ceil(
      (sample as NSString).boundingRect(
        with: CGSize(width: max(120, d + ins.left + ins.right), height: CGFloat.greatestFiniteMagnitude),
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        attributes: [.font: font],
        context: nil
      ).height
    )
    return max(d + ins.top + ins.bottom + strokeSlop, d + h + ins.top + ins.bottom + 4)
  }

  private func appendLog(_ line: String) {
    let existing = logLabel.text ?? ""
    if existing == "Event log:\n—" {
      logLabel.text = "Event log:\n\(line)"
    } else {
      logLabel.text = "\(existing)\n\(line)"
    }
  }

  private func resetDownloadDemo() {
    downloadPumpWorkItem?.cancel()
    downloadPumpWorkItem = nil
    isDownloadSequenceActive = false
    simulatedDownloadProgress = 0
    downloadBar.stopIndeterminate()
    downloadBar.setProgress(0, animated: false)
    appendLog("Reset download bar")
  }

  @objc private func onDownloadTapped() {
    guard !isDownloadSequenceActive, !downloadBar.isIndeterminate else {
      appendLog("Download ignored (already running)")
      return
    }
    isDownloadSequenceActive = true
    appendLog("Download tapped → mock download")
    downloadBar.setProgress(0, animated: false)
    downloadBar.startIndeterminate()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { [weak self] in
      guard let self else { return }
      self.downloadBar.stopIndeterminate()
      self.downloadBar.setProgress(0, animated: false)
      self.simulatedDownloadProgress = 0
      self.pumpSimulatedDownload()
    }
  }

  private func pumpSimulatedDownload() {
    simulatedDownloadProgress += 0.018
    if simulatedDownloadProgress >= 1 {
      downloadPumpWorkItem = nil
      isDownloadSequenceActive = false
      downloadBar.setProgress(1, animated: true)
      appendLog("Download finished")
      return
    }
    downloadBar.setProgress(simulatedDownloadProgress, animated: true)
    let work = DispatchWorkItem { [weak self] in
      self?.pumpSimulatedDownload()
    }
    downloadPumpWorkItem = work
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.035, execute: work)
  }

  @objc private func onRingTapped() {
    let next = min(1, ringBar.progress + 0.09)
    ringBar.setProgress(next, animated: true)
    appendLog(String(format: "Ring tapped → progress %.0f%%", next * 100))
  }
}
