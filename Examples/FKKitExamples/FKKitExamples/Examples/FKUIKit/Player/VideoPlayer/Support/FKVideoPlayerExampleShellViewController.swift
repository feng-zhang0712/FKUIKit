import FKUIKit
import UIKit

/// Base screen with a bound ``FKVideoPlayerView`` and optional event log.
@MainActor
class FKVideoPlayerExampleShellViewController: UIViewController, FKVideoPlayerDelegate {

  let player = FKVideoPlayer()
  let eventLog = FKVideoPlayerExampleEventLog()

  private(set) var playerView: FKVideoPlayerView!
  private let playerContainer = UIView()
  private var logTextView: UITextView?
  private let footerStack = UIStackView()

  /// Inserts a control row above the optional event log.
  func addFooterControls(_ view: UIView) {
    footerStack.insertArrangedSubview(view, at: 0)
  }

  /// When true, a monospace log is shown under the player chrome.
  var showsEventLog = false

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground
    player.delegate = self
    // Examples always start from the beginning; Core resume is for production apps.
    player.configuration.media.playback.resumePlaybackEnabled = false
    playerContainer.backgroundColor = .black
    playerContainer.layer.cornerRadius = 12
    playerContainer.clipsToBounds = true
    playerContainer.translatesAutoresizingMaskIntoConstraints = false

    playerView = FKVideoPlayerView()
    playerView.translatesAutoresizingMaskIntoConstraints = false
    playerContainer.addSubview(playerView)
    NSLayoutConstraint.activate([
      playerView.topAnchor.constraint(equalTo: playerContainer.topAnchor),
      playerView.leadingAnchor.constraint(equalTo: playerContainer.leadingAnchor),
      playerView.trailingAnchor.constraint(equalTo: playerContainer.trailingAnchor),
      playerView.bottomAnchor.constraint(equalTo: playerContainer.bottomAnchor),
    ])
    player.bind(to: playerView)

    footerStack.axis = .vertical
    footerStack.spacing = 12
    footerStack.translatesAutoresizingMaskIntoConstraints = false

    if showsEventLog {
      let log = eventLog.makeTextView()
      log.translatesAutoresizingMaskIntoConstraints = false
      log.heightAnchor.constraint(equalToConstant: 140).isActive = true
      logTextView = log
      footerStack.addArrangedSubview(log)
    }

    view.addSubview(playerContainer)
    view.addSubview(footerStack)
  }

  /// Call after `viewDidLoad` once subclasses build their control rows.
  func finalizeLayout(topAnchor: NSLayoutYAxisAnchor) {
    NSLayoutConstraint.activate([
      playerContainer.topAnchor.constraint(equalTo: topAnchor, constant: 12),
      playerContainer.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      playerContainer.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
      playerContainer.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.38),

      footerStack.topAnchor.constraint(equalTo: playerContainer.bottomAnchor, constant: 12),
      footerStack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      footerStack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
      footerStack.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])
  }

  func appendLog(_ message: String) {
    eventLog.append(message)
    if let logTextView {
      eventLog.refresh(logTextView)
    }
  }

  func clearEventLog() {
    eventLog.clear()
    if let logTextView {
      eventLog.refresh(logTextView)
    }
  }

  // MARK: - FKVideoPlayerDelegate

  func videoPlayer(_ player: FKVideoPlayer, didChangeState state: FKMediaPlaybackState) {
    appendLog("state → \(String(describing: state))")
  }

  func videoPlayer(_ player: FKVideoPlayer, didUpdateTime current: TimeInterval, duration: TimeInterval) {
    guard showsEventLog else { return }
    if Int(current) % 5 == 0, abs(current - floor(current)) < 0.25 {
      appendLog(String(format: "time %.1f / %.1f", current, duration))
    }
  }

  func videoPlayer(_ player: FKVideoPlayer, didUpdateBuffered ranges: [ClosedRange<TimeInterval>]) {
    guard showsEventLog, let end = ranges.map(\.upperBound).max() else { return }
    appendLog(String(format: "buffered → %.1fs", end))
  }

  func videoPlayerDidFinish(_ player: FKVideoPlayer) {
    appendLog("finished")
  }

  func videoPlayer(_ player: FKVideoPlayer, didFail error: FKMediaError) {
    appendLog("failed → \(error.localizedDescription)")
  }

  func videoPlayer(_ player: FKVideoPlayer, didToggleFullscreen isFullscreen: Bool) {
    appendLog("fullscreen → \(isFullscreen)")
  }

  func videoPlayer(
    _ player: FKVideoPlayer,
    didAdvanceTo item: FKVideoItem?,
    at index: Int,
    in playlist: FKVideoPlaylist?
  ) {
    appendLog("playlist → index \(index) title=\(item?.title ?? "—")")
  }
}
