//
// FKMultiPickerAnimator.swift
//
// Presentation animation helper for FKMultiPicker.
//

import UIKit

/// Animation helper that encapsulates picker presentation transitions.
///
/// This type centralizes fade and slide animations so the core view logic can remain focused
/// on data linkage and layout responsibilities.
@MainActor
enum FKMultiPickerAnimator {
  /// Plays present animation.
  ///
  /// - Parameters:
  ///   - maskView: The dimming overlay view behind the sheet.
  ///   - containerView: The bottom sheet container to animate.
  ///   - duration: Animation duration in seconds.
  ///   - completion: Called after animation finishes.
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

  /// Plays dismiss animation.
  ///
  /// - Parameters:
  ///   - maskView: The dimming overlay view behind the sheet.
  ///   - containerView: The bottom sheet container to animate.
  ///   - duration: Animation duration in seconds.
  ///   - completion: Called after animation finishes.
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
