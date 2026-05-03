//
// FKCornerShadowLayerStore.swift
//

import ObjectiveC.runtime
import UIKit

enum FKCornerShadowAssociatedKeys {
  nonisolated(unsafe) static var style: UInt8 = 0
  nonisolated(unsafe) static var store: UInt8 = 0
}

final class FKCornerShadowLayerStore {
  let maskLayer = CAShapeLayer()
  let fillLayer = CAShapeLayer()
  let fillGradientLayer = CAGradientLayer()
  let fillGradientMaskLayer = CAShapeLayer()
  let borderLayer = CAShapeLayer()
  let borderGradientLayer = CAGradientLayer()
  let borderGradientMaskLayer = CAShapeLayer()

  /// Sub-layers used when `FKCornerShadowElevation.edges` is not `.all`.
  var edgeShadowLayers: [FKCornerShadowEdge: CAShapeLayer] = [:]

  func removeAllShadowLayers() {
    edgeShadowLayers.values.forEach { $0.removeFromSuperlayer() }
    edgeShadowLayers.removeAll()
  }
}

extension UIView {
  var fk_cornerShadowStyle: FKCornerShadowStyle? {
    get { objc_getAssociatedObject(self, &FKCornerShadowAssociatedKeys.style) as? FKCornerShadowStyle }
    set { objc_setAssociatedObject(self, &FKCornerShadowAssociatedKeys.style, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
  }

  var fk_cornerShadowLayerStore: FKCornerShadowLayerStore {
    if let store = objc_getAssociatedObject(self, &FKCornerShadowAssociatedKeys.store) as? FKCornerShadowLayerStore {
      return store
    }
    let store = FKCornerShadowLayerStore()
    objc_setAssociatedObject(self, &FKCornerShadowAssociatedKeys.store, store, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    return store
  }

  func fk_cornerShadowClearAssociatedStyle() {
    fk_cornerShadowStyle = nil
  }
}
