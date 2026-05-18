import FKUIKit
import UIKit

/// Streams all ``FKAudioPlayerDelegate`` callbacks into the event log.
@MainActor
final class FKAudioPlayerDelegateLogExampleViewController: FKAudioPlayerExampleShellViewController {

  override func viewDidLoad() {
    title = "Delegate log"
    showsEventLog = true
    super.viewDidLoad()

    let caption = FKAudioPlayerExampleLayout.makeCaptionLabel(
      "Interact with transport controls and the queue to populate the log below."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    let clear = FKAudioPlayerExampleLayout.makeSecondaryButton("Clear log", action: UIAction { [weak self] _ in
      self?.clearEventLog()
    })
    addFooterControls(clear)

    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
    ])
    finalizeLayout(topAnchor: caption.bottomAnchor)

    player.loadQueue(FKAudioPlayerExampleCatalog.demoQueue(), autoPlay: true)
    appendLog("Delegate log ready")
  }
}
