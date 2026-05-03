//
// FKCornerShadowManager.swift
//

import UIKit

/// App-wide default `FKCornerShadowStyle` consumed by `fk_applyCornerShadowFromDefaults`.
@MainActor
public final class FKCornerShadowManager {
  public static let shared = FKCornerShadowManager()

  /// Copied before each apply; mutating copies does not change this property until you assign back.
  public var defaultStyle = FKCornerShadowStyle.none

  private init() {}

  public func configureDefaultStyle(_ block: (inout FKCornerShadowStyle) -> Void) {
    var style = defaultStyle
    block(&style)
    defaultStyle = style
  }

  public func resetDefaultStyle() {
    defaultStyle = .none
  }
}
