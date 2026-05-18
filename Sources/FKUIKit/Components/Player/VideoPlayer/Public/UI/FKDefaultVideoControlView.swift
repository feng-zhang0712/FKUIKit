import UIKit

/// Default transport controls for ``FKVideoPlayerView``.
@MainActor
public final class FKDefaultVideoControlView: UIView, FKVideoPlayerControlView {

  public var isControlsLocked = false

  private weak var player: FKVideoPlayer?

  private let playPauseButton = UIButton(type: .system)
  private let fullscreenButton = UIButton(type: .system)
  private let settingsButton = UIButton(type: .system)
  private let timeLabel = UILabel()
  private let progressSlider = UISlider()
  private let bufferProgressView = UIProgressView(progressViewStyle: .bar)

  private var isScrubbing = false
  private var showsRemainingTime = false
  private var showsPlaySpinner = false
  private var themeTint: UIColor = .white
  private var playPauseSpinner: UIActivityIndicatorView?
  private let thumbnailPreview = FKVideoThumbnailSeekPreview()
  private var thumbnailTask: Task<Void, Never>?

  public override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = UIColor.black.withAlphaComponent(0.35)

    playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
    playPauseButton.tintColor = .white
    playPauseButton.addTarget(self, action: #selector(togglePlayPause), for: .touchUpInside)

    fullscreenButton.setImage(UIImage(systemName: "arrow.up.left.and.arrow.down.right"), for: .normal)
    fullscreenButton.tintColor = .white
    fullscreenButton.addTarget(self, action: #selector(toggleFullscreen), for: .touchUpInside)

    settingsButton.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
    settingsButton.tintColor = .white
    settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)

    timeLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
    timeLabel.textColor = .white
    timeLabel.text = "00:00 / 00:00"

    progressSlider.minimumValue = 0
    progressSlider.maximumValue = 1
    progressSlider.addTarget(self, action: #selector(sliderBegan), for: .touchDown)
    progressSlider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
    progressSlider.addTarget(self, action: #selector(sliderEnded), for: [.touchUpInside, .touchUpOutside, .touchCancel])

    bufferProgressView.progressTintColor = UIColor.white.withAlphaComponent(0.35)
    bufferProgressView.trackTintColor = UIColor.white.withAlphaComponent(0.15)

    [
      playPauseButton, settingsButton, fullscreenButton,
      timeLabel, bufferProgressView, progressSlider,
    ].forEach {
      addSubview($0)
    }
  }

  func applyTheme(_ tint: UIColor) {
    themeTint = tint
    playPauseButton.tintColor = tint
    fullscreenButton.tintColor = tint
    settingsButton.tintColor = tint
    playPauseSpinner?.color = tint
  }

  func configure(showsRemainingTime: Bool) {
    self.showsRemainingTime = showsRemainingTime
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    let safe = safeAreaInsets
    let chromeHeight = bounds.height - safe.bottom
    let width = bounds.width

    let horizontalInset: CGFloat = 12
    let playSize: CGFloat = 44
    let sideButtonSize: CGFloat = 40
    let clusterGap: CGFloat = 8
    let playLeft = safe.left + horizontalInset
    let trackLeft = playLeft + playSize + clusterGap
    let trackRight = width - safe.right - horizontalInset
    let rightClusterWidth = sideButtonSize * 2 + clusterGap
    let trackWidth = max(160, trackRight - trackLeft - rightClusterWidth)

    let timeHeight: CGFloat = 16
    let sliderHeight: CGFloat = 32
    let timeToSliderGap: CGFloat = 4
    let chromeBottomPadding: CGFloat = 12

    let sliderY = chromeHeight - chromeBottomPadding - sliderHeight
    let transportCenterY = sliderY + sliderHeight / 2
    let timeY = sliderY - timeToSliderGap - timeHeight

    timeLabel.frame = CGRect(x: trackLeft, y: timeY, width: trackWidth, height: timeHeight)
    progressSlider.frame = CGRect(x: trackLeft, y: sliderY, width: trackWidth, height: sliderHeight)
    bufferProgressView.frame = CGRect(
      x: trackLeft + 2,
      y: sliderY + (sliderHeight - 3) / 2,
      width: trackWidth - 4,
      height: 3
    )

    playPauseButton.frame = CGRect(
      x: playLeft,
      y: transportCenterY - playSize / 2,
      width: playSize,
      height: playSize
    )
    fullscreenButton.frame = CGRect(
      x: trackRight - sideButtonSize,
      y: transportCenterY - sideButtonSize / 2,
      width: sideButtonSize,
      height: sideButtonSize
    )
    settingsButton.frame = CGRect(
      x: fullscreenButton.frame.minX - clusterGap - sideButtonSize,
      y: transportCenterY - sideButtonSize / 2,
      width: sideButtonSize,
      height: sideButtonSize
    )
    syncPlaySpinner()
  }

  public func bind(player: FKVideoPlayer) {
    self.player = player
    configure(showsRemainingTime: player.configuration.ui.showsRemainingTime)
    applyTheme(player.configuration.ui.resolvedTintColor(traitCollection: traitCollection))
    configureAccessibility()
    if effectiveUserInterfaceLayoutDirection == .rightToLeft {
      semanticContentAttribute = .forceRightToLeft
    }
  }

  private func configureAccessibility() {
    playPauseButton.accessibilityLabel = FKVideoPlayerStrings.play
    fullscreenButton.accessibilityLabel = FKVideoPlayerStrings.fullscreen
    settingsButton.accessibilityLabel = FKVideoPlayerStrings.settings
    progressSlider.accessibilityLabel = FKVideoPlayerStrings.progress
  }

  public func update(
    state: FKMediaPlaybackState,
    currentTime: TimeInterval,
    duration: TimeInterval,
    buffered: [ClosedRange<TimeInterval>],
    isLive: Bool,
    liveLatency: TimeInterval?
  ) {
    _ = liveLatency
    if !isScrubbing {
      let maxDuration = max(duration, 1)
      progressSlider.value = Float(currentTime / maxDuration)
      bufferProgressView.progress = Float(bufferedCoverage(buffered, duration: duration))
    }

    timeLabel.text = formattedPlaybackTime(
      current: currentTime,
      duration: duration,
      isLive: isLive
    )
    progressSlider.accessibilityValue = timeLabel.text

    let isLoading = isLoadingState(state)
    setPlaySpinnerVisible(isLoading)
    if !showsPlaySpinner {
      updatePlayButtonImage(for: state)
    }
    updateTransportAccessibility(for: state)

    playPauseButton.isEnabled = !isControlsLocked && state != .preparing
    progressSlider.isEnabled = isProgressInteractionEnabled(
      state: state,
      duration: duration,
      isLive: isLive
    )
  }

  public func setControlsVisible(_ visible: Bool, animated: Bool) {
    let alpha: CGFloat = visible ? 1 : 0
    let animations = { self.alpha = alpha }
    if animated {
      UIView.animate(withDuration: 0.25, animations: animations)
    } else {
      animations()
    }
  }

  // MARK: - Actions

  @objc
  private func togglePlayPause() {
    guard !isControlsLocked, !showsPlaySpinner else { return }
    player?.boundView?.noteControlsInteraction()
    player?.togglePlayPause()
  }

  @objc
  private func toggleFullscreen() {
    guard !isControlsLocked else { return }
    player?.boundView?.noteControlsInteraction()
    player?.boundView?.toggleFullscreen()
  }

  @objc
  private func openSettings() {
    guard !isControlsLocked,
          let player,
          let host = nearestViewController() else { return }
    player.boundView?.noteControlsInteraction()
    FKVideoSettingsMenu.present(from: settingsButton, in: host, player: player)
  }

  private func nearestViewController() -> UIViewController? {
    var responder: UIResponder? = self
    while let current = responder {
      if let vc = current as? UIViewController { return vc }
      responder = current.next
    }
    return nil
  }

  @objc
  private func sliderBegan() {
    guard progressSlider.isEnabled else { return }
    isScrubbing = true
    player?.boundView?.noteControlsInteraction()
  }

  @objc
  private func sliderChanged() {
    guard let player else { return }
    let target = TimeInterval(progressSlider.value) * max(player.duration, 1)
    timeLabel.text = formattedPlaybackTime(
      current: target,
      duration: player.duration,
      isLive: player.isLive
    )
    updateThumbnailPreview(at: target)
  }

  @objc
  private func sliderEnded() {
    guard let player else { return }
    let target = TimeInterval(progressSlider.value) * max(player.duration, 1)
    thumbnailPreview.hide()
    thumbnailTask?.cancel()
    player.seek(to: target) { [weak self] _ in
      self?.isScrubbing = false
    }
  }

  private func updateThumbnailPreview(at time: TimeInterval) {
    guard let player, let provider = player.thumbnailProvider else {
      thumbnailPreview.hide()
      return
    }
    let centerX = progressSlider.frame.minX + CGFloat(progressSlider.value) * progressSlider.frame.width
    thumbnailTask?.cancel()
    thumbnailTask = Task { @MainActor in
      let image = await provider.thumbnail(at: time)
      guard !Task.isCancelled else { return }
      thumbnailPreview.show(image: image, time: time, centerX: centerX, in: self)
    }
  }

  private func isLoadingState(_ state: FKMediaPlaybackState) -> Bool {
    switch state {
    case .preparing, .buffering:
      return true
    default:
      return false
    }
  }

  private func isProgressInteractionEnabled(
    state: FKMediaPlaybackState,
    duration: TimeInterval,
    isLive: Bool
  ) -> Bool {
    guard !isControlsLocked, state != .preparing else { return false }
    if isLive { return true }
    return duration > 0
  }

  private func setPlaySpinnerVisible(_ visible: Bool) {
    showsPlaySpinner = visible
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
      spinner.color = playPauseButton.tintColor ?? themeTint
      playPauseButton.setImage(nil, for: .normal)
      spinner.startAnimating()
    } else {
      playPauseSpinner?.stopAnimating()
    }
    syncPlaySpinner()
  }

  private func syncPlaySpinner() {
    playPauseSpinner?.center = CGPoint(
      x: playPauseButton.bounds.midX,
      y: playPauseButton.bounds.midY
    )
  }

  private func updatePlayButtonImage(for state: FKMediaPlaybackState) {
    switch state {
    case .playing:
      playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
    default:
      playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
    }
  }

  private func updateTransportAccessibility(for state: FKMediaPlaybackState) {
    if showsPlaySpinner {
      playPauseButton.accessibilityLabel = FKVideoPlayerStrings.loading
      return
    }
    playPauseButton.accessibilityLabel =
      state == .playing ? FKVideoPlayerStrings.pause : FKVideoPlayerStrings.play
  }

  private func bufferedCoverage(_ ranges: [ClosedRange<TimeInterval>], duration: TimeInterval) -> Double {
    guard duration > 0 else { return 0 }
    let end = ranges.map(\.upperBound).max() ?? 0
    return min(1, end / duration)
  }

  private func formattedPlaybackTime(
    current: TimeInterval,
    duration: TimeInterval,
    isLive: Bool
  ) -> String {
    let currentText = formatTime(current)
    if isLive {
      return "\(currentText) / \(FKVideoPlayerStrings.live)"
    }
    if showsRemainingTime, duration > 0 {
      let remaining = formatTime(max(0, duration - current))
      return "\(currentText) / -\(remaining)"
    }
    return "\(currentText) / \(formatTime(duration))"
  }

  private func formatTime(_ time: TimeInterval) -> String {
    guard time.isFinite, time >= 0 else { return "00:00" }
    let total = Int(time)
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    let seconds = total % 60
    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }
    return String(format: "%02d:%02d", minutes, seconds)
  }
}
