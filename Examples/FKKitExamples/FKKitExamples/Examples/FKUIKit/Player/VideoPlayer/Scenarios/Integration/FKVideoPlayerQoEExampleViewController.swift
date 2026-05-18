import FKUIKit
import UIKit

/// Attaches ``FKVideoQoEReporter`` and prints QoE snapshots.
@MainActor
final class FKVideoPlayerQoEExampleViewController: FKVideoPlayerExampleShellViewController {

  private let snapshotLabel = UILabel()

  override func viewDidLoad() {
    title = "QoE reporter"
    super.viewDidLoad()

    let caption = FKVideoPlayerExampleLayout.makeCaptionLabel(
      "QoE plugin is attached in `FKVideoPlayer` init via `qoeReporter.attach(to:)`."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    snapshotLabel.font = .preferredFont(forTextStyle: .footnote)
    snapshotLabel.textColor = .secondaryLabel
    snapshotLabel.numberOfLines = 0

    let snapshot = FKVideoPlayerExampleLayout.makePrimaryButton("Print QoE snapshot", action: UIAction { [weak self] _ in
      self?.printSnapshot()
    })
    let stack = UIStackView(arrangedSubviews: [snapshotLabel, snapshot])
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
    player.play()
    printSnapshot()
  }

  private func printSnapshot() {
    let snap = player.qoeReporter.snapshot()
    snapshotLabel.text = """
    stalls=\(snap.stallCount) errors=\(snap.errorCount) \
    playTime=\(String(format: "%.1f", snap.totalPlaySeconds))s \
    lastError=\(snap.lastError.map { String(describing: $0) } ?? "none")
    """
  }
}
