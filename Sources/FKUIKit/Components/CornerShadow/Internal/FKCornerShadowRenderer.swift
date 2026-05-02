//
// FKCornerShadowRenderer.swift
//

import UIKit

enum FKCornerShadowRenderer {
  static func apply(style: FKCornerShadowStyle, to view: UIView) {
    fk_cornerShadowAssertMainThread()
    guard view.bounds.width > 0, view.bounds.height > 0 else { return }
    installBaseLayersIfNeeded(on: view)
    render(style: style, on: view)
  }

  static func refreshIfNeeded(for view: UIView) {
    fk_cornerShadowAssertMainThread()
    guard let style = view.fk_cornerShadowStyle else { return }
    guard view.bounds.width > 0, view.bounds.height > 0 else { return }
    installBaseLayersIfNeeded(on: view)
    render(style: style, on: view)
  }

  static func reset(on view: UIView) {
    fk_cornerShadowAssertMainThread()
    let store = view.fk_cornerShadowLayerStore
    store.maskLayer.removeFromSuperlayer()
    store.fillLayer.removeFromSuperlayer()
    store.fillGradientLayer.removeFromSuperlayer()
    store.borderLayer.removeFromSuperlayer()
    store.borderGradientLayer.removeFromSuperlayer()
    store.removeAllShadowLayers()
    view.layer.mask = nil
    view.layer.shadowOpacity = 0
    view.layer.shadowPath = nil
    view.layer.shadowColor = nil
    view.layer.shadowRadius = 0
    view.layer.shadowOffset = .zero
  }

  private static func installBaseLayersIfNeeded(on view: UIView) {
    let store = view.fk_cornerShadowLayerStore

    if store.fillLayer.superlayer !== view.layer {
      store.fillLayer.fillColor = UIColor.clear.cgColor
      view.layer.insertSublayer(store.fillLayer, at: 0)
    }

    if store.fillGradientLayer.superlayer !== view.layer {
      store.fillGradientLayer.isHidden = true
      view.layer.insertSublayer(store.fillGradientLayer, above: store.fillLayer)
    }

    if store.borderLayer.superlayer !== view.layer {
      store.borderLayer.fillColor = UIColor.clear.cgColor
      view.layer.addSublayer(store.borderLayer)
    }

    if store.borderGradientLayer.superlayer !== view.layer {
      store.borderGradientLayer.isHidden = true
      store.borderGradientLayer.mask = store.borderGradientMaskLayer
      view.layer.addSublayer(store.borderGradientLayer)
    }
  }

  private static func render(style: FKCornerShadowStyle, on view: UIView) {
    let bounds = view.bounds
    let path = UIBezierPath(
      roundedRect: bounds,
      byRoundingCorners: style.corners,
      cornerRadii: CGSize(width: style.cornerRadius, height: style.cornerRadius)
    )
    let cgPath = path.cgPath
    let store = view.fk_cornerShadowLayerStore

    store.maskLayer.frame = bounds
    store.maskLayer.path = cgPath
    view.layer.mask = store.maskLayer

    applyFill(style: style, store: store, path: path, bounds: bounds)
    applyBorder(style: style, store: store, path: path, bounds: bounds)
    applyShadow(style: style, view: view, path: path, bounds: bounds)
  }

  private static func applyFill(
    style: FKCornerShadowStyle,
    store: FKCornerShadowLayerStore,
    path: UIBezierPath,
    bounds: CGRect
  ) {
    store.fillLayer.frame = bounds
    store.fillLayer.path = path.cgPath
    store.fillLayer.fillColor = style.fillColor?.cgColor ?? UIColor.clear.cgColor

    guard let gradient = style.fillGradient, gradient.colors.count >= 2 else {
      store.fillGradientLayer.isHidden = true
      store.fillGradientLayer.mask = nil
      return
    }

    store.fillGradientLayer.isHidden = false
    store.fillGradientLayer.frame = bounds
    store.fillGradientLayer.colors = gradient.colors.map(\.cgColor)
    store.fillGradientLayer.locations = gradient.locations
    store.fillGradientLayer.startPoint = gradient.startPoint
    store.fillGradientLayer.endPoint = gradient.endPoint
    store.fillGradientMaskLayer.frame = bounds
    store.fillGradientMaskLayer.path = path.cgPath
    store.fillGradientLayer.mask = store.fillGradientMaskLayer
  }

  private static func applyBorder(
    style: FKCornerShadowStyle,
    store: FKCornerShadowLayerStore,
    path: UIBezierPath,
    bounds: CGRect
  ) {
    switch style.border {
    case .none:
      store.borderLayer.isHidden = true
      store.borderGradientLayer.isHidden = true
      store.borderGradientLayer.mask = nil

    case let .solid(color, width):
      store.borderLayer.isHidden = false
      store.borderLayer.frame = bounds
      store.borderLayer.path = path.cgPath
      store.borderLayer.strokeColor = color.cgColor
      store.borderLayer.lineWidth = width
      store.borderGradientLayer.isHidden = true
      store.borderGradientLayer.mask = nil

    case let .gradient(gradient, width):
      store.borderLayer.isHidden = true
      store.borderGradientLayer.isHidden = false
      store.borderGradientLayer.frame = bounds
      store.borderGradientLayer.colors = gradient.colors.map(\.cgColor)
      store.borderGradientLayer.locations = gradient.locations
      store.borderGradientLayer.startPoint = gradient.startPoint
      store.borderGradientLayer.endPoint = gradient.endPoint

      store.borderGradientMaskLayer.frame = bounds
      store.borderGradientMaskLayer.path = path.cgPath
      store.borderGradientMaskLayer.fillColor = UIColor.clear.cgColor
      store.borderGradientMaskLayer.strokeColor = UIColor.black.cgColor
      store.borderGradientMaskLayer.lineWidth = width
      store.borderGradientLayer.mask = store.borderGradientMaskLayer
    }
  }

