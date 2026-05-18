import FKUIKit
import UIKit

/// Starts an HLS offline download and plays from the registry when complete.
@MainActor
final class FKVideoPlayerOfflineExampleViewController: FKVideoPlayerExampleShellViewController, FKMediaHLSDownloadServiceDelegate {

  private let statusLabel = UILabel()
  private var downloadID: String?

  override func viewDidLoad() {
    title = "Offline HLS"
    showsEventLog = true
    super.viewDidLoad()

    player.offlineDownloadManager.delegate = self

    let caption = FKVideoPlayerExampleLayout.makeCaptionLabel(
      "Downloads Apple's sample HLS asset. Playback uses `FKMediaSource.offline` after completion."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    statusLabel.font = .preferredFont(forTextStyle: .footnote)
    statusLabel.textColor = .secondaryLabel
    statusLabel.numberOfLines = 0
    statusLabel.text = "Idle"

    let start = FKVideoPlayerExampleLayout.makePrimaryButton("Start download", action: UIAction { [weak self] _ in
      self?.startDownload()
    })
    let play = FKVideoPlayerExampleLayout.makePrimaryButton("Play offline copy", action: UIAction { [weak self] _ in
      self?.playOffline()
    })

    let stack = UIStackView(arrangedSubviews: [statusLabel, start, play])
    stack.axis = .vertical
    stack.spacing = 8
    addFooterControls(stack)

    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
    ])
    finalizeLayout(topAnchor: caption.bottomAnchor)
  }

  private func startDownload() {
    downloadID = player.offlineDownloadManager.startDownload(
      from: FKVideoPlayerExampleCatalog.hlsVOD,
      title: "Offline sample"
    )
    statusLabel.text = "Downloading id=\(downloadID ?? "—")…"
    appendLog("download started")
  }

  private func playOffline() {
    guard let id = downloadID,
          let item = player.offlineDownloadManager.makeOfflineItem(downloadIdentifier: id, title: "Offline sample") else {
      statusLabel.text = "No offline asset yet."
      return
    }
    player.load(item)
    player.play()
    appendLog("playing offline package")
  }

  // MARK: - FKMediaHLSDownloadServiceDelegate

  func hlsDownloadService(
    _ service: FKMediaHLSDownloadService,
    didUpdateProgress progress: Float,
    for downloadIdentifier: String
  ) {
    statusLabel.text = String(format: "Progress %.0f%%", progress * 100)
  }

  func hlsDownloadService(
    _ service: FKMediaHLSDownloadService,
    didFinish downloadIdentifier: String,
    localURL: URL
  ) {
    statusLabel.text = "Finished — tap Play offline copy"
    appendLog("download finished → \(localURL.lastPathComponent)")
  }

  func hlsDownloadService(
    _ service: FKMediaHLSDownloadService,
    didFail downloadIdentifier: String,
    error: Error
  ) {
    statusLabel.text = "Failed: \(error.localizedDescription)"
    appendLog("download failed")
  }
}
