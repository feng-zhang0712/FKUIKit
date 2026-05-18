import SwiftUI

/// SwiftUI wrapper for ``FKAudioPlayerView``.
public struct FKAudioPlayerSwiftUIView: UIViewRepresentable {

  private let player: FKAudioPlayer
  private let style: FKAudioPlayerViewStyle

  public init(player: FKAudioPlayer, style: FKAudioPlayerViewStyle = .standard) {
    self.player = player
    self.style = style
  }

  public func makeUIView(context: Context) -> FKAudioPlayerView {
    let view = FKAudioPlayerView(style: style)
    player.bind(to: view)
    return view
  }

  public func updateUIView(_ uiView: FKAudioPlayerView, context: Context) {}
}
