import FKUIKit
import UIKit

/// Stops advancing the queue after the current item finishes.
@MainActor
final class FKAudioPlayerStopAfterCurrentExampleViewController: FKAudioPlayerExampleShellViewController {

  private let statusLabel = UILabel()

  override func viewDidLoad() {
    title = "Stop after current"
    showsEventLog = true
    super.viewDidLoad()

    let caption = FKAudioPlayerExampleLayout.makeCaptionLabel(
      "When enabled, the player pauses instead of advancing to the next queue item."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    statusLabel.font = .preferredFont(forTextStyle: .footnote)
    statusLabel.textColor = .secondaryLabel
    statusLabel.text = "Stop after current: off"

    let toggle = UISwitch()
    toggle.addAction(UIAction { [weak self] action in
      guard let self, let control = action.sender as? UISwitch else { return }
      self.player.setStopAfterCurrentItem(control.isOn)
      self.statusLabel.text = "Stop after current: \(control.isOn ? "on" : "off")"
    }, for: .valueChanged)
    let row = UIStackView(arrangedSubviews: [statusLabel, toggle])
    row.axis = .horizontal
    row.spacing = 12
    row.alignment = .center
    addFooterControls(row)

    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
    ])
    finalizeLayout(topAnchor: caption.bottomAnchor)

    player.loadQueue(FKAudioPlayerExampleCatalog.demoQueue(), autoPlay: true)
  }
}
