import UIKit

public extension FKButton {
  /// Mirrors `minimumTapInterval` for Interface Builder.
  @IBInspectable var fk_minimumTapInterval: CGFloat {
    get { CGFloat(minimumTapInterval) }
    set { minimumTapInterval = TimeInterval(newValue) }
  }

  @IBInspectable var fk_longPressMinimumDuration: CGFloat {
    get { CGFloat(longPressMinimumDuration) }
    set { longPressMinimumDuration = TimeInterval(newValue) }
  }

  /// Uniform expansion of hit target.
  @IBInspectable var fk_hitTestMargin: CGFloat {
    get { -hitTestEdgeInsets.top }
    set {
      let margin = newValue
      hitTestEdgeInsets = UIEdgeInsets(top: -margin, left: -margin, bottom: -margin, right: -margin)
    }
  }

  @IBInspectable var fk_automaticallyDimsWhenDisabled: Bool {
    get { automaticallyDimsWhenDisabled }
    set { automaticallyDimsWhenDisabled = newValue }
  }

  @IBInspectable var fk_disabledDimmingAlpha: CGFloat {
    get { disabledDimmingAlpha }
    set { disabledDimmingAlpha = newValue }
  }

  @IBInspectable var fk_overlayLoadingDimmedAlpha: CGFloat {
    get {
      if case .overlay(let alpha) = loadingPresentationStyle { return alpha }
      return 0.35
    }
    set { loadingPresentationStyle = .overlay(dimmedContentAlpha: newValue) }
  }
}
