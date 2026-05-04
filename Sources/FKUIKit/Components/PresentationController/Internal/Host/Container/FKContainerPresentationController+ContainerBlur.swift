import UIKit

@MainActor
extension FKContainerPresentationController {
  /// Applies optional blur material on the presented container.
  func configureContainerBlurIfNeeded() {
    let blur = configuration.containerBlur
    guard blur.isEnabled else {
      containerBlurView?.blurSourceView = nil
      containerBlurView?.removeFromSuperview()
      containerBlurView = nil
      wrapperView.backgroundColor = .systemBackground
      return
    }

    let blurView: FKBlurView
    if let existing = containerBlurView {
      blurView = existing
    } else {
      let v = FKBlurView()
      v.isUserInteractionEnabled = false
      wrapperView.insertSubview(v, belowSubview: contentContainerView)
      containerBlurView = v
      blurView = v
    }
    blurView.isHidden = false
    blurView.configuration = blur.configuration
    blurView.blurSourceView = presentingViewController.view
    wrapperView.backgroundColor = .clear
  }
}

