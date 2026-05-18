import FKUIKit
import UIKit

/// Exercises the SharePlay stub coordinator shipped with the module.
@MainActor
final class FKVideoPlayerSharePlayExampleViewController: FKVideoPlayerExampleShellViewController {

  private let resultLabel = UILabel()

  override func viewDidLoad() {
    title = "SharePlay hook"
    showsEventLog = true
    super.viewDidLoad()

    let caption = FKVideoPlayerExampleLayout.makeCaptionLabel(
      "The default coordinator throws `notImplemented` until Group Activities is integrated in the host app."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    resultLabel.font = .preferredFont(forTextStyle: .footnote)
    resultLabel.textColor = .secondaryLabel
    resultLabel.numberOfLines = 0

    let start = FKVideoPlayerExampleLayout.makePrimaryButton("startSharePlay()", action: UIAction { [weak self] _ in
      Task { await self?.attemptSharePlay() }
    })
    let stack = UIStackView(arrangedSubviews: [resultLabel, start])
    stack.axis = .vertical
    stack.spacing = 8
    addFooterControls(stack)

    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
    ])
    finalizeLayout(topAnchor: caption.bottomAnchor)

    player.load(FKVideoPlayerExampleCatalog.progressiveItem())
  }

  private func attemptSharePlay() async {
    guard let item = player.currentItem else { return }
    do {
      try await player.sharePlayCoordinator.startSharePlay(for: item)
      resultLabel.text = "SharePlay started (unexpected in stub build)."
      appendLog("sharePlay started")
    } catch {
      resultLabel.text = error.localizedDescription
      appendLog("sharePlay error")
    }
  }
}
