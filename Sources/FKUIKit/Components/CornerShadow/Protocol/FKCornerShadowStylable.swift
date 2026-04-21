//
// FKCornerShadowStylable.swift
//
// Protocol abstraction for testability and extensibility.
//

import UIKit

/// Describes a host that can apply FKCornerShadow styles.
///
/// Adopted by `UIView` so every UIKit subclass can access the same non-invasive API.
/// This protocol keeps the component testable and makes future host types pluggable.
@MainActor
public protocol FKCornerShadowStylable: AnyObject {
  /// Applies a concrete corner-shadow style.
  ///
  /// - Parameter style: Full style descriptor including corners, fill, border, and shadow.
  func fk_applyCornerShadow(_ style: FKCornerShadowStyle)

  /// Applies the global default style with optional local overrides.
  ///
  /// - Parameter configure: Optional closure used to mutate a copy of the global style.
  func fk_applyCornerShadowFromGlobal(configure: ((inout FKCornerShadowStyle) -> Void)?)

  /// Clears all FKCornerShadow layers and associated style state.
  ///
  /// Use this API in reusable views to avoid stale layer artifacts.
  func fk_resetCornerShadow()
}
