//
// FKLoadingAnimatorConfig.swift
//

import UIKit

/// Immutable configuration used by `FKLoadingAnimatorView`.
public struct FKLoadingAnimatorConfiguration {
  /// Animation style to render.
  public var style: FKLoadingAnimatorStyle
  /// Fine-grained style tuning values for the selected style.
  public var styleConfiguration: FKLoadingAnimatorStyleConfiguration
  /// Fixed size of the centered animator container.
  public var size: CGSize
  /// Insets applied to the drawing area inside `size`.
  public var animationInset: UIEdgeInsets
  /// Background color of the animator container.
  public var backgroundColor: UIColor
  /// Mask color used in full-screen presentation mode.
  public var maskColor: UIColor
  /// Mask opacity in the range `0...1`.
  public var maskAlpha: CGFloat
  /// Enables closing full-screen loading by tapping the mask.
  public var allowsMaskTapToStop: Bool
  /// Starts animation automatically when applied.
  public var autoStart: Bool
  /// Controls embedded or full-screen presentation behavior.
  public var presentationMode: FKLoadingAnimatorPresentationMode
  /// Called when animation transitions to the stopped state.
  public var completion: (() -> Void)?
  /// Called whenever loading state changes (`loading`, `paused`, `stopped`).
  public var stateDidChange: ((FKLoadingAnimatorState) -> Void)?

  /// Creates a complete loading animator configuration.
  ///
  /// - Parameters:
  ///   - style: Animation style to display.
  ///   - styleConfiguration: Shared style options for selected animator.
  ///   - size: Container size in points.
  ///   - animationInset: Content insets applied to drawing bounds.
  ///   - backgroundColor: Container background color.
  ///   - maskColor: Overlay mask color for full-screen mode.
  ///   - maskAlpha: Overlay alpha in `0...1`.
  ///   - allowsMaskTapToStop: Whether mask taps hide loading.
  ///   - autoStart: Automatically starts animation after apply.
  ///   - presentationMode: Embedded or full-screen presentation mode.
  ///   - completion: Completion callback executed on stop.
  ///   - stateDidChange: State observer callback.
  public init(
    style: FKLoadingAnimatorStyle = .ring,
    styleConfiguration: FKLoadingAnimatorStyleConfiguration = .init(),
    size: CGSize = .init(width: 72, height: 72),
    animationInset: UIEdgeInsets = .init(top: 12, left: 12, bottom: 12, right: 12),
    backgroundColor: UIColor = .secondarySystemBackground,
    maskColor: UIColor = .black,
    maskAlpha: CGFloat = 0.2,
    allowsMaskTapToStop: Bool = false,
    autoStart: Bool = true,
    presentationMode: FKLoadingAnimatorPresentationMode = .embedded,
    completion: (() -> Void)? = nil,
    stateDidChange: ((FKLoadingAnimatorState) -> Void)? = nil
  ) {
    self.style = style
    self.styleConfiguration = styleConfiguration
    self.size = size
    self.animationInset = animationInset
    self.backgroundColor = backgroundColor
    self.maskColor = maskColor
    self.maskAlpha = maskAlpha
    self.allowsMaskTapToStop = allowsMaskTapToStop
    self.autoStart = autoStart
    self.presentationMode = presentationMode
    self.completion = completion
    self.stateDidChange = stateDidChange
  }
}
