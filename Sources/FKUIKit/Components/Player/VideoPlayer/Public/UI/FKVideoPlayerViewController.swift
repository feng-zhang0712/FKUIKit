import UIKit

/// Full-screen host for ``FKVideoPlayerView``.
@MainActor
public final class FKVideoPlayerViewController: UIViewController {

  public let player: FKVideoPlayer
  private let embeddedView: FKVideoPlayerView?
  private weak var embeddedReturnSuperview: UIView?
  private let playerView: FKVideoPlayerView
  public init(player: FKVideoPlayer, embeddedView: FKVideoPlayerView? = nil) {
    self.player = player
    self.embeddedView = embeddedView
    if let embeddedView {
      self.playerView = embeddedView
    } else {
      self.playerView = FKVideoPlayerView()
    }
    super.init(nibName: nil, bundle: nil)
    modalPresentationStyle = .fullScreen
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black

    if embeddedView == nil {
      playerView.translatesAutoresizingMaskIntoConstraints = false
      view.addSubview(playerView)
      NSLayoutConstraint.activate([
        playerView.topAnchor.constraint(equalTo: view.topAnchor),
        playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      ])
      player.bind(to: playerView)
    } else {
      embeddedReturnSuperview = playerView.superview
      playerView.capturePreFullscreenHostIfNeeded()
      playerView.removeFromSuperview()
      playerView.translatesAutoresizingMaskIntoConstraints = false
      view.addSubview(playerView)
      NSLayoutConstraint.activate([
        playerView.topAnchor.constraint(equalTo: view.topAnchor),
        playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      ])
      player.bind(to: playerView)
      playerView.revealControls(animated: false)
    }
  }

  public override var prefersHomeIndicatorAutoHidden: Bool { true }
  public override var prefersStatusBarHidden: Bool { true }
  public override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .allButUpsideDown }

  public override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    guard isBeingDismissed else { return }
    embeddedView?.restoreAfterFullscreen(fallbackParent: embeddedReturnSuperview)
    player.delegate?.videoPlayer(player, didToggleFullscreen: false)
  }
}
