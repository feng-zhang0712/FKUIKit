import UIKit

/// Layout style for ``FKAudioPlayerView``.
public enum FKAudioPlayerViewStyle: Sendable {
  case standard
  case compact
  case miniBar
}

/// Full audio player chrome with artwork, controls, and optional lyrics.
@MainActor
public final class FKAudioPlayerView: UIView {

  private let style: FKAudioPlayerViewStyle
  private weak var player: FKAudioPlayer?

  /// When `false`, lyrics are not laid out inside the player chrome (use an external ``FKAudioLyricsView``).
  public var embedsLyricsInLayout = true

  private let artworkView = UIImageView()
  private let titleLabel = UILabel()
  private let artistLabel = UILabel()
  private let controlsView = FKAudioControlsView()
  private let lyricsView = FKAudioLyricsView()
  private var retryButton: UIButton?
  private var lastToastErrorDescription: String?
  private var queueModeToastHandle: FKToastHandle?
  private let queueModeButton = UIButton(type: .system)
  private let sleepButton = UIButton(type: .system)

  private let compactChromeTrailing: CGFloat = 96

  public init(style: FKAudioPlayerViewStyle = .standard) {
    self.style = style
    super.init(frame: .zero)
    backgroundColor = .systemBackground
    setupViews()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    let safe = safeAreaInsets
    let width = bounds.width
    let height = bounds.height

    switch style {
    case .standard:
      layoutStandard(width: width, height: height, safe: safe)
    case .compact:
      layoutCompact(width: width, height: height, safe: safe)
    case .miniBar:
      layoutMiniBar(width: width, height: height)
    }

    if style != .miniBar {
      layoutRetryButton()
      queueModeButton.frame = CGRect(x: width - 120, y: safe.top + 12, width: 44, height: 32)
      sleepButton.frame = CGRect(x: width - 68, y: safe.top + 12, width: 44, height: 32)
      queueModeButton.isHidden = false
      sleepButton.isHidden = false
    } else {
      queueModeButton.isHidden = true
      sleepButton.isHidden = true
    }

    if let retryButton { bringSubviewToFront(retryButton) }
    bringSubviewToFront(controlsView)
    if style != .miniBar {
      bringSubviewToFront(queueModeButton)
      bringSubviewToFront(sleepButton)
    }
  }

  public func bind(player: FKAudioPlayer) {
    self.player = player
    controlsView.bind(player: player)
    let tint = player.configuration.ui.resolvedTintColor(traitCollection: traitCollection)
    controlsView.applyTheme(tint)
    queueModeButton.tintColor = tint
    sleepButton.tintColor = tint
    refreshQueueModeChrome()
    if let item = player.currentItem {
      reload(for: item)
    }
  }

  /// Syncs queue-mode and sleep chrome with ``FKAudioPlayer/queue``.
  public func refreshQueueModeChrome() {
    guard let mode = player?.queue.mode else { return }
    let symbol: String
    let accessibilityValue: String
    switch mode {
    case .sequential:
      symbol = "arrow.triangle.2.circlepath"
      accessibilityValue = "Sequential"
    case .shuffle:
      symbol = "shuffle"
      accessibilityValue = "Shuffle"
    case .repeatAll:
      symbol = "repeat"
      accessibilityValue = "Repeat all"
    case .repeatOne:
      symbol = "repeat.1"
      accessibilityValue = "Repeat one"
    }
    queueModeButton.setImage(UIImage(systemName: symbol), for: .normal)
    queueModeButton.accessibilityLabel = "Queue mode"
    queueModeButton.accessibilityValue = accessibilityValue
    sleepButton.accessibilityLabel = FKAudioPlayerStrings.sleepTimer
  }

  public func reload(for item: FKAudioItem) {
    titleLabel.text = item.title ?? "Unknown Title"
    artistLabel.text = item.artist ?? "Unknown Artist"
    loadArtwork(url: item.artworkURL)
  }

  public func setLyrics(lines: [FKAudioLyricLine]) {
    lyricsView.setLines(lines)
    let showsLyrics = embedsLyricsInLayout && style == .standard && !lines.isEmpty
    lyricsView.isHidden = !showsLyrics
    setNeedsLayout()
  }

  public func highlightLyricLine(at index: Int?) {
    lyricsView.highlightLine(at: index)
  }

  public func handleStateChange(_ state: FKMediaPlaybackState) {
    controlsView.update(
      state: state,
      currentTime: player?.currentTime ?? 0,
      duration: player?.duration ?? 0,
      buffered: player?.bufferedTimeRanges ?? []
    )
    switch state {
    case .preparing, .buffering:
      lastToastErrorDescription = nil
      hideRetryButton()
    case .failed(let error):
      presentPlaybackError(error)
    default:
      lastToastErrorDescription = nil
      hideRetryButton()
    }
  }

