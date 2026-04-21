//
// FKLoadingOverlayView.swift
//

import UIKit

/// Full-screen mask container that hosts a centered `FKLoadingAnimatorView`.
///
/// This view is used by `.fullScreen` presentation mode and supports optional mask tap handling.
@MainActor
final class FKLoadingOverlayView: UIView {
  /// Embedded animator host responsible for style rendering and state transitions.
  let animatorView = FKLoadingAnimatorView()
  /// Tap callback invoked when the overlay mask is tapped.
  var onMaskTap: (() -> Void)?

  /// Initializes overlay using frame-based construction.
  ///
  /// - Parameter frame: Initial view frame.
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  /// Initializes overlay when loaded from nib/storyboard.
  ///
  /// - Parameter coder: NSCoder instance for archive decoding.
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupUI()
  }

  /// Applies overlay and animator configuration.
  ///
  /// - Parameter configuration: Full loading animator configuration.
  func apply(_ configuration: FKLoadingAnimatorConfiguration) {
    backgroundColor = configuration.maskColor.withAlphaComponent(configuration.maskAlpha)
    animatorView.apply(configuration, restart: false)
    animatorView.configuration.autoStart ? animatorView.start() : animatorView.stop()
    isUserInteractionEnabled = true
  }

  /// Builds view hierarchy, constraints, and tap gesture recognizer.
  private func setupUI() {
    translatesAutoresizingMaskIntoConstraints = false
    animatorView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(animatorView)
    NSLayoutConstraint.activate([
      animatorView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
      animatorView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
      animatorView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
      animatorView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
    ])
    let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
    addGestureRecognizer(tap)
  }

  /// Handles user taps on the mask layer.
  @objc
  private func handleTap() {
    onMaskTap?()
  }
}
