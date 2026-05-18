import FKUIKit
import UIKit

/// Surfaces every ``FKVideoPlayerDelegate`` callback in the event log.
@MainActor
final class FKVideoPlayerDelegateLogExampleViewController: FKVideoPlayerExampleShellViewController {

  override func viewDidLoad() {
    title = "Delegate log"
    showsEventLog = true
    super.viewDidLoad()

    let caption = FKVideoPlayerExampleLayout.makeCaptionLabel(
      "Interact with the player to populate the log. Throttled time updates every ~5 seconds."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    let clear = FKVideoPlayerExampleLayout.makePrimaryButton("Clear log", action: UIAction { [weak self] _ in
      self?.clearEventLog()
    })
    addFooterControls(clear)

    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
    ])
    finalizeLayout(topAnchor: caption.bottomAnchor)

    appendLog("ready")
    player.load(FKVideoPlayerExampleCatalog.progressiveItem())
    player.play()
  }
}