  private static func applyShadow(
    style: FKCornerShadowStyle,
    view: UIView,
    path: UIBezierPath,
    bounds: CGRect
  ) {
    guard let elevation = style.shadow, elevation.opacity > 0 else {
      view.layer.shadowOpacity = 0
      view.layer.shadowPath = nil
      view.fk_cornerShadowLayerStore.removeAllShadowLayers()
      return
    }

    let spreadInset = -elevation.spread
    let spreadBounds = bounds.insetBy(dx: spreadInset, dy: spreadInset)
    let spreadPath = UIBezierPath(
      roundedRect: spreadBounds,
      byRoundingCorners: style.corners,
      cornerRadii: CGSize(width: style.cornerRadius + elevation.spread, height: style.cornerRadius + elevation.spread)
    )

    if elevation.edges == .all {
      view.fk_cornerShadowLayerStore.removeAllShadowLayers()
      view.layer.shadowColor = elevation.color.cgColor
      view.layer.shadowOpacity = elevation.opacity
      view.layer.shadowOffset = elevation.offset
      view.layer.shadowRadius = elevation.blur
      view.layer.shadowPath = spreadPath.cgPath
      return
    }

    view.layer.shadowOpacity = 0
    view.layer.shadowPath = nil
    applyEdgeShadows(
      elevation: elevation,
      view: view,
      spreadPath: spreadPath,
      bounds: bounds,
      basePath: path
    )
  }

  private static func applyEdgeShadows(
    elevation: FKCornerShadowElevation,
    view: UIView,
    spreadPath: UIBezierPath,
    bounds: CGRect,
    basePath: UIBezierPath
  ) {
    let store = view.fk_cornerShadowLayerStore
    let selected: [FKCornerShadowEdge] = [.top, .left, .bottom, .right].filter { elevation.edges.contains($0) }

    let staleKeys = Set(store.edgeShadowLayers.keys).subtracting(selected)
    for key in staleKeys {
      store.edgeShadowLayers[key]?.removeFromSuperlayer()
      store.edgeShadowLayers.removeValue(forKey: key)
    }

    for edge in selected {
      let layer = store.edgeShadowLayers[edge] ?? {
        let l = CAShapeLayer()
        l.fillColor = UIColor.clear.cgColor
        view.layer.insertSublayer(l, at: 0)
        store.edgeShadowLayers[edge] = l
        return l
      }()

      layer.frame = bounds
      layer.path = basePath.cgPath
      layer.shadowColor = elevation.color.cgColor
      layer.shadowOpacity = elevation.opacity
      layer.shadowOffset = elevation.offset
      layer.shadowRadius = elevation.blur
      layer.shadowPath = spreadPath.cgPath
      updateEdgeShadowMask(
        on: layer,
        edge: edge,
        bounds: bounds,
        blur: elevation.blur,
        spread: elevation.spread,
        offset: elevation.offset
      )
    }

    if store.borderLayer.superlayer === view.layer {
      view.layer.addSublayer(store.borderLayer)
    }
    if store.borderGradientLayer.superlayer === view.layer {
      view.layer.addSublayer(store.borderGradientLayer)
    }
  }

  private static func updateEdgeShadowMask(
    on layer: CAShapeLayer,
    edge: FKCornerShadowEdge,
    bounds: CGRect,
    blur: CGFloat,
    spread: CGFloat,
    offset: CGSize
  ) {
    let mask: CAShapeLayer = {
      if let existing = layer.mask as? CAShapeLayer {
        return existing
      }
      let created = CAShapeLayer()
      layer.mask = created
      return created
    }()
    let padding = max(blur * 2 + abs(spread) + abs(offset.width) + abs(offset.height), 8)
    let rect: CGRect
    switch edge {
    case .top:
      rect = CGRect(x: -padding, y: -padding, width: bounds.width + padding * 2, height: bounds.height / 2 + padding)
    case .left:
      rect = CGRect(x: -padding, y: -padding, width: bounds.width / 2 + padding, height: bounds.height + padding * 2)
    case .bottom:
      rect = CGRect(x: -padding, y: bounds.height / 2, width: bounds.width + padding * 2, height: bounds.height / 2 + padding)
    case .right:
      rect = CGRect(x: bounds.width / 2, y: -padding, width: bounds.width / 2 + padding, height: bounds.height + padding * 2)
    default:
      rect = bounds.insetBy(dx: -padding, dy: -padding)
    }
    mask.path = UIBezierPath(rect: rect).cgPath
  }
}
