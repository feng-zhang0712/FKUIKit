import FKUIKit
import UIKit

/// Cross-track fade, playback rate, and per-item rate memory.
@MainActor
final class FKAudioPlayerPlaygroundExampleViewController: FKAudioPlayerExampleShellViewController {

  private let settingsLabel = UILabel()

  override func viewDidLoad() {
    title = "Playground"
    super.viewDidLoad()

    let caption = FKAudioPlayerExampleLayout.makeCaptionLabel(
      """
      Fade controls cross-track transitions. The Rate slider sets playback speed (0.5×–2×) on the bound \
      player; the transport “1.0x” button cycles presets and mirrors the current rate. Rate memory applies \
      when `remembersRatePerItem` is enabled.
      """
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    settingsLabel.font = .preferredFont(forTextStyle: .footnote)
    settingsLabel.textColor = .secondaryLabel
    settingsLabel.numberOfLines = 0
    refreshSettingsLabel()

    let fadeSlider = UISlider()
    fadeSlider.minimumValue = 0
    fadeSlider.maximumValue = 2
    fadeSlider.value = 0.8
    fadeSlider.addAction(UIAction { [weak self] action in
      guard let self, let slider = action.sender as? UISlider else { return }
      let value = TimeInterval(slider.value)
      self.player.configuration.playback.fadeBetweenTracksDuration = value > 0.05 ? value : nil
      self.refreshSettingsLabel()
    }, for: .valueChanged)

    let rateSlider = UISlider()
    rateSlider.minimumValue = 0.5
    rateSlider.maximumValue = 2
    rateSlider.value = 1
    rateSlider.addAction(UIAction { [weak self] action in
      guard let self, let slider = action.sender as? UISlider else { return }
      self.player.rate = slider.value
      self.playerView.syncPlaybackRateDisplay()
      self.refreshSettingsLabel()
    }, for: .valueChanged)

    let memorySwitch = UISwitch()
    memorySwitch.isOn = true
    memorySwitch.addAction(UIAction { [weak self] action in
      guard let self, let control = action.sender as? UISwitch else { return }
      self.player.configuration.playback.remembersRatePerItem = control.isOn
      self.refreshSettingsLabel()
    }, for: .valueChanged)

    let memoryRow = UIStackView(arrangedSubviews: [
      FKAudioPlayerExampleLayout.makeSectionLabel("Remember rate per item"),
      memorySwitch,
    ])
    memoryRow.axis = .horizontal
    memoryRow.alignment = .center
    memoryRow.distribution = .equalSpacing

    let stack = UIStackView(arrangedSubviews: [
      settingsLabel,
      FKAudioPlayerExampleLayout.makeSectionLabel("Fade (seconds)"),
      fadeSlider,
      FKAudioPlayerExampleLayout.makeSectionLabel("Rate"),
      rateSlider,
      memoryRow,
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

    player.configuration.playback.fadeBetweenTracksDuration = 0.8
    player.configuration.playback.remembersRatePerItem = true
    player.loadQueue(FKAudioPlayerExampleCatalog.demoQueue(), autoPlay: true)
  }

  private func refreshSettingsLabel() {
    let fade = player.configuration.playback.fadeBetweenTracksDuration.map { String(format: "%.2fs", $0) } ?? "off"
    settingsLabel.text = """
    Fade: \(fade)
    Rate: \(String(format: "%.2fx", player.rate))
    Memory: \(player.configuration.playback.remembersRatePerItem ? "on" : "off")
    """
  }

  override func audioPlayer(_ player: FKAudioPlayer, didChangeItem item: FKAudioItem?, index: Int?) {
    super.audioPlayer(player, didChangeItem: item, index: index)
    playerView.syncPlaybackRateDisplay()
    refreshSettingsLabel()
  }
}
