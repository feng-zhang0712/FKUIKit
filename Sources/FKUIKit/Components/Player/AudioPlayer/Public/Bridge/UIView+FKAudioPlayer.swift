import UIKit

extension UIView {

  /// Embeds an ``FKAudioPlayerView`` bound to the given player.
  @discardableResult
  public func fk_embedAudioPlayer(
    _ player: FKAudioPlayer,
    style: FKAudioPlayerViewStyle = .standard
  ) -> FKAudioPlayerView {
    let view = FKAudioPlayerView(style: style)
    view.translatesAutoresizingMaskIntoConstraints = false
    addSubview(view)
    NSLayoutConstraint.activate([
      view.topAnchor.constraint(equalTo: topAnchor),
      view.leadingAnchor.constraint(equalTo: leadingAnchor),
      view.trailingAnchor.constraint(equalTo: trailingAnchor),
      view.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
    player.bind(to: view)
    return view
  }
}
