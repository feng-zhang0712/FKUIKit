//
// FKCornerShadowLayerStore.swift
//
// Runtime storage for FKCornerShadow layers.
//

import ObjectiveC.runtime
import UIKit

/// Associated-object keys used by FKCornerShadow.
///
/// These keys back style and layer cache storage without requiring view subclassing.
enum FKCornerShadowAssociatedKeys {
  /// Associated-object key for the latest applied style.
  nonisolated(unsafe) static var style: UInt8 = 0

  /// Associated-object key for internal layer store.
  nonisolated(unsafe) static var store: UInt8 = 0
}

/// Stores all internal layers for a host view.
///
/// Layer reuse avoids repeated allocations during frequent style updates.
final class FKCornerShadowLayerStore {
  /// Shape mask used to clip host content to rounded corners.
  let maskLayer = CAShapeLayer()

  /// Solid fill layer following rounded corner path.
  let fillLayer = CAShapeLayer()

  /// Gradient fill layer (masked by `fillGradientMaskLayer`).
  let fillGradientLayer = CAGradientLayer()

  /// Mask for gradient fill path.
  let fillGradientMaskLayer = CAShapeLayer()

  /// Solid border layer.
  let borderLayer = CAShapeLayer()

  /// Gradient border layer (masked by `borderGradientMaskLayer`).
  let borderGradientLayer = CAGradientLayer()

  /// Stroke mask for gradient border rendering.
  let borderGradientMaskLayer = CAShapeLayer()

  /// Side-specific shadow layers for partial-edge shadow mode.
  var sideShadowLayers: [FKCornerShadowSide: CAShapeLayer] = [:]

  /// Removes all side shadow layers.
  func removeAllShadowLayers() {
    sideShadowLayers.values.forEach { $0.removeFromSuperlayer() }
    sideShadowLayers.removeAll()
  }
}

extension UIView {
  /// Last style applied to the receiver via FKCornerShadow APIs.
  var fk_cornerShadowStyle: FKCornerShadowStyle? {
    get { objc_getAssociatedObject(self, &FKCornerShadowAssociatedKeys.style) as? FKCornerShadowStyle }
    set { objc_setAssociatedObject(self, &FKCornerShadowAssociatedKeys.style, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
  }

  /// Lazily created per-view layer store used by the renderer.
  var fk_cornerShadowLayerStore: FKCornerShadowLayerStore {
    if let store = objc_getAssociatedObject(self, &FKCornerShadowAssociatedKeys.store) as? FKCornerShadowLayerStore {
      return store
    }
    let store = FKCornerShadowLayerStore()
    objc_setAssociatedObject(self, &FKCornerShadowAssociatedKeys.store, store, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    return store
  }

  /// Clears the style snapshot kept in associated objects.
  func fk_cornerShadowClearAssociatedStyle() {
    fk_cornerShadowStyle = nil
  }
}
