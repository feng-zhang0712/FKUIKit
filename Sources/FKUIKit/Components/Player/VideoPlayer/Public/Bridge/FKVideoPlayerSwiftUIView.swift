import SwiftUI

/// SwiftUI wrapper for ``FKVideoPlayerView``.
@MainActor
public struct FKVideoPlayerSwiftUIView: UIViewRepresentable {

  private let player: FKVideoPlayer
  private let uiConfiguration: FKVideoUIConfiguration

  public init(player: FKVideoPlayer, uiConfiguration: FKVideoUIConfiguration = .default) {
    self.player = player
    self.uiConfiguration = uiConfiguration
  }

  public func makeUIView(context: Context) -> FKVideoPlayerView {
    let view = FKVideoPlayerView()
    player.bind(to: view)
    return view
  }

  public func updateUIView(_ uiView: FKVideoPlayerView, context: Context) {
    uiView.bind(player: player)
  }
}
