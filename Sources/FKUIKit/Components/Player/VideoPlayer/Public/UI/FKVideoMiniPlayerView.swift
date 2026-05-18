import UIKit

enum FKVideoMiniBarChromeMetrics {
  static let mainRowHeight: CGFloat = 52
  static let closeButtonSize: CGFloat = 32
  static let playButtonSize: CGFloat = 36
  static let horizontalInset: CGFloat = 12
  static let itemSpacing: CGFloat = 8
  static let progressHeight: CGFloat = 3
  static let progressBottomInset: CGFloat = 6

  static var barHeight: CGFloat {
    mainRowHeight + progressBottomInset + progressHeight
  }

  static func textWidth(for barWidth: CGFloat) -> CGFloat {
    let reserved = horizontalInset + closeButtonSize + itemSpacing + itemSpacing + playButtonSize + horizontalInset
    return max(72, barWidth - reserved)
  }
}

/// Compact floating mini player shell with playback progress.
@MainActor
public final class FKVideoMiniPlayerView: UIView {

  public var onExpand: (() -> Void)?
  public var onClose: (() -> Void)?

  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()
  private let playPauseButton = UIButton(type: .system)
  private let closeButton = UIButton(type: .system)
  private let progressView = UIProgressView(progressViewStyle: .bar)
  private var playPauseSpinner: UIActivityIndicatorView?
  private var showsPlaySpinner = false

  private weak var player: FKVideoPlayer?
  private lazy var expandTap: UITapGestureRecognizer = {
    let tap = UITapGestureRecognizer(target: self, action: #selector(expandTapped))
    tap.delegate = self
    return tap
  }()

  public override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .secondarySystemBackground
    layer.cornerRadius = 12
    layer.shadowColor = UIColor.black.cgColor
    layer.shadowOpacity = 0.2
    layer.shadowRadius = 8
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override var intrinsicContentSize: CGSize {
    CGSize(width: UIView.noIntrinsicMetric, height: FKVideoMiniBarChromeMetrics.barHeight)
  }

  public override func didMoveToSuperview() {
    super.didMoveToSuperview()
    installSubviewsIfNeeded()
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    let metrics = FKVideoMiniBarChromeMetrics.self
    let width = bounds.width
    let rowHeight = metrics.mainRowHeight
    let rowMidY = rowHeight / 2

    progressView.frame = CGRect(
      x: metrics.horizontalInset,
      y: bounds.height - metrics.progressBottomInset - metrics.progressHeight,
      width: width - metrics.horizontalInset * 2,
      height: metrics.progressHeight
    )

    closeButton.frame = CGRect(
      x: metrics.horizontalInset,
      y: rowMidY - metrics.closeButtonSize / 2,
      width: metrics.closeButtonSize,
      height: metrics.closeButtonSize
    )

    playPauseButton.frame = CGRect(
      x: width - metrics.horizontalInset - metrics.playButtonSize,
      y: rowMidY - metrics.playButtonSize / 2,
      width: metrics.playButtonSize,
      height: metrics.playButtonSize
    )
    syncPlaySpinner()

    let textX = closeButton.frame.maxX + metrics.itemSpacing
    let textWidth = metrics.textWidth(for: width)
    let titleLineHeight: CGFloat = 18
    let subtitleLineHeight: CGFloat = 15

    if subtitleLabel.isHidden {
      titleLabel.frame = CGRect(
        x: textX,
        y: rowMidY - titleLineHeight / 2,
        width: textWidth,
        height: titleLineHeight
      )
    } else {
      let textBlockHeight = titleLineHeight + 2 + subtitleLineHeight
      let textY = rowMidY - textBlockHeight / 2
      titleLabel.frame = CGRect(x: textX, y: textY, width: textWidth, height: titleLineHeight)
      subtitleLabel.frame = CGRect(
        x: textX,
        y: textY + titleLineHeight + 2,
        width: textWidth,
        height: subtitleLineHeight
      )
    }
  }

  public func bind(player: FKVideoPlayer) {
    installSubviewsIfNeeded()
    self.player = player
    reload(for: player.currentItem)
    handleStateChange(player.state)
    updateProgress()
  }

  public func syncFromPlayer() {
    guard let player else { return }
    reload(for: player.currentItem)
    handleStateChange(player.state)
    updateProgress()
  }

  public func reload(for item: FKVideoItem?) {
    titleLabel.text = item?.title ?? "Video"
    let live = player?.isLive == true
    subtitleLabel.text = live ? FKVideoPlayerStrings.live : nil
    subtitleLabel.isHidden = subtitleLabel.text == nil
    setNeedsLayout()
  }

  public func handleStateChange(_ state: FKMediaPlaybackState) {
    setPlaySpinnerVisible(state == .preparing || state == .buffering)
    updatePlayIcon(for: state)
  }

  public func updateProgress() {
    guard let player else { return }
    let duration = max(player.duration, 1)
    progressView.progress = Float(player.currentTime / duration)
    progressView.progressTintColor = player.configuration.ui.resolvedTintColor(traitCollection: traitCollection)
    if !showsPlaySpinner {
      updatePlayIcon(for: player.state)
    }
  }

  // MARK: - Private

  private func installSubviewsIfNeeded() {
    guard titleLabel.superview == nil else { return }

    titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
    titleLabel.textColor = .label
    titleLabel.lineBreakMode = .byTruncatingTail
    addSubview(titleLabel)

    subtitleLabel.font = .systemFont(ofSize: 11, weight: .regular)
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.lineBreakMode = .byTruncatingTail
    addSubview(subtitleLabel)

    progressView.trackTintColor = .quaternarySystemFill
    addSubview(progressView)

    playPauseButton.tintColor = .label
    playPauseButton.addTarget(self, action: #selector(toggle), for: .touchUpInside)
    addSubview(playPauseButton)

    closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
    closeButton.tintColor = .secondaryLabel
    closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    addSubview(closeButton)

    addGestureRecognizer(expandTap)
    playPauseButton.accessibilityLabel = FKVideoPlayerStrings.play
    closeButton.accessibilityLabel = FKVideoPlayerStrings.close
  }

  private func updatePlayIcon(for state: FKMediaPlaybackState) {
    guard !showsPlaySpinner else { return }
    let playing = state == .playing || state == .buffering
    let name = playing ? "pause.fill" : "play.fill"
    playPauseButton.setImage(UIImage(systemName: name), for: .normal)
    playPauseButton.accessibilityLabel = playing ? FKVideoPlayerStrings.pause : FKVideoPlayerStrings.play
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
      spinner.color = playPauseButton.tintColor
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

  @objc
  private func toggle() {
    player?.togglePlayPause()
    if let player, !showsPlaySpinner {
      updatePlayIcon(for: player.state)
    }
  }

  @objc
  private func closeTapped() {
    player?.stop()
    onClose?()
    isHidden = true
  }

  @objc
  private func expandTapped() {
    onExpand?()
  }
}

extension FKVideoMiniPlayerView: UIGestureRecognizerDelegate {

  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    var view: UIView? = touch.view
    while let current = view {
      if current is UIButton {
        return false
      }
      view = current.superview
    }
    return true
  }
}
