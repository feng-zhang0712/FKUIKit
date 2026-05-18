import FKUIKit
import UIKit

/// Renders waveform samples from the active audio asset.
@MainActor
final class FKAudioPlayerWaveformExampleViewController: FKAudioPlayerExampleShellViewController {

  private let waveformView = FKAudioWaveformView()
  private let statusLabel = UILabel()
  private var loadGeneration = 0

  override func viewDidLoad() {
    title = "Waveform"
    super.viewDidLoad()

    let caption = FKAudioPlayerExampleLayout.makeCaptionLabel(
      "Downloads the track to a temp file and decodes PCM (independent of AVPlayer) for the waveform below."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    waveformView.translatesAutoresizingMaskIntoConstraints = false
    waveformView.backgroundColor = .tertiarySystemGroupedBackground
    waveformView.layer.cornerRadius = 8
    waveformView.barColor = view.tintColor

    statusLabel.font = .preferredFont(forTextStyle: .footnote)
    statusLabel.textColor = .secondaryLabel
    statusLabel.numberOfLines = 0
    statusLabel.text = "Waiting for track URL…"

    let reload = FKAudioPlayerExampleLayout.makePrimaryButton("Reload waveform", action: UIAction { [weak self] _ in
      Task { await self?.loadWaveform() }
    })
    let stack = UIStackView(arrangedSubviews: [waveformView, statusLabel, reload])
    stack.axis = .vertical
    stack.spacing = 8
    addFooterControls(stack)

    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
      waveformView.heightAnchor.constraint(equalToConstant: 72),
    ])
    finalizeLayout(topAnchor: caption.bottomAnchor)

    player.load(FKAudioPlayerExampleCatalog.trackOne(), autoPlay: true)
  }

  override func audioPlayer(_ player: FKAudioPlayer, didChangeState state: FKMediaPlaybackState) {
    super.audioPlayer(player, didChangeState: state)
    guard case .ready = state else { return }
    Task { await loadWaveform() }
  }

  override func audioPlayer(_ player: FKAudioPlayer, didChangeItem item: FKAudioItem?, index: Int?) {
    super.audioPlayer(player, didChangeItem: item, index: index)
    Task { await loadWaveform() }
  }

  private func loadWaveform() async {
    loadGeneration += 1
    let generation = loadGeneration

    statusLabel.text = "Loading waveform…"
    guard let url = player.currentItem?.source.primaryURL else {
      statusLabel.text = "No URL source on the current item."
      return
    }

    let result = await waveformView.loadWaveform(from: url, sampleCount: 96)
    guard generation == loadGeneration else { return }

    switch result {
    case let .success(count):
      statusLabel.text = "Waveform ready — \(count) bars (\(player.currentItem?.title ?? "—"))"
    case .noAudioTrack:
      statusLabel.text = "No audio track found in file."
    case .unreadableAsset:
      statusLabel.text = "File is not readable. Check network, then tap Reload."
    case let .readFailed(message):
      statusLabel.text = "Waveform failed: \(message)"
    }
  }
}
