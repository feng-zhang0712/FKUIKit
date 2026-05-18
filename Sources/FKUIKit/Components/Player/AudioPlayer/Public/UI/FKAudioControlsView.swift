import UIKit

/// Layout density for ``FKAudioControlsView``.
public enum FKAudioControlsLayoutStyle: Sendable {
  case standard
  case miniBar
}

/// Transport controls shared by standard and compact audio layouts.
@MainActor
public final class FKAudioControlsView: UIView {

  public var isControlsLocked = false
  public var layoutStyle: FKAudioControlsLayoutStyle = .standard {
    didSet {
      guard oldValue != layoutStyle else { return }
      syncSubviewsForLayoutStyle()
    }
  }

  let playPauseButton = UIButton(type: .system)
  let previousButton = UIButton(type: .system)
  let nextButton = UIButton(type: .system)
  let rateButton = UIButton(type: .system)
  let progressSlider = UISlider()
  let bufferProgressView = UIProgressView(progressViewStyle: .bar)
  let currentTimeLabel = UILabel()
  let durationLabel = UILabel()
  private var playPauseSpinner: UIActivityIndicatorView?

  private weak var player: FKAudioPlayer?
  private var isScrubbing = false
  private var standardChromeInstalled = false

  public override init(frame: CGRect) {
    super.init(frame: frame)

    playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
    previousButton.setImage(UIImage(systemName: "backward.fill"), for: .normal)
    nextButton.setImage(UIImage(systemName: "forward.fill"), for: .normal)
    rateButton.setTitle("1.0x", for: .normal)
    rateButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)

    for label in [currentTimeLabel, durationLabel] {
      label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
      label.textColor = .secondaryLabel
    }
    currentTimeLabel.text = "00:00"
    durationLabel.text = "00:00"

