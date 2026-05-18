import UIKit

/// Auto-plays visible videos in a scroll view and pauses off-screen cells.
@MainActor
public final class FKVideoFeedPlaybackCoordinator: NSObject, UIScrollViewDelegate {

  public weak var scrollView: UIScrollView?
  public var pool: FKVideoPlayerPool
  public var visibilityThreshold: CGFloat = 0.6

  private var playViews: NSHashTable<FKVideoPlayerView> = .weakObjects()
  private var activeView: FKVideoPlayerView?

  public init(pool: FKVideoPlayerPool = FKVideoPlayerPool()) {
    self.pool = pool
    super.init()
  }

  public func register(_ playerView: FKVideoPlayerView) {
    playViews.add(playerView)
  }

  public func unregister(_ playerView: FKVideoPlayerView) {
    playViews.remove(playerView)
    if activeView === playerView {
      activeView?.exposedPlayer?.pause()
      activeView = nil
    }
  }

  public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    evaluateVisibility(in: scrollView)
  }

  public func refreshVisibility() {
    guard let scrollView else { return }
    evaluateVisibility(in: scrollView)
  }

  private func evaluateVisibility(in scrollView: UIScrollView) {
    let visibleRect = CGRect(origin: scrollView.contentOffset, size: scrollView.bounds.size)
    var bestView: FKVideoPlayerView?
    var bestRatio: CGFloat = 0

    for view in playViews.allObjects {
      let frame = view.convert(view.bounds, to: scrollView)
      let intersection = frame.intersection(visibleRect)
      guard intersection.width > 0, intersection.height > 0 else { continue }
      let ratio = (intersection.width * intersection.height) / (frame.width * frame.height)
      if ratio > bestRatio {
        bestRatio = ratio
        bestView = view
      }
    }

    guard bestRatio >= visibilityThreshold, let target = bestView else {
      activeView?.exposedPlayer?.pause()
      activeView = nil
      return
    }

    if activeView !== target {
      activeView?.exposedPlayer?.pause()
      activeView = target
      if let player = target.exposedPlayer {
        pool.applyLowPowerPolicyIfNeeded(to: player)
        player.play()
      }
    }
  }
}
