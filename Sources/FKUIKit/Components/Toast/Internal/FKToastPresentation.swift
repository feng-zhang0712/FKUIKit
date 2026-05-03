import UIKit

/// Binds one in-flight request to its rendered view and layout state.
final class FKToastPresentation {
  var request: FKToastRequest
  let view: FKToastView
  let resolvedPosition: FKToastPosition
  let positionConstraint: NSLayoutConstraint
  weak var hostWindow: UIWindow?

  init(
    request: FKToastRequest,
    view: FKToastView,
    resolvedPosition: FKToastPosition,
    positionConstraint: NSLayoutConstraint,
    hostWindow: UIWindow?
  ) {
    self.request = request
    self.view = view
    self.resolvedPosition = resolvedPosition
    self.positionConstraint = positionConstraint
    self.hostWindow = hostWindow
  }
}
