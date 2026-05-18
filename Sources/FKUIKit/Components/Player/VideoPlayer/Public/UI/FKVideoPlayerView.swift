import AVFoundation
import UIKit

/// Hosts the video render layer, controls, subtitles, and overlays.
@MainActor
public final class FKVideoPlayerView: UIView {

  public let playerLayer = AVPlayerLayer()
  public private(set) weak var controlView: FKVideoPlayerControlView?

  fileprivate weak var player: FKVideoPlayer?
  fileprivate weak var preFullscreenSuperview: UIView?

  /// Used by feed coordination helpers in the same module.
  var exposedPlayer: FKVideoPlayer? { player }
  private var uiConfiguration: FKVideoUIConfiguration = .default

  // MARK: - Essential chrome (always mounted)

  private let gestureController = FKVideoGestureController()
  private let pictureInPictureController = FKVideoPictureInPictureController()
  private let airPlayPresenter = FKVideoAirPlayPresenter()

  // MARK: - Optional overlays (mounted on demand)

  private var posterImageView: UIImageView?
  private var subtitleView: FKVideoSubtitleView?
  private var liveBadge: FKVideoLiveBadgeView?
  private var errorLabel: UILabel?
  private var retryButton: UIButton?
  private var screenCaptureOverlay: UIView?
  private var llhlsDebugPanel: FKVideoLLHLSDebugPanel?

  private var subtitleCues: [FKVideoSubtitleCue] = []
  private var controlsHideWorkItem: DispatchWorkItem?
  private var posterLoadTask: Task<Void, Never>?
  private var customControlView: FKVideoPlayerControlView?

  public override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .black
    clipsToBounds = true

    playerLayer.videoGravity = .resizeAspect
    layer.addSublayer(playerLayer)

