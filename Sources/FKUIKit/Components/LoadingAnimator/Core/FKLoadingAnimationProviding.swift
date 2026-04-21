//
// FKLoadingAnimationProviding.swift
//

import QuartzCore
import UIKit

/// Protocol for pluggable loading animations.
///
/// Implementations should build `renderLayer` once and update only animatable values to keep CPU usage low.
@MainActor
public protocol FKLoadingAnimationProviding: AnyObject {
  /// Root layer rendered by the animation implementation.
  ///
  /// This layer is mounted into `FKLoadingAnimatorView` and reused across layout passes.
  var renderLayer: CALayer { get }

  /// Applies style values and drawing bounds to the animator.
  ///
  /// - Parameters:
  ///   - style: Shared style configuration for colors, timing, and geometry.
  ///   - bounds: Target drawing rect in the host container.
  func configure(style: FKLoadingAnimatorStyleConfiguration, bounds: CGRect)

  /// Starts all CoreAnimation timelines required by this style.
  func start()

  /// Stops the running animation and removes active CA animations.
  func stop()

  /// Pauses animations while preserving the current presentation frame.
  func pause()

  /// Resumes animations previously paused by `pause()`.
  func resume()

  /// Updates normalized progress for progress-capable styles.
  ///
  /// - Parameter progress: Progress value in the range `0...1`.
  func updateProgress(_ progress: CGFloat)
}
