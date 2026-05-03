//
// FKMultiPickerAnimator.swift
//

import UIKit

@MainActor
enum FKMultiPickerAnimator {
  static func present(
    maskView: UIView,
    containerView: UIView,
    duration: TimeInterval,
    completion: (() -> Void)? = nil
  ) {
    maskView.alpha = 0
    containerView.transform = CGAffineTransform(translationX: 0, y: containerView.bounds.height + 20)
    UIView.animate(
      withDuration: duration,
      delay: 0,
      options: [.curveEaseOut, .allowUserInteraction]
    ) {
      maskView.alpha = 1
      containerView.transform = .identity
    } completion: { _ in
      completion?()
    }
  }

  static func dismiss(
    maskView: UIView,
    containerView: UIView,
    duration: TimeInterval,
    completion: (() -> Void)? = nil
  ) {
    UIView.animate(
      withDuration: duration,
      delay: 0,
      options: [.curveEaseIn, .allowUserInteraction]
    ) {
      maskView.alpha = 0
      containerView.transform = CGAffineTransform(translationX: 0, y: containerView.bounds.height + 20)
    } completion: { _ in
      completion?()
    }
  }
}