  public func updateProgress(
    current: TimeInterval,
    duration: TimeInterval,
    buffered: [ClosedRange<TimeInterval>]
  ) {
    controlsView.update(
      state: player?.state ?? .idle,
      currentTime: current,
      duration: duration,
      buffered: buffered
    )
  }

  /// Refreshes the transport rate label after external rate changes (e.g. playground sliders).
  public func syncPlaybackRateDisplay() {
    controlsView.syncPlaybackRateDisplay()
  }

  /// Suggested height when embedding in Auto Layout or SwiftUI hosts (standard chrome, no lyrics).
  public static var standardPreferredHeight: CGFloat { 360 }

  public func reset() {
    artworkView.image = nil
    titleLabel.text = nil
    artistLabel.text = nil
    lyricsView.setLines([])
    lastToastErrorDescription = nil
    hideRetryButton()
  }

  // MARK: - Private

  private func setupViews() {
    artworkView.contentMode = .scaleAspectFill
    artworkView.clipsToBounds = true
    artworkView.layer.cornerRadius = style == .miniBar ? 8 : 12
    artworkView.backgroundColor = .secondarySystemFill

    titleLabel.font = .systemFont(ofSize: style == .miniBar ? 14 : 20, weight: .semibold)
    titleLabel.textAlignment = style == .standard ? .center : .left
    titleLabel.lineBreakMode = .byTruncatingTail

    artistLabel.font = .systemFont(ofSize: style == .miniBar ? 12 : 15, weight: .regular)
    artistLabel.textColor = .secondaryLabel
    artistLabel.textAlignment = style == .standard ? .center : .left
    artistLabel.lineBreakMode = .byTruncatingTail

    queueModeButton.setImage(UIImage(systemName: "arrow.triangle.2.circlepath"), for: .normal)
    queueModeButton.addTarget(self, action: #selector(cycleQueueMode), for: .touchUpInside)

    sleepButton.setImage(UIImage(systemName: "moon.zzz"), for: .normal)
    sleepButton.addTarget(self, action: #selector(scheduleSleep), for: .touchUpInside)

    [artworkView, titleLabel, artistLabel, lyricsView, controlsView, queueModeButton, sleepButton].forEach {
      addSubview($0)
    }

    if style == .miniBar {
      controlsView.layoutStyle = .miniBar
      controlsView.isUserInteractionEnabled = true
      queueModeButton.isHidden = true
      sleepButton.isHidden = true
      lyricsView.isHidden = true
      backgroundColor = .clear
    }
  }

  private func layoutMiniBar(width: CGFloat, height: CGFloat) {
    let artworkSize = FKAudioMiniBarChromeMetrics.artworkSize
    let playSize = FKAudioMiniBarChromeMetrics.playButtonSize
    let gap = FKAudioMiniBarChromeMetrics.itemSpacing
    let textWidth = FKAudioMiniBarChromeMetrics.textWidth(for: width)

    let artworkY = (height - artworkSize) / 2
    artworkView.frame = CGRect(
      x: FKAudioMiniBarChromeMetrics.leadingInset,
      y: artworkY,
      width: artworkSize,
      height: artworkSize
    )

    let textX = artworkView.frame.maxX + gap
    let titleHeight: CGFloat = 18
    let artistHeight: CGFloat = 15
    let textBlockHeight = titleHeight + 2 + artistHeight
    let textY = (height - textBlockHeight) / 2
    titleLabel.frame = CGRect(x: textX, y: textY, width: textWidth, height: titleHeight)
    artistLabel.frame = CGRect(x: textX, y: textY + titleHeight + 2, width: textWidth, height: artistHeight)

    let playX = width - FKAudioMiniBarChromeMetrics.trailingInset - playSize
    let playY = (height - playSize) / 2
    controlsView.frame = CGRect(x: 0, y: 0, width: width, height: height)
    controlsView.playPauseButton.frame = CGRect(x: playX, y: playY, width: playSize, height: playSize)
    controlsView.syncMiniBarPlaySpinner()
    lyricsView.isHidden = true
  }

  private func layoutStandard(width: CGFloat, height: CGFloat, safe: UIEdgeInsets) {
    let controlsHeight = FKAudioControlsView.preferredHeight
    let bottomInset = safe.bottom
    let reservedBottom = controlsHeight + bottomInset
    let availableHeader = max(120, height - reservedBottom)
    let artworkScale: CGFloat = embedsLyricsInLayout ? 0.52 : 0.38
    let artSize = min(width - 48, availableHeader * artworkScale)

    artworkView.frame = CGRect(x: (width - artSize) / 2, y: safe.top + 16, width: artSize, height: artSize)
    titleLabel.frame = CGRect(x: 24, y: artworkView.frame.maxY + 12, width: width - 48, height: 28)
    artistLabel.frame = CGRect(x: 24, y: titleLabel.frame.maxY + 4, width: width - 48, height: 22)

    let maxControlsY = height - controlsHeight
    let minControlsY = artistLabel.frame.maxY + 16
    let controlsY = min(maxControlsY, max(minControlsY, 0))
    let actualControlsHeight = min(controlsHeight, height - controlsY)
    controlsView.frame = CGRect(x: 0, y: controlsY, width: width, height: actualControlsHeight)

    if embedsLyricsInLayout, !lyricsView.isHidden {
      let lyricsTop = artistLabel.frame.maxY + 12
      let lyricsMaxHeight = max(0, controlsY - lyricsTop - 8)
      let lyricsHeight = min(max(44, height * 0.18), lyricsMaxHeight)
      lyricsView.frame = CGRect(x: 0, y: lyricsTop, width: width, height: lyricsHeight)
      lyricsView.isUserInteractionEnabled = lyricsHeight >= 44
    } else {
      lyricsView.frame = .zero
      lyricsView.isUserInteractionEnabled = false
    }
  }

  private func layoutCompact(width: CGFloat, height: CGFloat, safe: UIEdgeInsets) {
    artworkView.frame = CGRect(x: 16, y: safe.top + 12, width: 72, height: 72)
    let textWidth = width - 100 - compactChromeTrailing
    titleLabel.frame = CGRect(x: 100, y: safe.top + 14, width: textWidth, height: 24)
    artistLabel.frame = CGRect(x: 100, y: titleLabel.frame.maxY + 2, width: textWidth, height: 20)
    lyricsView.frame = .zero
    lyricsView.isHidden = true

    let headerBottom = max(artworkView.frame.maxY, artistLabel.frame.maxY)
    let controlsHeight = FKAudioControlsView.preferredHeight
    let maxControlsY = height - controlsHeight
    let controlsY = min(maxControlsY, headerBottom + 8)
    let actualControlsHeight = min(controlsHeight, height - controlsY)
    controlsView.frame = CGRect(x: 0, y: controlsY, width: width, height: actualControlsHeight)
  }

  private func layoutRetryButton() {
    guard let retryButton, !retryButton.isHidden else { return }
    let width = bounds.width
    retryButton.frame = CGRect(
      x: (width - 88) / 2,
      y: controlsView.frame.minY - 40,
      width: 88,
      height: 32
    )
  }

  private func loadArtwork(url: URL?) {
    guard let url else {
      artworkView.image = player?.configuration.ui.defaultArtwork
      return
    }
    Task {
      let data: Data?
      if url.isFileURL {
        data = try? Data(contentsOf: url)
      } else {
        data = try? await URLSession.shared.data(from: url).0
      }
      guard let data, let image = UIImage(data: data) else { return }
      await MainActor.run {
        self.artworkView.image = image
      }
    }
  }

  private func presentPlaybackError(_ error: FKMediaError) {
    showRetryButton()
    let message = error.localizedDescription
    guard lastToastErrorDescription != message else { return }
    lastToastErrorDescription = message
    FKToast.show(message, style: .error)
  }

  private func showRetryButton() {
    guard player?.currentItem != nil else {
      hideRetryButton()
      return
    }
    let button = retryButton ?? makeRetryButton()
    retryButton = button
    if button.superview == nil {
      addSubview(button)
    }
    button.tintColor = controlsView.playPauseButton.tintColor
    button.isHidden = false
    setNeedsLayout()
  }

  private func hideRetryButton() {
    retryButton?.removeFromSuperview()
    retryButton = nil
  }

  private func makeRetryButton() -> UIButton {
    let button = UIButton(type: .system)
    button.setTitle(FKAudioPlayerStrings.retry, for: .normal)
    button.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
    return button
  }

  @objc private func retryTapped() {
    player?.retryCurrentItem(autoPlay: true)
  }

  @objc private func cycleQueueMode() {
    guard let player else { return }
    switch player.queue.mode {
    case .sequential: player.queue.mode = .shuffle
    case .shuffle: player.queue.mode = .repeatAll
    case .repeatAll: player.queue.mode = .repeatOne
    case .repeatOne: player.queue.mode = .sequential
    }
    player.applyLoopModeFromQueue()
    refreshQueueModeChrome()
    guard let value = queueModeButton.accessibilityValue else { return }
    let message = "Queue mode: \(value)"
    queueModeToastHandle = FKToast.showOrUpdate(
      message,
      handle: queueModeToastHandle,
      style: .info,
      presentationStrategy: .replaceActive
    )
  }

  @objc private func scheduleSleep() {
    let fireDate = Date().addingTimeInterval(30 * 60)
    player?.setSleepTimer(fireDate: fireDate)
    FKToast.show("Sleep timer set for 30 minutes", style: .info, presentationStrategy: .replaceActive)
  }
}
