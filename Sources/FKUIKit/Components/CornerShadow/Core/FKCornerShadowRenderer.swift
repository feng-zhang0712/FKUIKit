//
// FKCornerShadowRenderer.swift
//
// Core rendering implementation for FKCornerShadow.
//

import UIKit

/// Main renderer that updates corner, border, fill, and shadow layers.
///
/// The renderer is path-driven:
/// - rounded corners are generated from `UIBezierPath`
/// - shadows always rely on explicit `shadowPath`
/// This design minimizes implicit Core Animation work and keeps scrolling smooth.
enum FKCornerShadowRenderer {
  /// Applies style immediately for the current view bounds.
  ///
  /// - Parameters:
  ///   - style: Style descriptor containing corner, fill, border, and shadow.
  ///   - view: Target host view.
  static func apply(style: FKCornerShadowStyle, to view: UIView) {
    fk_cornerShadowAssertMainThread()
    guard view.bounds.width > 0, view.bounds.height > 0 else { return }
    installBaseLayersIfNeeded(on: view)
    render(style: style, on: view)
  }

  /// Re-renders the current associated style after layout updates.
  ///
  /// - Parameter view: Target host view that may have changed bounds.
  static func refreshIfNeeded(for view: UIView) {
    fk_cornerShadowAssertMainThread()
    guard let style = view.fk_cornerShadowStyle else { return }
    guard view.bounds.width > 0, view.bounds.height > 0 else { return }
    installBaseLayersIfNeeded(on: view)
    render(style: style, on: view)
  }

  /// Clears all rendering effects from a view.
  ///
  /// - Parameter view: Target host view.
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

  // MARK: - Private

  /// Installs and reuses base layers required by the renderer.
  ///
  /// - Parameter view: Target host view.
  ///
  /// - Performance: Layers are created once and reused across updates to avoid
  ///   repeated layer allocation during frequent layout passes.
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

  /// Renders all visual parts for the current style and bounds.
  ///
  /// - Parameters:
  ///   - style: Full style descriptor.
  ///   - view: Target host view.
  private static func render(style: FKCornerShadowStyle, on view: UIView) {
    let bounds = view.bounds
    // Build a deterministic rounded path once, then reuse it for mask/fill/border/shadow.
    let path = UIBezierPath(
      roundedRect: bounds,
      byRoundingCorners: style.corners,
      cornerRadii: CGSize(width: style.cornerRadius, height: style.cornerRadius)
    )
    let cgPath = path.cgPath
    let store = view.fk_cornerShadowLayerStore

    // Clip content with shape-mask while shadow remains externally controlled by `shadowPath`.
    // This avoids relying on `masksToBounds` for shadow rendering.
    store.maskLayer.frame = bounds
    store.maskLayer.path = cgPath
    view.layer.mask = store.maskLayer

    applyFill(style: style, store: store, path: path, bounds: bounds)
    applyBorder(style: style, store: store, path: path, bounds: bounds)
    applyShadow(style: style, view: view, path: path, bounds: bounds)
  }

