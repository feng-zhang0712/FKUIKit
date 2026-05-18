import FKUIKit
import UIKit

/// Base screen with a bound ``FKAudioPlayerView`` and optional event log.
@MainActor
class FKAudioPlayerExampleShellViewController: UIViewController, FKAudioPlayerDelegate {

  let player = FKAudioPlayer()
  let eventLog = FKAudioPlayerExampleEventLog()

  private(set) var playerView: FKAudioPlayerView!
  private let playerContainer = UIView()
  private var logTextView: UITextView?
  private let footerStack = UIStackView()

  /// Inserts a control row above the optional event log.
  func addFooterControls(_ view: UIView) {
    footerStack.insertArrangedSubview(view, at: 0)
  }

  /// When true, a monospace log is shown under the player chrome.
  var showsEventLog = false

  /// Layout style passed to ``FKAudioPlayerView`` (default `.standard`).
  var playerViewStyle: FKAudioPlayerViewStyle = .standard

  /// Height of the player card relative to the safe area (default `0.4`).
  var playerHeightMultiplier: CGFloat = 0.4

  /// When true, lyrics render in a panel below the player card instead of inside ``FKAudioPlayerView``.
  var usesExternalLyricsPanel = false

  private var externalLyricsView: FKAudioLyricsView?
  private let externalLyricsContainer = UIView()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemGroupedBackground
    player.delegate = self
    // Examples always start from the beginning; Core resume is for production apps.
    player.configuration.media.playback.resumePlaybackEnabled = false

    playerContainer.backgroundColor = .secondarySystemGroupedBackground
    playerContainer.layer.cornerRadius = 12
    playerContainer.clipsToBounds = true
    playerContainer.translatesAutoresizingMaskIntoConstraints = false

    playerView = FKAudioPlayerView(style: playerViewStyle)
    playerView.translatesAutoresizingMaskIntoConstraints = false
    playerContainer.addSubview(playerView)
    NSLayoutConstraint.activate([
      playerView.topAnchor.constraint(equalTo: playerContainer.topAnchor),
      playerView.leadingAnchor.constraint(equalTo: playerContainer.leadingAnchor),
      playerView.trailingAnchor.constraint(equalTo: playerContainer.trailingAnchor),
      playerView.bottomAnchor.constraint(equalTo: playerContainer.bottomAnchor),
    ])
    player.bind(to: playerView)
    if usesExternalLyricsPanel {
      playerView.embedsLyricsInLayout = false
      configureExternalLyricsPanel()
    }

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
    if usesExternalLyricsPanel {
      view.addSubview(externalLyricsContainer)
    }
    view.addSubview(footerStack)
  }

  private func configureExternalLyricsPanel() {
    externalLyricsContainer.backgroundColor = .secondarySystemGroupedBackground
    externalLyricsContainer.layer.cornerRadius = 12
    externalLyricsContainer.clipsToBounds = true
    externalLyricsContainer.translatesAutoresizingMaskIntoConstraints = false

    let lyricsView = FKAudioLyricsView()
    lyricsView.translatesAutoresizingMaskIntoConstraints = false
    externalLyricsContainer.addSubview(lyricsView)
    NSLayoutConstraint.activate([
      lyricsView.topAnchor.constraint(equalTo: externalLyricsContainer.topAnchor, constant: 8),
      lyricsView.leadingAnchor.constraint(equalTo: externalLyricsContainer.leadingAnchor),
      lyricsView.trailingAnchor.constraint(equalTo: externalLyricsContainer.trailingAnchor),
      lyricsView.bottomAnchor.constraint(equalTo: externalLyricsContainer.bottomAnchor, constant: -8),
    ])
    externalLyricsView = lyricsView
  }

  /// Ensures the external lyrics panel exists when enabled after `viewDidLoad` (subclasses may flip the flag late).
  private func ensureExternalLyricsPanelAttached() {
    guard usesExternalLyricsPanel else { return }
    playerView.embedsLyricsInLayout = false
    if externalLyricsView == nil {
      configureExternalLyricsPanel()
    }
    if externalLyricsContainer.superview == nil {
      view.insertSubview(externalLyricsContainer, belowSubview: footerStack)
    }
  }

  /// Call after `viewDidLoad` once subclasses build their caption or controls.
  func finalizeLayout(topAnchor: NSLayoutYAxisAnchor) {
    ensureExternalLyricsPanelAttached()

    var constraints: [NSLayoutConstraint] = [
      playerContainer.topAnchor.constraint(equalTo: topAnchor, constant: 12),
      playerContainer.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      playerContainer.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
      playerContainer.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: playerHeightMultiplier),
    ]

    let footerTopAnchor: NSLayoutYAxisAnchor
    if usesExternalLyricsPanel {
      constraints += [
        externalLyricsContainer.topAnchor.constraint(equalTo: playerContainer.bottomAnchor, constant: 12),
        externalLyricsContainer.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
        externalLyricsContainer.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
        externalLyricsContainer.heightAnchor.constraint(equalToConstant: 168),
      ]
      footerTopAnchor = externalLyricsContainer.bottomAnchor
    } else {
      footerTopAnchor = playerContainer.bottomAnchor
    }

    constraints += [
      footerStack.topAnchor.constraint(equalTo: footerTopAnchor, constant: 12),
      footerStack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      footerStack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
      footerStack.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ]
    NSLayoutConstraint.activate(constraints)
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

  // MARK: - FKAudioPlayerDelegate

  func audioPlayer(_ player: FKAudioPlayer, didChangeState state: FKMediaPlaybackState) {
    appendLog("state → \(String(describing: state))")
  }

  func audioPlayer(_ player: FKAudioPlayer, didUpdateTime current: TimeInterval, duration: TimeInterval) {
    guard showsEventLog else { return }
    if Int(current) % 5 == 0, abs(current - floor(current)) < 0.25 {
      appendLog(String(format: "time %.1f / %.1f", current, duration))
    }
  }

  func audioPlayer(_ player: FKAudioPlayer, didChangeItem item: FKAudioItem?, index: Int?) {
    appendLog("item → \(item?.title ?? "—") index=\(index.map(String.init) ?? "nil")")
  }

  func audioPlayerDidFinish(_ player: FKAudioPlayer) {
    appendLog("finished")
  }

  func audioPlayer(_ player: FKAudioPlayer, didFail error: FKMediaError) {
    appendLog("failed → \(error.localizedDescription)")
  }

  func audioPlayer(_ player: FKAudioPlayer, didUpdateLyricsLine index: Int?) {
    externalLyricsView?.highlightLine(at: index)
    guard showsEventLog else { return }
    appendLog("lyrics line → \(index.map(String.init) ?? "nil")")
  }

  func audioPlayer(_ player: FKAudioPlayer, didLoadLyrics lines: [FKAudioLyricLine]) {
    externalLyricsView?.setLines(lines)
  }

  func audioPlayer(_ player: FKAudioPlayer, didChangeQueueIndex index: Int?) {
    appendLog("queue index → \(index.map(String.init) ?? "nil")")
  }
}
