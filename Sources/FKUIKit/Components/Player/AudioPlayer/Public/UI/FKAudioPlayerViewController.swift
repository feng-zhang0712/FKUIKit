import UIKit

/// Full-screen "Now Playing" page for ``FKAudioPlayer``.
@MainActor
public final class FKAudioPlayerViewController: UIViewController {

  public let player: FKAudioPlayer
  private let playerView: FKAudioPlayerView
  private let standaloneCloseButton = UIButton(type: .system)

  public init(player: FKAudioPlayer, style: FKAudioPlayerViewStyle = .standard) {
    self.player = player
    self.playerView = FKAudioPlayerView(style: style)
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    playerView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(playerView)
    NSLayoutConstraint.activate([
      playerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      playerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
    ])
    player.attachChrome(playerView)

    if navigationController != nil {
      navigationItem.leftBarButtonItem = UIBarButtonItem(
        barButtonSystemItem: .close,
        target: self,
        action: #selector(closeTapped)
      )
    } else {
      configureStandaloneCloseButton()
    }
  }

  public override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    player.detachChrome(playerView)
    if isBeingDismissed, let boundView = player.boundView {
      player.syncChrome(with: boundView)
    }
  }

  private func configureStandaloneCloseButton() {
    var config = UIButton.Configuration.plain()
    config.image = UIImage(systemName: "xmark.circle.fill")
    config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)
    standaloneCloseButton.configuration = config
    standaloneCloseButton.tintColor = .secondaryLabel
    standaloneCloseButton.accessibilityLabel = FKAudioPlayerStrings.close
    standaloneCloseButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    standaloneCloseButton.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(standaloneCloseButton)
    NSLayoutConstraint.activate([
      standaloneCloseButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      standaloneCloseButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
    ])
    view.bringSubviewToFront(standaloneCloseButton)
  }

  @objc
  private func closeTapped() {
    if let navigationController, navigationController.viewControllers.first != self {
      navigationController.popViewController(animated: true)
    } else {
      dismiss(animated: true)
    }
  }
}
