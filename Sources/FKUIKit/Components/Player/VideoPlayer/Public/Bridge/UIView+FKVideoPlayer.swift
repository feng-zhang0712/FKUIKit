import UIKit

extension UIView {

  /// Embeds a ``FKVideoPlayerView`` bound to the given player.
  @discardableResult
  public func fk_embedVideoPlayer(
    _ player: FKVideoPlayer,
    configuration: FKVideoUIConfiguration = .default
  ) -> FKVideoPlayerView {
    let view = FKVideoPlayerView()
    view.translatesAutoresizingMaskIntoConstraints = false
    addSubview(view)
    NSLayoutConstraint.activate([
      view.topAnchor.constraint(equalTo: topAnchor),
      view.leadingAnchor.constraint(equalTo: leadingAnchor),
      view.trailingAnchor.constraint(equalTo: trailingAnchor),
      view.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
    view.apply(uiConfiguration: configuration)
    player.bind(to: view)
    return view
  }
}
