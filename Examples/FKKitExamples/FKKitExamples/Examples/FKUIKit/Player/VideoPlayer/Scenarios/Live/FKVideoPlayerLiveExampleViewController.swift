import FKUIKit
import UIKit

/// Live HLS stream with go-live affordances.
@MainActor
final class FKVideoPlayerLiveExampleViewController: FKVideoPlayerExampleShellViewController {

  override func viewDidLoad() {
    title = "Live HLS"
    super.viewDidLoad()

    let caption = FKVideoPlayerExampleLayout.makeCaptionLabel(
      "When `isLive` is true the live badge appears. Tap Go Live or use the control below."
    )
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    let goLive = FKVideoPlayerExampleLayout.makePrimaryButton("Seek to live edge", action: UIAction { [weak self] _ in
      self?.player.seekToLiveEdge()
    })
    let debug = UISwitch()
    debug.addAction(UIAction { [weak self] _ in
      self?.player.showsLLHLSDebugPanel = debug.isOn
      self?.player.setLowLatencyHLS(enabled: debug.isOn)
    }, for: .valueChanged)

    let debugRow = UIStackView(arrangedSubviews: [UILabel(text: "LL-HLS debug"), debug])
    debugRow.axis = .horizontal
    debugRow.alignment = .center
    debugRow.distribution = .equalSpacing

    let stack = UIStackView(arrangedSubviews: [goLive, debugRow])
    stack.axis = .vertical
    stack.spacing = 8
    addFooterControls(stack)

    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
    ])
    finalizeLayout(topAnchor: caption.bottomAnchor)

    player.load(FKVideoPlayerExampleCatalog.hlsLiveItem())
    player.play()
  }
}

private extension UILabel {
  convenience init(text: String) {
    self.init()
    self.text = text
    font = .preferredFont(forTextStyle: .subheadline)
  }
}
