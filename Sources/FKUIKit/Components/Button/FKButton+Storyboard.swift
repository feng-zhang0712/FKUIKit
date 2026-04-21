//
//  FKButton+Storyboard.swift
//
//  Interface Builder attributes (`@IBInspectable` / `@IBDesignable`).
//

import UIKit

// MARK: - Interface Builder

public extension FKButton {

  // MARK: Interaction & disabled state

  /// Mirrors `minimumTapInterval` for Interface Builder (seconds).
  @IBInspectable public var fk_minimumTapInterval: CGFloat {
    get { CGFloat(minimumTapInterval) }
    set { minimumTapInterval = TimeInterval(newValue) }
  }

  @IBInspectable public var fk_longPressMinimumDuration: CGFloat {
    get { CGFloat(longPressMinimumDuration) }
    set { longPressMinimumDuration = TimeInterval(newValue) }
  }

  /// Uniform expansion of the hit target (maps to negative `hitTestEdgeInsets` on all edges).
  @IBInspectable public var fk_hitTestMargin: CGFloat {
    get { -hitTestEdgeInsets.top }
    set {
      let m = newValue
      hitTestEdgeInsets = UIEdgeInsets(top: -m, left: -m, bottom: -m, right: -m)
    }
  }

  @IBInspectable public var fk_automaticallyDimsWhenDisabled: Bool {
    get { automaticallyDimsWhenDisabled }
    set { automaticallyDimsWhenDisabled = newValue }
  }

  @IBInspectable public var fk_disabledDimmingAlpha: CGFloat {
    get { disabledDimmingAlpha }
    set { disabledDimmingAlpha = newValue }
  }

  // MARK: Loading

  /// When `loadingPresentationStyle` is `.overlay`, this reads/writes the dimmed content alpha. Otherwise sets `.overlay(dimmedContentAlpha:)`.
  @IBInspectable public var fk_overlayLoadingDimmedAlpha: CGFloat {
    get {
      if case .overlay(let a) = loadingPresentationStyle { return a }
      return 0.35
    }
    set {
      loadingPresentationStyle = .overlay(dimmedContentAlpha: newValue)
    }
  }
}
