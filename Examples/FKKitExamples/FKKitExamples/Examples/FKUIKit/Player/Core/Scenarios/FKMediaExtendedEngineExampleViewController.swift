import FKUIKit
import UIKit

/// Demonstrates format probing and expected failure when loading extended-only URLs without a decoder.
@MainActor
final class FKMediaExtendedEngineExampleViewController: UIViewController, FKMediaPlaybackCoordinatorDelegate {

  private let coordinator = FKMediaPlaybackCoordinator()
  private let eventLog = FKVideoPlayerExampleEventLog()
  private lazy var logTextView = eventLog.makeTextView()

  private let statusLabel: UILabel = {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .subheadline)
    label.numberOfLines = 0
    return label
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Extended engine"
    view.backgroundColor = .systemGroupedBackground
    coordinator.delegate = self

    let caption = FKVideoPlayerExampleLayout.makeCaptionLabel(
      """
      FKKit does not bundle FFmpeg/VLC. ``FKExtendedPlayerEngine`` is AV best-effort only. \
      This app registers ``FKMediaExtendedEngineExampleFactory`` at launch (same AV path) to show the hook — \
      not real MKV/DASH playback. Use format probes offline; load MP4 to verify AV routing, then MKV/DASH to see failure.
      """
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    statusLabel.translatesAutoresizingMaskIntoConstraints = false
    logTextView.translatesAutoresizingMaskIntoConstraints = false

    let probe = FKVideoPlayerExampleLayout.makePrimaryButton("Run format probes", action: UIAction { [weak self] _ in
      self?.runFormatProbes()
    })
    let loadMP4 = FKVideoPlayerExampleLayout.makePrimaryButton("Load MP4 (should prepare)", action: UIAction { [weak self] _ in
      self?.loadSample(FKMediaPlayerCoreExampleSamples.progressiveMP4, label: "MP4")
    })
    let loadMKV = FKVideoPlayerExampleLayout.makePrimaryButton("Load MKV (expect failure)", action: UIAction { [weak self] _ in
      self?.loadSample(FKMediaPlayerCoreExampleSamples.syntheticMKV, label: "MKV")
    })
    let loadDASH = FKVideoPlayerExampleLayout.makePrimaryButton("Load DASH .mpd (expect failure)", action: UIAction { [weak self] _ in
      self?.loadSample(FKMediaPlayerCoreExampleSamples.syntheticDASH, label: "DASH")
    })
    let clear = FKVideoPlayerExampleLayout.makePrimaryButton("Clear log", action: UIAction { [weak self] _ in
      self?.clearLog()
    })

    let buttons = UIStackView(arrangedSubviews: [probe, loadMP4, loadMKV, loadDASH, clear])
    buttons.axis = .vertical
    buttons.spacing = 10
    buttons.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(caption)
    view.addSubview(statusLabel)
    view.addSubview(buttons)
    view.addSubview(logTextView)

    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

      statusLabel.topAnchor.constraint(equalTo: caption.bottomAnchor, constant: 12),
      statusLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      statusLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

      buttons.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 16),
      buttons.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      buttons.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

      logTextView.topAnchor.constraint(equalTo: buttons.bottomAnchor, constant: 16),
      logTextView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      logTextView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
      logTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])

    refreshStatus()
    appendLog("Open this screen after a cold launch so the example factory is registered in AppDelegate.")
  }

  // MARK: - Actions

  private func runFormatProbes() {
    appendLog("—— format probes (no network) ——")
    for sample in FKMediaPlayerCoreExampleSamples.probes {
      let descriptor = FKMediaFormatProbe.probe(url: sample.url)
      appendLog(
        """
        \(sample.label)
          suggested=\(descriptor.suggestedEngine.rawValue) \
          container=\(descriptor.container.rawValue) \
          delivery=\(descriptor.delivery.displayName) \
          allowsAV=\(descriptor.allowsAVFoundation) \
          allowsExtended=\(descriptor.allowsExtended)
        """
      )
    }
  }

  private func loadSample(_ item: FKMediaItem, label: String) {
    appendLog("load \(label) → coordinator…")
    coordinator.load(item, presentationMode: .video)
  }

  private func refreshStatus() {
    let registered = FKMediaPlayerExtended.hasRegisteredFactory
    let factoryName = registered ? "FKMediaExtendedEngineExampleFactory (AV best-effort stub)" : "none"
    statusLabel.text = "Extended factory: \(factoryName)\nActive engine: \(coordinator.engineKind.rawValue)"
  }

  private func appendLog(_ message: String) {
    eventLog.append(message)
    eventLog.refresh(logTextView)
  }

  private func clearLog() {
    eventLog.clear()
    eventLog.refresh(logTextView)
  }

  // MARK: - FKMediaPlaybackCoordinatorDelegate

  func mediaPlaybackCoordinator(
    _ coordinator: FKMediaPlaybackCoordinator,
    didChangeState state: FKMediaPlaybackState
  ) {
    appendLog("state → \(String(describing: state)) | engine=\(coordinator.engineKind.rawValue)")
    refreshStatus()
  }

  func mediaPlaybackCoordinator(
    _ coordinator: FKMediaPlaybackCoordinator,
    didFail error: FKMediaError
  ) {
    appendLog("didFail: \(error.localizedDescription)")
    refreshStatus()
  }

  func mediaPlaybackCoordinatorDidFinish(_ coordinator: FKMediaPlaybackCoordinator) {
    appendLog("didFinish")
  }
}
