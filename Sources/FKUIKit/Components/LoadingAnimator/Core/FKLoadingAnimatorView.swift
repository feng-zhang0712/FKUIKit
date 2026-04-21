//
// FKLoadingAnimatorView.swift
//

import UIKit

/// Reusable loading animation host view for both embedded and full-screen usage.
@MainActor
public final class FKLoadingAnimatorView: UIView {
  /// Current loading state.
  ///
  /// State transitions trigger `configuration.stateDidChange` callbacks.
  public private(set) var state: FKLoadingAnimatorState = .stopped {
    didSet { configuration.stateDidChange?(state) }
  }

  /// Last applied configuration snapshot.
  public private(set) var configuration: FKLoadingAnimatorConfiguration = .init()
  /// Current normalized progress value in `0...1`.
  public private(set) var progress: CGFloat = 0

  /// Active animator implementation for the current style.
  private var animator: FKLoadingAnimationProviding = FKRingLoadingAnimator()
  /// Centered container view for content background, corner radius, and fixed sizing.
  private let containerView = UIView()
  /// Width constraint updated when configuration size changes.
  private var widthConstraint: NSLayoutConstraint?
  /// Height constraint updated when configuration size changes.
  private var heightConstraint: NSLayoutConstraint?

  /// Initializes a loading animator view programmatically.
  ///
  /// - Parameter frame: Initial frame.
  public override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  /// Initializes a loading animator view from nib/storyboard.
  ///
  /// - Parameter coder: NSCoder used for decoding archived state.
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupUI()
  }

  /// Updates layout-sensitive geometry when bounds change.
  public override func layoutSubviews() {
    super.layoutSubviews()
    containerView.layer.cornerRadius = configuration.styleConfiguration.cornerRadius
    reconfigureAnimatorFrame()
  }

  /// Applies a full configuration and optionally restarts animation.
  ///
  /// - Parameters:
  ///   - configuration: New configuration to apply.
  ///   - restart: Whether to restart animation lifecycle immediately.
  public func apply(_ configuration: FKLoadingAnimatorConfiguration, restart: Bool = true) {
    fk_loadingAssertMainThread()
    self.configuration = configuration
    backgroundColor = configuration.presentationMode == .fullScreen ? configuration.maskColor.withAlphaComponent(configuration.maskAlpha) : .clear
    containerView.backgroundColor = configuration.backgroundColor
    containerView.layer.cornerRadius = configuration.styleConfiguration.cornerRadius
    widthConstraint?.constant = configuration.size.width
    heightConstraint?.constant = configuration.size.height

    // Reuse custom animator instance if caller passed the same object to avoid reset side effects.
    if case .custom(let existing) = configuration.style, existing === animator {
      animator.configure(style: configuration.styleConfiguration, bounds: animationBounds())
    } else {
      // Swap animator implementation atomically to ensure style transitions remain deterministic.
      animator.stop()
      animator.renderLayer.removeFromSuperlayer()
      animator = FKLoadingAnimatorFactory.makeAnimator(style: configuration.style)
      animator.configure(style: configuration.styleConfiguration, bounds: animationBounds())
      containerView.layer.addSublayer(animator.renderLayer)
    }

    if restart {
      configuration.autoStart ? start() : stop()
    }
  }

  /// Starts animation rendering.
  public func start() {
    fk_loadingAssertMainThread()
    animator.start()
    state = .loading
  }

  /// Stops animation and triggers completion callback.
  public func stop() {
    fk_loadingAssertMainThread()
    animator.stop()
    state = .stopped
    configuration.completion?()
  }

  /// Pauses animation without resetting current visual frame.
  public func pause() {
    fk_loadingAssertMainThread()
    animator.pause()
    state = .paused
  }

  /// Resumes from paused frame.
  public func resume() {
    fk_loadingAssertMainThread()
    animator.resume()
    state = .loading
  }

  /// Updates progress ring value from 0 to 1.
  ///
  /// - Parameter progress: Normalized progress value in the range `0...1`.
  public func setProgress(_ progress: CGFloat) {
    fk_loadingAssertMainThread()
    self.progress = min(max(progress, 0), 1)
    animator.updateProgress(self.progress)
  }

  /// Switches style in-place with the current configuration.
  ///
  /// - Parameters:
  ///   - style: New style to apply.
  ///   - autoRestart: Whether animation should restart after switching.
  public func switchStyle(_ style: FKLoadingAnimatorStyle, autoRestart: Bool = true) {
    var updated = configuration
    updated.style = style
    apply(updated, restart: autoRestart)
  }

  /// Constructs static UI hierarchy and layout constraints.
  private func setupUI() {
    isAccessibilityElement = false
    containerView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(containerView)
    widthConstraint = containerView.widthAnchor.constraint(equalToConstant: configuration.size.width)
    heightConstraint = containerView.heightAnchor.constraint(equalToConstant: configuration.size.height)
    NSLayoutConstraint.activate([
      containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
      containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
      widthConstraint!,
      heightConstraint!,
    ])
  }

  /// Re-applies animator frame and style after container layout changes.
  private func reconfigureAnimatorFrame() {
    let animatorBounds = animationBounds()
    // Disable implicit layer animations so layout updates do not produce flicker or extra GPU work.
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    animator.renderLayer.frame = animatorBounds
    animator.configure(style: configuration.styleConfiguration, bounds: animatorBounds)
    CATransaction.commit()
  }

  /// Computes effective drawing bounds for the active animator.
  ///
  /// - Returns: Insets-applied bounds, or full container bounds when inset result is invalid.
  private func animationBounds() -> CGRect {
    let frame = containerView.bounds.inset(by: configuration.animationInset)
    return frame.isNull || frame.isEmpty ? containerView.bounds : frame
  }
}
