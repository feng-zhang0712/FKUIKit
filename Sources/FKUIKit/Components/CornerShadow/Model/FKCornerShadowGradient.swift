//
// FKCornerShadowGradient.swift
//
// Gradient models used by FKCornerShadow.
//

import UIKit

/// Defines a linear gradient.
///
/// This model is reused by both fill gradients and border gradients to keep the API
/// consistent across visual effects.
public struct FKCornerShadowGradient {
  /// Gradient colors in rendering order.
  ///
  /// - Note: At least two colors are required for visible gradient interpolation.
  public var colors: [UIColor]

  /// Gradient stop locations in `[0, 1]`. `nil` uses even distribution.
  ///
  /// The count should match `colors.count` when specified.
  public var locations: [NSNumber]?

  /// Gradient start point in unit coordinates.
  ///
  /// Default is left-center: `(0, 0.5)`.
  public var startPoint: CGPoint

  /// Gradient end point in unit coordinates.
  ///
  /// Default is right-center: `(1, 0.5)`.
  public var endPoint: CGPoint

  /// Creates a gradient descriptor.
  ///
  /// - Parameters:
  ///   - colors: Gradient colors in display order.
  ///   - locations: Optional stop positions in `[0, 1]`.
  ///   - startPoint: Gradient start point in unit coordinates.
  ///   - endPoint: Gradient end point in unit coordinates.
  public init(
    colors: [UIColor],
    locations: [NSNumber]? = nil,
    startPoint: CGPoint = CGPoint(x: 0, y: 0.5),
    endPoint: CGPoint = CGPoint(x: 1, y: 0.5)
  ) {
    self.colors = colors
    self.locations = locations
    self.startPoint = startPoint
    self.endPoint = endPoint
  }
}