  /// Applies solid/gradient fill following the rounded path.
  ///
  /// - Parameters:
  ///   - style: Current style descriptor.
  ///   - store: Layer store attached to host view.
  ///   - path: Rounded path for current bounds.
  ///   - bounds: Host view bounds.
  private static func applyFill(
    style: FKCornerShadowStyle,
    store: FKCornerShadowLayerStore,
    path: UIBezierPath,
    bounds: CGRect
  ) {
    // Solid fill always follows the rounded path.
    store.fillLayer.frame = bounds
    store.fillLayer.path = path.cgPath
    store.fillLayer.fillColor = style.fillColor?.cgColor ?? UIColor.clear.cgColor

    guard let gradient = style.fillGradient, gradient.colors.count >= 2 else {
      store.fillGradientLayer.isHidden = true
      store.fillGradientLayer.mask = nil
      return
    }

    // Gradient fill is masked by the same rounded path for pixel-perfect edge alignment.
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

  /// Applies solid or gradient border using the same rounded path.
  ///
  /// - Parameters:
  ///   - style: Current style descriptor.
  ///   - store: Layer store attached to host view.
  ///   - path: Rounded path for current bounds.
  ///   - bounds: Host view bounds.
  private static func applyBorder(
    style: FKCornerShadowStyle,
    store: FKCornerShadowLayerStore,
    path: UIBezierPath,
    bounds: CGRect
  ) {
    // Border rendering shares the exact corner path to avoid mismatch between stroke and mask.
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

  /// Applies full or side-specific shadow rendering.
  ///
  /// - Parameters:
  ///   - style: Current style descriptor.
  ///   - view: Target host view.
  ///   - path: Rounded base path.
  ///   - bounds: Host view bounds.
  private static func applyShadow(
    style: FKCornerShadowStyle,
    view: UIView,
    path: UIBezierPath,
    bounds: CGRect
  ) {
    guard let shadow = style.shadow, shadow.opacity > 0 else {
      view.layer.shadowOpacity = 0
      view.layer.shadowPath = nil
      view.fk_cornerShadowLayerStore.removeAllShadowLayers()
      return
    }

    let spreadInset = -shadow.spread
    let spreadBounds = bounds.insetBy(dx: spreadInset, dy: spreadInset)
    // Spread is implemented by expanding/contracting the explicit shadow path.
    let spreadPath = UIBezierPath(
      roundedRect: spreadBounds,
      byRoundingCorners: style.corners,
      cornerRadii: CGSize(width: style.cornerRadius + shadow.spread, height: style.cornerRadius + shadow.spread)
    )

    if shadow.sides == .all {
      view.fk_cornerShadowLayerStore.removeAllShadowLayers()
      // Full-shadow mode uses host-layer `shadowPath` for best rendering performance.
      // Explicit `shadowPath` avoids Core Animation's expensive dynamic shadow geometry inference.
      view.layer.shadowColor = shadow.color.cgColor
      view.layer.shadowOpacity = shadow.opacity
      view.layer.shadowOffset = shadow.offset
      view.layer.shadowRadius = shadow.blur
      view.layer.shadowPath = spreadPath.cgPath
      return
    }

    // Disable host layer shadow and render side-specific shadow carriers.
    view.layer.shadowOpacity = 0
    view.layer.shadowPath = nil
    applySideShadows(style: style, shadow: shadow, view: view, spreadPath: spreadPath, bounds: bounds, basePath: path)
  }

  /// Applies side-specific shadow layers when `.all` is not selected.
  ///
  /// - Parameters:
  ///   - style: Current style descriptor.
  ///   - shadow: Shadow descriptor.
  ///   - view: Target host view.
  ///   - spreadPath: Spread-adjusted rounded path.
  ///   - bounds: Host view bounds.
  ///   - basePath: Original rounded base path.
  private static func applySideShadows(
    style: FKCornerShadowStyle,
    shadow: FKCornerShadowShadow,
    view: UIView,
    spreadPath: UIBezierPath,
    bounds: CGRect,
    basePath: UIBezierPath
  ) {
    let store = view.fk_cornerShadowLayerStore
    // Build selected edge list once to reduce branching in the update loop.
    let selected: [FKCornerShadowSide] = [.top, .left, .bottom, .right].filter { shadow.sides.contains($0) }

    // Remove stale side layers.
    let staleKeys = Set(store.sideShadowLayers.keys).subtracting(selected)
    for key in staleKeys {
      store.sideShadowLayers[key]?.removeFromSuperlayer()
      store.sideShadowLayers.removeValue(forKey: key)
    }

    for side in selected {
      let layer = store.sideShadowLayers[side] ?? {
        let l = CAShapeLayer()
        l.fillColor = UIColor.clear.cgColor
        // Side layers are inserted below content/border layers.
        view.layer.insertSublayer(l, at: 0)
        store.sideShadowLayers[side] = l
        return l
      }()

      layer.frame = bounds
      layer.path = basePath.cgPath
      layer.shadowColor = shadow.color.cgColor
      layer.shadowOpacity = shadow.opacity
      layer.shadowOffset = shadow.offset
      layer.shadowRadius = shadow.blur
      layer.shadowPath = spreadPath.cgPath
      // A side mask clips shadow visibility to specific edges while still using explicit path.
      layer.mask = sideMaskLayer(for: side, bounds: bounds, blur: shadow.blur, spread: shadow.spread)
    }

    // Keep visual z-order for borders.
    if store.borderLayer.superlayer === view.layer {
      view.layer.addSublayer(store.borderLayer)
    }
    if store.borderGradientLayer.superlayer === view.layer {
      view.layer.addSublayer(store.borderGradientLayer)
    }

    // Keep compiler happy and preserve compatibility with the current function contract.
    _ = style
  }

  /// Builds a rectangular mask used to clip a side-specific shadow carrier.
  ///
  /// - Parameters:
  ///   - side: Target edge.
  ///   - bounds: Host view bounds.
  ///   - blur: Shadow blur radius.
  ///   - spread: Shadow spread radius.
  /// - Returns: A configured mask layer for the requested edge.
  ///
  /// - Performance: Mask geometry is lightweight rectangle math to keep updates cheap.
  private static func sideMaskLayer(
    for side: FKCornerShadowSide,
    bounds: CGRect,
    blur: CGFloat,
    spread: CGFloat
  ) -> CAShapeLayer {
    let mask = CAShapeLayer()
    let padding = max(blur * 2 + abs(spread), 8)
    let rect: CGRect
    switch side {
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
    return mask
  }
}
