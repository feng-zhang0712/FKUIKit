import FKUIKit
import UIKit

/// Interactive toggles for transport, UI, and thumbnail scrubbing.
@MainActor
final class FKVideoPlayerPlaygroundExampleViewController: FKVideoPlayerExampleShellViewController {

  private let rateLabel = UILabel()

  override func viewDidLoad() {
    title = "Playground"
    super.viewDidLoad()

    let caption = FKVideoPlayerExampleLayout.makeCaptionLabel(
      "Scrub the progress bar to preview frames when a thumbnail provider is attached."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    rateLabel.font = .preferredFont(forTextStyle: .footnote)
    rateLabel.textColor = .secondaryLabel

    let mute = UISwitch()
    mute.addAction(UIAction { [weak self] _ in self?.player.isMuted = mute.isOn }, for: .valueChanged)
    let muteRow = labeledRow(title: "Muted", control: mute)

    let llhls = UISwitch()
    llhls.addAction(UIAction { [weak self] _ in
      self?.player.setLowLatencyHLS(enabled: llhls.isOn)
      self?.player.showsLLHLSDebugPanel = llhls.isOn
    }, for: .valueChanged)

    let remaining = UISwitch()
    remaining.isOn = player.configuration.ui.showsRemainingTime
    remaining.addAction(UIAction { [weak self] _ in
      self?.player.configuration.ui.showsRemainingTime = remaining.isOn
      self?.playerView.apply(uiConfiguration: self?.player.configuration.ui ?? .default)
    }, for: .valueChanged)

    let rateDown = FKVideoPlayerExampleLayout.makePrimaryButton("Slower", action: UIAction { [weak self] _ in
      self?.adjustRate(by: -0.25)
    })
    let rateUp = FKVideoPlayerExampleLayout.makePrimaryButton("Faster", action: UIAction { [weak self] _ in
      self?.adjustRate(by: 0.25)
    })
    let rateRow = UIStackView(arrangedSubviews: [rateDown, rateUp])
    rateRow.axis = .horizontal
    rateRow.spacing = 8
    rateRow.distribution = .fillEqually

    let stack = UIStackView(arrangedSubviews: [
      muteRow,
      labeledRow(title: "LL-HLS + debug panel", control: llhls),
      labeledRow(title: "Remaining time label", control: remaining),
      rateLabel,
      rateRow,
    ])
    stack.axis = .vertical
    stack.spacing = 8
    addFooterControls(stack)

    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
    ])
    finalizeLayout(topAnchor: caption.bottomAnchor)

    player.thumbnailProvider = FKVideoPlayerExampleThumbnailProvider(player: player)
    player.load(FKVideoPlayerExampleCatalog.progressiveItem())
    updateRateLabel()
    player.play()
  }

  private func adjustRate(by delta: Float) {
    player.rate = max(0.25, min(2.0, player.rate + delta))
    updateRateLabel()
  }

  private func updateRateLabel() {
    rateLabel.text = String(format: "Playback rate: %.2fx", player.rate)
  }

  private func labeledRow(title: String, control: UIView) -> UIStackView {
    let label = UILabel()
    label.text = title
    label.font = .preferredFont(forTextStyle: .subheadline)
    let row = UIStackView(arrangedSubviews: [label, control])
    row.axis = .horizontal
    row.alignment = .center
    row.distribution = .equalSpacing
    return row
  }
}