    progressSlider.addTarget(self, action: #selector(sliderBegan), for: .touchDown)
    progressSlider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
    progressSlider.addTarget(self, action: #selector(sliderEnded), for: [.touchUpInside, .touchUpOutside, .touchCancel])

    bufferProgressView.progressTintColor = .tertiaryLabel
    bufferProgressView.trackTintColor = .quaternarySystemFill

    playPauseButton.addTarget(self, action: #selector(togglePlayPause), for: .touchUpInside)
    previousButton.addTarget(self, action: #selector(playPrevious), for: .touchUpInside)
    nextButton.addTarget(self, action: #selector(playNext), for: .touchUpInside)
    rateButton.addTarget(self, action: #selector(cycleRate), for: .touchUpInside)

    addSubview(playPauseButton)
    syncSubviewsForLayoutStyle()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    switch layoutStyle {
    case .standard:
      layoutStandardControls()
    case .miniBar:
      layoutMiniBarControls()
    }
  }

  private func layoutStandardControls() {
    previousButton.isHidden = false
    nextButton.isHidden = false
    rateButton.isHidden = false
    currentTimeLabel.isHidden = false
    durationLabel.isHidden = false
    bufferProgressView.isHidden = false
    progressSlider.isHidden = false
    playPauseButton.isHidden = false

    let width = bounds.width
    let height = bounds.height
    let horizontalInset: CGFloat = 16
    let sliderWidth = width - horizontalInset * 2
    let topPadding: CGFloat = 4

    progressSlider.frame = CGRect(x: horizontalInset, y: topPadding, width: sliderWidth, height: 28)
    bufferProgressView.frame = CGRect(
      x: horizontalInset + 2,
      y: topPadding + 13,
      width: sliderWidth - 4,
      height: 3
    )

    let timeY = progressSlider.frame.maxY + 4
    currentTimeLabel.frame = CGRect(x: horizontalInset, y: timeY, width: 56, height: 14)
    currentTimeLabel.textAlignment = .left
    durationLabel.frame = CGRect(x: horizontalInset + sliderWidth - 56, y: timeY, width: 56, height: 14)
    durationLabel.textAlignment = .right

    let buttonSize: CGFloat = 44
    let bottomPadding: CGFloat = 2
    let buttonY = max(timeY + 20, height - bottomPadding - buttonSize)
    previousButton.frame = CGRect(x: width / 2 - 100, y: buttonY, width: buttonSize, height: buttonSize)
    playPauseButton.frame = CGRect(x: width / 2 - 22, y: buttonY, width: buttonSize, height: buttonSize)
    nextButton.frame = CGRect(x: width / 2 + 56, y: buttonY, width: buttonSize, height: buttonSize)
    rateButton.frame = CGRect(x: width - 64, y: buttonY + 8, width: 52, height: 28)
    playPauseSpinner?.center = CGPoint(x: playPauseButton.bounds.midX, y: playPauseButton.bounds.midY)
  }

  private func layoutMiniBarControls() {
    syncMiniBarPlaySpinner()
    // Play button frame is positioned by ``FKAudioPlayerView`` for mini-bar chrome.
  }

  func syncMiniBarPlaySpinner() {
    guard layoutStyle == .miniBar, let spinner = playPauseSpinner else { return }
    spinner.center = CGPoint(x: playPauseButton.bounds.midX, y: playPauseButton.bounds.midY)
  }

  private func syncSubviewsForLayoutStyle() {
    switch layoutStyle {
    case .standard:
      installStandardChromeIfNeeded()
    case .miniBar:
      uninstallStandardChromeIfNeeded()
    }
  }

  private func installStandardChromeIfNeeded() {
    guard !standardChromeInstalled else { return }
    standardChromeInstalled = true
    [
      previousButton, nextButton, rateButton,
      currentTimeLabel, durationLabel, bufferProgressView, progressSlider,
    ].forEach { addSubview($0) }
  }

  private func uninstallStandardChromeIfNeeded() {
    guard standardChromeInstalled else { return }
    standardChromeInstalled = false
    [
      previousButton, nextButton, rateButton,
      currentTimeLabel, durationLabel, bufferProgressView, progressSlider,
    ].forEach { $0.removeFromSuperview() }
    setPlaySpinnerVisible(false, tint: playPauseButton.tintColor ?? .systemBlue)
  }

  private func setPlaySpinnerVisible(_ visible: Bool, tint: UIColor) {
    if visible {
      let spinner: UIActivityIndicatorView
      if let existing = playPauseSpinner {
        spinner = existing
      } else {
        let created = UIActivityIndicatorView(style: .medium)
        created.hidesWhenStopped = true
        playPauseButton.addSubview(created)
        playPauseSpinner = created
        spinner = created
      }
      spinner.color = tint
      spinner.center = CGPoint(x: playPauseButton.bounds.midX, y: playPauseButton.bounds.midY)
      spinner.startAnimating()
    } else {
      playPauseSpinner?.stopAnimating()
      playPauseSpinner?.removeFromSuperview()
      playPauseSpinner = nil
    }
  }

  /// Minimum height for the Apple Music–style progress + time + transport layout.
  public static let preferredHeight: CGFloat = 108

  public func bind(player: FKAudioPlayer) {
    self.player = player
    syncSubviewsForLayoutStyle()
    applyTheme(player.configuration.ui.resolvedTintColor(traitCollection: traitCollection))
    updateRateTitle()
    configureAccessibility()
    if effectiveUserInterfaceLayoutDirection == .rightToLeft {
      semanticContentAttribute = .forceRightToLeft
    }
  }

  private func configureAccessibility() {
    playPauseButton.accessibilityLabel = FKAudioPlayerStrings.play
    previousButton.accessibilityLabel = FKAudioPlayerStrings.previous
    nextButton.accessibilityLabel = FKAudioPlayerStrings.next
    rateButton.accessibilityLabel = FKAudioPlayerStrings.playbackSpeed
  }

  public func applyTheme(_ tint: UIColor) {
    for button in [playPauseButton, previousButton, nextButton, rateButton] {
      button.tintColor = tint
    }
    if standardChromeInstalled {
      progressSlider.tintColor = tint
      bufferProgressView.progressTintColor = tint.withAlphaComponent(0.35)
    }
    playPauseSpinner?.color = tint
  }

  public func update(
    state: FKMediaPlaybackState,
    currentTime: TimeInterval,
    duration: TimeInterval,
    buffered: [ClosedRange<TimeInterval>]
  ) {
    if standardChromeInstalled, !isScrubbing {
      let maxDuration = max(duration, 1)
      progressSlider.value = Float(currentTime / maxDuration)
      let end = buffered.map(\.upperBound).max() ?? 0
      bufferProgressView.progress = Float(min(1, end / maxDuration))
      currentTimeLabel.text = formatTime(currentTime)
      durationLabel.text = formatTime(duration)
      progressSlider.isEnabled = duration > 0 && !isControlsLocked
    }
    let isPreparing = state == .preparing
    let isBuffering = state == .buffering
    let showsPlaySpinner = isPreparing || isBuffering

    playPauseButton.isEnabled = !isControlsLocked && !isPreparing
    previousButton.isEnabled = !isControlsLocked && !isPreparing
    nextButton.isEnabled = !isControlsLocked && !isPreparing
    rateButton.isEnabled = !isControlsLocked

    let tint = playPauseButton.tintColor ?? .systemBlue
    if showsPlaySpinner {
      playPauseButton.setImage(nil, for: .normal)
      setPlaySpinnerVisible(true, tint: tint)
      playPauseButton.accessibilityLabel = isBuffering
        ? FKAudioPlayerStrings.pause
        : FKAudioPlayerStrings.play
    } else {
      setPlaySpinnerVisible(false, tint: tint)
      switch state {
      case .playing:
        playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        playPauseButton.accessibilityLabel = FKAudioPlayerStrings.pause
      default:
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playPauseButton.accessibilityLabel = FKAudioPlayerStrings.play
      }
    }
  }

  /// Updates the rate button title from the bound player's current ``FKAudioPlayer/rate``.
  public func syncPlaybackRateDisplay() {
    updateRateTitle()
  }

  private func updateRateTitle() {
    guard let player else { return }
    rateButton.setTitle(String(format: "%.1fx", player.rate), for: .normal)
  }

  @objc private func togglePlayPause() {
    guard !isControlsLocked else { return }
    player?.togglePlayPause()
  }

  @objc private func playNext() {
    guard !isControlsLocked else { return }
    player?.playNext()
  }

  @objc private func playPrevious() {
    guard !isControlsLocked else { return }
    player?.playPrevious()
  }

  @objc private func cycleRate() {
    guard let player else { return }
    let rates: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
    let maxRate = player.configuration.playback.maxRate
    let filtered = rates.filter { $0 <= maxRate }
    let current = player.rate
    let next = filtered.first(where: { $0 > current + 0.01 }) ?? filtered.first ?? 1.0
    player.rate = next
    updateRateTitle()
  }

  @objc private func sliderBegan() { isScrubbing = true }
  @objc private func sliderChanged() {
    guard let player else { return }
    currentTimeLabel.text = formatTime(TimeInterval(progressSlider.value) * max(player.duration, 1))
  }
  @objc private func sliderEnded() {
    guard let player else { return }
    let target = TimeInterval(progressSlider.value) * max(player.duration, 1)
    player.seek(to: target) { [weak self] _ in self?.isScrubbing = false }
  }

  private func formatTime(_ time: TimeInterval) -> String {
    guard time.isFinite, time >= 0 else { return "00:00" }
    let total = Int(time)
    let minutes = (total % 3600) / 60
    let seconds = total % 60
    return String(format: "%02d:%02d", minutes, seconds)
  }
}
