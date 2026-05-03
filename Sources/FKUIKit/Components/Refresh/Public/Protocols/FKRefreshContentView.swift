import UIKit

/// Custom header or footer content driven by ``FKRefreshControl`` (GIF, Lottie host, branded layout, etc.).
public protocol FKRefreshContentView: UIView {
  /// Called on every state transition; update visuals and copy here.
  func refreshControl(_ control: FKRefreshControl, didTransitionTo state: FKRefreshState, from previous: FKRefreshState)
  /// Called while the user pulls a **header**; `progress` is `0...1` relative to ``FKRefreshConfiguration/triggerThreshold``. Footers receive no calls.
  func refreshControl(_ control: FKRefreshControl, didUpdatePullProgress progress: CGFloat)
}

public extension FKRefreshContentView {
  func refreshControl(_ control: FKRefreshControl, didUpdatePullProgress progress: CGFloat) {}
}
