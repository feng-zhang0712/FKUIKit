//
// FKCornerShadowBorder.swift
//

import UIKit

/// Border drawn along the same rounded path as the clip shape.
public enum FKCornerShadowBorder {
  case none
  case solid(color: UIColor, width: CGFloat)
  case gradient(gradient: FKCornerShadowGradient, width: CGFloat)
}
