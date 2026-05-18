import FKUIKit
import UIKit

/// Mutates the in-memory queue while playback is active.
@MainActor
final class FKAudioPlayerQueueEditingExampleViewController: FKAudioPlayerExampleShellViewController {

  private let queueLabel = UILabel()

  override func viewDidLoad() {
    title = "Queue editing"
    super.viewDidLoad()

    let caption = FKAudioPlayerExampleLayout.makeCaptionLabel(
      "Demonstrates `insertNext`, `append`, and `remove(at:)` on ``FKAudioQueue``."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    queueLabel.font = .preferredFont(forTextStyle: .footnote)
    queueLabel.textColor = .secondaryLabel
    queueLabel.numberOfLines = 0

    let insertNext = FKAudioPlayerExampleLayout.makePrimaryButton("Insert next track", action: UIAction { [weak self] _ in
      self?.player.queue.insertNext(FKAudioPlayerExampleCatalog.insertNextCandidate())
      self?.refreshQueueLabel()
    })
    let append = FKAudioPlayerExampleLayout.makeSecondaryButton("Append track", action: UIAction { [weak self] _ in
      self?.player.queue.append(FKAudioPlayerExampleCatalog.trackThree(title: "Appended track"))
      self?.refreshQueueLabel()
    })
    let remove = FKAudioPlayerExampleLayout.makeSecondaryButton("Remove current", action: UIAction { [weak self] _ in
      guard let self, let index = self.player.currentIndex else { return }
      self.player.queue.remove(at: index)
      self.refreshQueueLabel()
    })
    let stack = UIStackView(arrangedSubviews: [queueLabel, insertNext, append, remove])
    stack.axis = .vertical
    stack.spacing = 8
    addFooterControls(stack)

    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
    ])
    finalizeLayout(topAnchor: caption.bottomAnchor)

    player.load(FKAudioPlayerExampleCatalog.trackOne(), autoPlay: true)
    refreshQueueLabel()
  }

  private func refreshQueueLabel() {
    let titles = player.queue.items.map { $0.title ?? "—" }.joined(separator: " → ")
    queueLabel.text = "Queue (\(player.queue.items.count)): \(titles)"
  }
}
