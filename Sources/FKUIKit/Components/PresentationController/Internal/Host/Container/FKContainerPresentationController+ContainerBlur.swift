import UIKit

@MainActor
extension FKContainerPresentationController {
  /// Applies optional blur material on the presented container.
  func configureContainerBlurIfNeeded() {
    let blur = configuration.containerBlur
    guard blur.isEnabled else {
      containerBlurView.isHidden = true
      containerBlurView.blurSourceView = nil
      wrapperView.backgroundColor = .systemBackground
      return
    }

    containerBlurView.isHidden = false
    containerBlurView.configuration = blur.configuration
    containerBlurView.blurSourceView = presentingViewController.view
    wrapperView.backgroundColor = .clear
  }
}

