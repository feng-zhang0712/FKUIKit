//
// FKCornerShadowManager.swift
//
// Global style manager for FKCornerShadow.
//

import UIKit

/// Shared manager for global FKCornerShadow defaults.
///
/// Use this singleton to define app-wide corner, border, and shadow presets once,
/// then apply them with one-line APIs on any view.
///
/// - Performance: Reusing a shared style object minimizes repeated style construction
///   on heavily reused UI surfaces such as feed cells and dashboard cards.
@MainActor
public final class FKCornerShadowManager {
  /// Singleton instance.
  public static let shared = FKCornerShadowManager()

  /// Global default style used by one-line apply APIs.
  ///
  /// This value is copied before mutation so local overrides do not affect global state.
  public var defaultStyle = FKCornerShadowStyle.none

  /// Creates the singleton instance.
  ///
  /// The initializer is intentionally private to enforce a single source of truth.
  private init() {
    // Keep init private for singleton semantics.
  }

  /// Mutates the global default style in place.
  ///
  /// - Parameter block: A closure that receives an `inout` style copy to mutate.
  public func configureDefaultStyle(_ block: (inout FKCornerShadowStyle) -> Void) {
    var style = defaultStyle
    block(&style)
    defaultStyle = style
  }

  /// Restores the global default style to `none`.
  ///
  /// Call this when switching design themes dynamically or when resetting test fixtures.
  public func resetDefaultStyle() {
    defaultStyle = .none
  }
}
