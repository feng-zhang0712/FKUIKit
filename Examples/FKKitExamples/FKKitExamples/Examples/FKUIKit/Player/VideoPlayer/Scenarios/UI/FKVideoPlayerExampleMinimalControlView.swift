import FKUIKit
import UIKit

/// Minimal custom control surface for the custom-controls demo.
@MainActor
final class FKVideoPlayerExampleMinimalControlView: UIView, FKVideoPlayerControlView {

  var isControlsLocked = false

  private weak var player: FKVideoPlayer?
  private let label = UILabel()
  private let playButton = UIButton(type: .system)

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = UIColor.systemIndigo.withAlphaComponent(0.35)

    label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
    label.textColor = .white
    label.textAlignment = .center

    playButton.setTitle("Play/Pause", for: .normal)
    playButton.tintColor = .white
    playButton.addTarget(self, action: #selector(toggle), for: .touchUpInside)

    [label, playButton].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      addSubview($0)
    }
    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: topAnchor, constant: 8),
      label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
      label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
      playButton.centerXAnchor.constraint(equalTo: centerXAnchor),
      playButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func bind(player: FKVideoPlayer) {
    self.player = player
  }

  func update(
    state: FKMediaPlaybackState,
    currentTime: TimeInterval,
    duration: TimeInterval,
    buffered: [ClosedRange<TimeInterval>],
    isLive: Bool,
    liveLatency: TimeInterval?
  ) {
    // Minimal demo: ignore buffer/live fields.
    label.text = String(format: "%@  %.0f / %.0f", title(for: state), currentTime, duration)
  }

  func setControlsVisible(_ visible: Bool, animated: Bool) {
    alpha = visible ? 1 : 0.2
  }

  @objc
  private func toggle() {
    guard !isControlsLocked else { return }
    player?.togglePlayPause()
  }

  private func title(for state: FKMediaPlaybackState) -> String {
    switch state {
    case .playing, .buffering: return "Playing"
    case .paused: return "Paused"
    default: return "\(state)"
    }
  }
}
