import UIKit

/// Wraps an arbitrary `UIView` so it can serve as ``FKRefreshContentView``.
/// Update the hosted view from your controller in response to ``FKRefreshControl/onStateChanged``
/// or by subclassing and overriding transition hooks.
public final class FKHostedRefreshContentView: UIView, FKRefreshContentView {

  public let hostedView: UIView

  public init(hostedView: UIView) {
    self.hostedView = hostedView
    super.init(frame: .zero)
    hostedView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(hostedView)
    NSLayoutConstraint.activate([
      hostedView.topAnchor.constraint(equalTo: topAnchor),
      hostedView.leadingAnchor.constraint(equalTo: leadingAnchor),
      hostedView.trailingAnchor.constraint(equalTo: trailingAnchor),
      hostedView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }

  public required init?(coder: NSCoder) {
    nil
  }

  public func refreshControl(_ control: FKRefreshControl, didTransitionTo state: FKRefreshState, from previous: FKRefreshState) {}

  public func refreshControl(_ control: FKRefreshControl, didUpdatePullProgress progress: CGFloat) {}
}
