//
// FKCornerShadowGradient.swift
//

import UIKit

/// Linear gradient used for fill or stroke (border) under rounded corners.
public struct FKCornerShadowGradient {
  public var colors: [UIColor]
  /// Stop positions in `[0, 1]`; use `nil` for even spacing.
  public var locations: [NSNumber]?
  public var startPoint: CGPoint
  public var endPoint: CGPoint

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