    setDefaultControlView(FKDefaultVideoControlView())
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    playerLayer.frame = bounds
    posterImageView?.frame = bounds
    subtitleView?.frame = bounds
    if let liveBadge {
      liveBadge.frame = CGRect(x: 12, y: safeAreaInsets.top + 8, width: 140, height: 28)
    }
    if let errorLabel, let retryButton {
      errorLabel.frame = CGRect(x: 24, y: bounds.midY - 40, width: bounds.width - 48, height: 80)
      retryButton.frame = CGRect(x: (bounds.width - 80) / 2, y: errorLabel.frame.maxY + 8, width: 80, height: 36)
    }
    controlView?.frame = CGRect(
      x: 0,
      y: bounds.height - 80 - safeAreaInsets.bottom,
      width: bounds.width,
      height: 80 + safeAreaInsets.bottom
    )
    if let llhlsDebugPanel, let liveBadge {
      llhlsDebugPanel.frame = CGRect(
        x: 12,
        y: liveBadge.frame.maxY + 8,
        width: min(200, bounds.width - 24),
        height: 72
      )
    } else if let llhlsDebugPanel {
      llhlsDebugPanel.frame = CGRect(
        x: 12,
        y: safeAreaInsets.top + 8,
        width: min(200, bounds.width - 24),
        height: 72
      )
    }
  }

  // MARK: - Public

  public func setDefaultControlView(_ view: FKVideoPlayerControlView) {
    customControlView?.removeFromSuperview()
    customControlView = view
    controlView = view
    view.frame = CGRect(x: 0, y: bounds.height - 80, width: bounds.width, height: 80)
    addSubview(view)
    bringOptionalOverlaysAboveControlBar()
    airPlayPresenter.bringToFront(on: self)
    if let player {
      view.bind(player: player)
      syncControlState()
    }
  }

  public func apply(uiConfiguration: FKVideoUIConfiguration) {
    self.uiConfiguration = uiConfiguration
    playerLayer.videoGravity = uiConfiguration.aspectFill ? .resizeAspectFill : .resizeAspect
    applyTheme()
    airPlayPresenter.attach(to: self, enabled: uiConfiguration.allowsAirPlay)
    if let player {
      pictureInPictureController.configure(player: player, playerLayer: playerLayer)
    }
  }

  public func bind(player: FKVideoPlayer) {
    self.player = player
    apply(uiConfiguration: player.configuration.ui)
    controlView?.bind(player: player)
    gestureController.attach(to: self, player: player, configuration: uiConfiguration) { [weak self] visible in
      self?.scheduleControlsAutoHide(visible: visible)
    }
    pictureInPictureController.configure(player: player, playerLayer: playerLayer)
    refreshChrome()
    syncControlState()
    revealControls(animated: false)
  }

  /// Shows transport controls and restarts the auto-hide timer.
  public func revealControls(animated: Bool = true) {
    controlsHideWorkItem?.cancel()
    controlView?.setControlsVisible(true, animated: animated)
    scheduleControlsAutoHide(visible: true)
  }

  public func reloadSubtitles(for item: FKVideoItem) {
    subtitleCues = []
    unmountSubtitleView()
    guard let source = item.subtitleSources.first else { return }
    let itemID = item.id
    Task {
      do {
        let data = try await Self.loadSubtitleData(from: source)
        let format: FKVideoSubtitleFormat
        switch source {
        case let .bundled(_, f), let .remote(_, f):
          format = f
        }
        let cues = try FKVideoSubtitleParser.parse(data: data, format: format)
        await MainActor.run {
          guard self.player?.currentItem?.id == itemID else { return }
          self.subtitleCues = cues
          if cues.isEmpty {
            self.unmountSubtitleView()
          } else {
            self.mountSubtitleView().isHidden = false
          }
        }
      } catch {
        await MainActor.run {
          self.unmountSubtitleView()
        }
      }
    }
  }

  public func handleStateChange(_ state: FKMediaPlaybackState) {
    refreshChrome()
    controlView?.update(
      state: state,
      currentTime: player?.currentTime ?? 0,
      duration: player?.duration ?? 0,
      buffered: player?.bufferedTimeRanges ?? [],
      isLive: player?.isLive ?? false,
      liveLatency: player?.liveLatencySeconds
    )

    switch state {
    case .preparing, .buffering:
      if player?.currentItem?.posterURL != nil {
        mountPosterImageView().isHidden = false
      } else {
        unmountPosterImageView()
      }
    case .ready, .playing:
      unmountPosterImageView()
      unmountErrorChrome()
    case .failed(let error):
      unmountPosterImageView()
      let errorLabel = mountErrorLabel()
      errorLabel.text = error.localizedDescription
      errorLabel.isHidden = false
      if player?.currentItem != nil {
        mountRetryButton().isHidden = false
      } else {
        unmountRetryButton()
      }
    default:
      break
    }

    refreshLiveBadge()
    refreshLLHLSDebugPanel()
  }

  public func updateProgress(
    current: TimeInterval,
    duration: TimeInterval,
    buffered: [ClosedRange<TimeInterval>]
  ) {
    controlView?.update(
      state: player?.state ?? .idle,
      currentTime: current,
      duration: duration,
      buffered: buffered,
      isLive: player?.isLive ?? false,
      liveLatency: player?.liveLatencySeconds
    )
    if !subtitleCues.isEmpty, let subtitleView {
      if let text = FKVideoSubtitleParser.cue(at: current, in: subtitleCues) {
        subtitleView.show(text: text)
      } else {
        subtitleView.show(text: nil)
      }
    }
    refreshLiveBadge()
    refreshLLHLSDebugPanel()
  }

  public func resetChrome() {
    posterLoadTask?.cancel()
    posterLoadTask = nil
    subtitleCues = []
    unmountPosterImageView()
    unmountSubtitleView()
    unmountLiveBadge()
    unmountErrorChrome()
    unmountLLHLSDebugPanel()
    setScreenCaptureOverlayVisible(false)
  }

  public func setScreenCaptureOverlayVisible(_ visible: Bool) {
    if visible {
      mountScreenCaptureOverlay().isHidden = false
      bringSubviewToFront(screenCaptureOverlay!)
    } else {
      unmountScreenCaptureOverlay()
    }
  }

  public func toggleFullscreen() {
    guard let player else { return }

    if let fullscreenHost = nearestViewController() as? FKVideoPlayerViewController {
      fullscreenHost.dismiss(animated: true)
      return
    }

    guard let host = nearestViewController() else { return }
    if host.presentedViewController is FKVideoPlayerViewController {
      host.dismiss(animated: true)
    } else {
      capturePreFullscreenHostIfNeeded()
      let fullscreen = FKVideoPlayerViewController(player: player, embeddedView: self)
      host.present(fullscreen, animated: true)
      player.delegate?.videoPlayer(player, didToggleFullscreen: true)
    }
  }

  // MARK: - Overlay lifecycle

  private func mountPosterImageView() -> UIImageView {
    if let posterImageView { return posterImageView }
    let view = UIImageView()
    view.contentMode = .scaleAspectFit
    view.isHidden = true
    posterImageView = view
    insertOverlay(view)
    return view
  }

  private func unmountPosterImageView() {
    posterImageView?.removeFromSuperview()
    posterImageView = nil
  }

  @discardableResult
  private func mountSubtitleView() -> FKVideoSubtitleView {
    if let subtitleView { return subtitleView }
    let view = FKVideoSubtitleView()
    view.isHidden = true
    subtitleView = view
    insertOverlay(view)
    return view
  }

  private func unmountSubtitleView() {
    subtitleView?.removeFromSuperview()
    subtitleView = nil
  }

  private func refreshLiveBadge() {
    guard player?.isLive == true else {
      unmountLiveBadge()
      return
    }
    let badge = mountLiveBadge()
    badge.update(isLive: true, latencySeconds: player?.liveLatencySeconds)
    bringSubviewToFront(badge)
    bringOptionalOverlaysAboveControlBar()
    airPlayPresenter.bringToFront(on: self)
  }

  @discardableResult
  private func mountLiveBadge() -> FKVideoLiveBadgeView {
    if let liveBadge { return liveBadge }
    let badge = FKVideoLiveBadgeView()
    badge.onGoLiveTapped = { [weak self] in
      self?.player?.seekToLiveEdge()
    }
    liveBadge = badge
    insertOverlay(badge)
    return badge
  }

  private func unmountLiveBadge() {
    liveBadge?.removeFromSuperview()
    liveBadge = nil
    if llhlsDebugPanel != nil {
      setNeedsLayout()
    }
  }

  private func mountErrorLabel() -> UILabel {
    if let errorLabel { return errorLabel }
    let label = UILabel()
    label.textColor = .white
    label.font = .systemFont(ofSize: 14, weight: .medium)
    label.numberOfLines = 0
    label.textAlignment = .center
    label.isHidden = true
    errorLabel = label
    insertOverlay(label)
    return label
  }

  private func mountRetryButton() -> UIButton {
    if let retryButton { return retryButton }
    let button = UIButton(type: .system)
    button.setTitle(FKVideoPlayerStrings.retry, for: .normal)
    button.isHidden = true
    button.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
    retryButton = button
    insertOverlay(button)
    applyTheme()
    return button
  }

  private func unmountErrorChrome() {
    errorLabel?.removeFromSuperview()
    retryButton?.removeFromSuperview()
    errorLabel = nil
    retryButton = nil
  }

  private func unmountRetryButton() {
    retryButton?.removeFromSuperview()
    retryButton = nil
  }

  @discardableResult
  private func mountScreenCaptureOverlay() -> UIView {
    if let screenCaptureOverlay { return screenCaptureOverlay }
    let overlay = UIView()
    overlay.backgroundColor = UIColor.black.withAlphaComponent(0.92)
    overlay.translatesAutoresizingMaskIntoConstraints = false
    let captureLabel = UILabel()
    captureLabel.text = FKVideoPlayerStrings.screenCaptureBlocked
    captureLabel.textColor = .white
    captureLabel.textAlignment = .center
    captureLabel.numberOfLines = 0
    captureLabel.translatesAutoresizingMaskIntoConstraints = false
    overlay.addSubview(captureLabel)
    screenCaptureOverlay = overlay
    addSubview(overlay)
    NSLayoutConstraint.activate([
      overlay.topAnchor.constraint(equalTo: topAnchor),
      overlay.leadingAnchor.constraint(equalTo: leadingAnchor),
      overlay.trailingAnchor.constraint(equalTo: trailingAnchor),
      overlay.bottomAnchor.constraint(equalTo: bottomAnchor),
      captureLabel.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
      captureLabel.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
      captureLabel.leadingAnchor.constraint(greaterThanOrEqualTo: overlay.leadingAnchor, constant: 24),
      captureLabel.trailingAnchor.constraint(lessThanOrEqualTo: overlay.trailingAnchor, constant: -24),
    ])
    return overlay
  }

  private func unmountScreenCaptureOverlay() {
    screenCaptureOverlay?.removeFromSuperview()
    screenCaptureOverlay = nil
  }

  private func refreshLLHLSDebugPanel() {
    guard let player, player.showsLLHLSDebugPanel else {
      unmountLLHLSDebugPanel()
      return
    }
    let panel = mountLLHLSDebugPanel()
    panel.update(player: player)
    bringOptionalOverlaysAboveControlBar()
    airPlayPresenter.bringToFront(on: self)
    setNeedsLayout()
  }

  @discardableResult
  private func mountLLHLSDebugPanel() -> FKVideoLLHLSDebugPanel {
    if let llhlsDebugPanel { return llhlsDebugPanel }
    let panel = FKVideoLLHLSDebugPanel()
    llhlsDebugPanel = panel
    insertOverlay(panel)
    return panel
  }

  private func unmountLLHLSDebugPanel() {
    llhlsDebugPanel?.removeFromSuperview()
    llhlsDebugPanel = nil
  }

  /// Inserts optional overlays above the video surface but below transport controls.
  private func insertOverlay(_ view: UIView) {
    if let controlView {
      insertSubview(view, belowSubview: controlView)
    } else {
      addSubview(view)
    }
  }

  private func bringOptionalOverlaysAboveControlBar() {
    if let liveBadge { bringSubviewToFront(liveBadge) }
    if let llhlsDebugPanel { bringSubviewToFront(llhlsDebugPanel) }
    if let screenCaptureOverlay { bringSubviewToFront(screenCaptureOverlay) }
  }

  // MARK: - Private

  private func refreshChrome() {
    posterLoadTask?.cancel()
    guard let url = player?.currentItem?.posterURL else {
      unmountPosterImageView()
      return
    }
    let poster = mountPosterImageView()
    posterLoadTask = Task {
      do {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard !Task.isCancelled else { return }
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
          return
        }
        guard let image = UIImage(data: data) else { return }
        await MainActor.run {
          guard !Task.isCancelled, self.player?.currentItem?.posterURL == url else { return }
          self.posterImageView?.image = image
        }
      } catch {
        // Poster is decorative; ignore load failures.
      }
    }
  }

  private func scheduleControlsAutoHide(visible: Bool) {
    controlsHideWorkItem?.cancel()
    controlsHideWorkItem = nil
    guard visible, uiConfiguration.controlsAutoHideInterval > 0 else { return }
    let work = DispatchWorkItem { [weak self] in
      guard let self, self.controlView?.alpha ?? 0 > 0.5 else { return }
      self.controlView?.setControlsVisible(false, animated: true)
    }
    controlsHideWorkItem = work
    DispatchQueue.main.asyncAfter(deadline: .now() + uiConfiguration.controlsAutoHideInterval, execute: work)
  }

  func noteControlsInteraction() {
    guard controlView?.alpha ?? 0 > 0.5 else { return }
    scheduleControlsAutoHide(visible: true)
  }

  @objc
  private func retryTapped() {
    guard let item = player?.currentItem else { return }
    player?.load(item)
  }

  /// Records the inline host before reparenting for fullscreen (idempotent).
  func capturePreFullscreenHostIfNeeded() {
    if preFullscreenSuperview == nil {
      preFullscreenSuperview = superview
    }
  }

  /// Returns the embedded view to its inline container after fullscreen dismiss.
  func restoreAfterFullscreen(fallbackParent: UIView? = nil) {
    guard superview != nil else { return }
    let parent = preFullscreenSuperview ?? fallbackParent
    guard let parent else { return }
    removeFromSuperview()
    translatesAutoresizingMaskIntoConstraints = false
    parent.addSubview(self)
    NSLayoutConstraint.activate([
      topAnchor.constraint(equalTo: parent.topAnchor),
      leadingAnchor.constraint(equalTo: parent.leadingAnchor),
      trailingAnchor.constraint(equalTo: parent.trailingAnchor),
      bottomAnchor.constraint(equalTo: parent.bottomAnchor),
    ])
    preFullscreenSuperview = nil
    setNeedsLayout()
    layoutIfNeeded()
    player?.rebindVideoOutput()
    player?.bind(to: self)
    revealControls(animated: false)
  }

  private func syncControlState() {
    guard let player else { return }
    controlView?.update(
      state: player.state,
      currentTime: player.currentTime,
      duration: player.duration,
      buffered: player.bufferedTimeRanges,
      isLive: player.isLive,
      liveLatency: player.liveLatencySeconds
    )
  }

  private func applyTheme() {
    let tint = uiConfiguration.resolvedTintColor(traitCollection: traitCollection)
    retryButton?.tintColor = tint
    (controlView as? FKDefaultVideoControlView)?.applyTheme(tint)
  }

  private static func loadSubtitleData(from source: FKVideoSubtitleSource) async throws -> Data {
    switch source {
    case let .bundled(url, _):
      return try Data(contentsOf: url)
    case let .remote(url, _):
      let (data, response) = try await URLSession.shared.data(from: url)
      if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
        throw FKMediaError.httpStatus(code: http.statusCode)
      }
      return data
    }
  }

  private func nearestViewController() -> UIViewController? {
    var responder: UIResponder? = self
    while let current = responder {
      if let vc = current as? UIViewController { return vc }
      responder = current.next
    }
    return nil
  }
}
