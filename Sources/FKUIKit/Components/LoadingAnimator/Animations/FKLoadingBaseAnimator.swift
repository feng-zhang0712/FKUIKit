//
// FKLoadingBaseAnimator.swift
//

import QuartzCore
import UIKit

/// Base animator implementation that provides shared layer and lifecycle behavior.
///
/// Concrete animators subclass this type and override only the pieces they need
/// (`configure`, `start`, `updateProgress`) to keep implementations lightweight.
@MainActor
class FKLoadingBaseAnimator: NSObject, FKLoadingAnimationProviding {
  /// Root rendering layer mounted by the host view.
  let renderLayer = CALayer()
  /// Last applied style configuration.
  var style = FKLoadingAnimatorStyleConfiguration()
  /// Last applied drawing bounds.
  var bounds: CGRect = .zero

  /// Applies shared style values and target bounds.
  ///
  /// - Parameters:
  ///   - style: Style values used for drawing and timing.
  ///   - bounds: Drawing area within the host container.
  func configure(style: FKLoadingAnimatorStyleConfiguration, bounds: CGRect) {
    self.style = style
    self.bounds = bounds
    renderLayer.frame = bounds
  }

  /// Starts animation timelines. Subclasses override when needed.
  func start() {}

  /// Stops all running animations from root and sublayers.
  ///
  /// Removing animations is cheaper than recreating layers and helps avoid unnecessary allocations.
  func stop() {
    renderLayer.removeAllAnimations()
    renderLayer.sublayers?.forEach { $0.removeAllAnimations() }
  }

  /// Pauses animation by freezing layer time space.
  ///
  /// The current presentation timestamp is stored in `timeOffset` so resume can continue smoothly.
  func pause() {
    let paused = renderLayer.convertTime(CACurrentMediaTime(), from: nil)
    renderLayer.speed = 0
    renderLayer.timeOffset = paused
  }

  /// Resumes animation from a previously paused `timeOffset`.
  ///
  /// This restores temporal continuity without visual jumps.
  func resume() {
    let paused = renderLayer.timeOffset
    renderLayer.speed = 1
    renderLayer.timeOffset = 0
    renderLayer.beginTime = 0
    renderLayer.beginTime = renderLayer.convertTime(CACurrentMediaTime(), from: nil) - paused
  }

  /// Updates determinate progress. Subclasses override when style supports progress.
  ///
  /// - Parameter progress: Normalized progress in `0...1`.
  func updateProgress(_ progress: CGFloat) {}
}
