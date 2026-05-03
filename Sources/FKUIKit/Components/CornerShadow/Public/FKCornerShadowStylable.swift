//
// FKCornerShadowStylable.swift
//

import UIKit

/// Host types that support FKCornerShadow styling (`UIView` conforms by default).
@MainActor
public protocol FKCornerShadowStylable: AnyObject {
  func fk_applyCornerShadow(_ style: FKCornerShadowStyle)
  /// Copies `FKCornerShadowManager.shared.defaultStyle`, applies `configure`, then installs the result.
  func fk_applyCornerShadowFromDefaults(_ configure: ((inout FKCornerShadowStyle) -> Void)?)
  func fk_resetCornerShadow()
}
